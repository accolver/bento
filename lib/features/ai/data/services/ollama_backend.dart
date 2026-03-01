// @telos L1:function:lib/features/ai/data/services:ollama_backend

import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/ai_suggestion.dart';
import '../../domain/entities/ollama_model.dart';
import '../../domain/services/ai_service.dart';
import '../../domain/services/prompt_templates.dart';
import '../utils/response_parser.dart';
import '../utils/shell_escape.dart';
import '../utils/ssh_utils.dart';
import 'remote_ai_exceptions.dart';
import 'remote_backend.dart';

/// Remote backend using Ollama's OpenAI-compatible API on the remote host.
///
/// All requests are executed as `curl` commands via SSH. Data stays on
/// the remote server — no external API calls are made.
class OllamaBackend extends RemoteBackend {
  /// Creates an Ollama backend targeting a specific model on the remote host.
  ///
  /// [selectedModel] - The Ollama model name to use (e.g., "llama3:8b").
  /// [availableModels] - All models detected on the server.
  /// [port] - Ollama API port (defaults to 11434).
  OllamaBackend({
    required this.selectedModel,
    required this.availableModels,
    this.port = 11434,
    this.maxTokens = 256,
    this.temperature = 0.3,
  });

  /// Currently selected Ollama model name.
  final String selectedModel;

  /// All available models on the server.
  final List<OllamaModel> availableModels;

  /// Ollama server port on the remote host.
  final int port;

  /// Maximum tokens to generate.
  final int maxTokens;

  /// Temperature for generation.
  final double temperature;

  @override
  bool get isConfigured => selectedModel.isNotEmpty;

  @override
  String get displayName => 'Ollama ($selectedModel)';

  @override
  String get privacyDescription =>
      'Running locally on remote server. No data leaves your infrastructure.';

  @override
  Future<AiSuggestion> generateCommand(
    SSHClient client,
    String prompt,
  ) async {
    final requestBody = _buildChatRequestBody(
      systemPrompt: PromptTemplates.commandGeneration.system,
      userPrompt: PromptTemplates.commandGeneration.user(prompt),
      stream: false,
    );

    final escaped = ShellEscape.escape(jsonEncode(requestBody));

    final session = await client
        .execute(
          'curl -s --max-time 25 localhost:$port/v1/chat/completions '
          '-H "Content-Type: application/json" '
          "-d '$escaped'",
        )
        .timeout(const Duration(seconds: 30));

    final stdout = await SshUtils.collectOutput(session.stdout)
        .timeout(const Duration(seconds: 30));
    final exitCode = await session.exitCode;

    if (exitCode != 0) {
      final stderr = await SshUtils.collectOutput(session.stderr);
      _throwForExitCode(exitCode, stderr);
    }

    return _parseOpenAiResponse(stdout);
  }

  @override
  Stream<AiStreamEvent> generateCommandStream(
    SSHClient client,
    String prompt,
  ) async* {
    final requestBody = _buildChatRequestBody(
      systemPrompt: PromptTemplates.commandGeneration.system,
      userPrompt: PromptTemplates.commandGeneration.user(prompt),
      stream: true,
    );

    final escaped = ShellEscape.escape(jsonEncode(requestBody));

    SSHSession? session;
    try {
      session = await client
          .execute(
            'curl -sN localhost:$port/v1/chat/completions '
            '-H "Content-Type: application/json" '
            "-d '$escaped'",
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      yield AiStreamError(
        'Failed to start Ollama streaming: $e',
        code: 'remote_exec_failed',
      );
      return;
    }

    final commandBuffer = StringBuffer();

    try {
      await for (final chunk in session.stdout) {
        final text = utf8.decode(chunk);
        for (final line in text.split('\n')) {
          if (line.isEmpty || !line.startsWith('data: ')) continue;
          final data = line.substring(6);

          if (data == '[DONE]') {
            final response = commandBuffer.toString().trim();
            final (command, explanation) =
                ResponseParser.parseCommandAndExplanation(response);
            yield AiStreamComplete(
              AiSuggestion(
                command: command,
                explanation: explanation,
                confidence: 0.8,
              ),
            );
            return;
          }

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>?;
              final content = delta?['content'] as String?;
              if (content != null && content.isNotEmpty) {
                commandBuffer.write(content);
                yield AiStreamToken(content);
              }
            }
          } on FormatException {
            // Skip malformed chunks
          }
        }
      }

      // Stream ended without [DONE]
      final finalText = commandBuffer.toString().trim();
      if (finalText.isNotEmpty) {
        final (command, explanation) =
            ResponseParser.parseCommandAndExplanation(finalText);
        yield AiStreamComplete(
          AiSuggestion(
            command: command,
            explanation: explanation,
            confidence: 0.8,
          ),
        );
      } else {
        yield const AiStreamError('No response from Ollama');
      }
    } catch (e) {
      yield AiStreamError(
        'Ollama streaming error: $e',
        code: 'stream_error',
        originalError: e,
      );
    }
  }

  @override
  Future<String> summarizeOutput(
    SSHClient client,
    String command,
    String output,
  ) async {
    final truncated =
        output.length > 2000 ? '${output.substring(0, 2000)}...' : output;

    final requestBody = _buildChatRequestBody(
      systemPrompt: PromptTemplates.summarization.system,
      userPrompt: PromptTemplates.summarization.user(
        command: command,
        output: truncated,
      ),
      stream: false,
    );

    final escaped = ShellEscape.escape(jsonEncode(requestBody));

    final session = await client
        .execute(
          'curl -s --max-time 25 localhost:$port/v1/chat/completions '
          '-H "Content-Type: application/json" '
          "-d '$escaped'",
        )
        .timeout(const Duration(seconds: 30));

    final stdout = await SshUtils.collectOutput(session.stdout)
        .timeout(const Duration(seconds: 30));
    final exitCode = await session.exitCode;

    if (exitCode != 0) {
      return 'Unable to generate summary.';
    }

    try {
      final json = jsonDecode(stdout) as Map<String, dynamic>;
      final choices = json['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'] as Map<String, dynamic>?;
        final content = message?['content'] as String?;
        if (content != null && content.isNotEmpty) {
          return content.trim();
        }
      }
    } catch (e) {
      debugPrint('[OllamaBackend] Failed to parse summary response: $e');
    }

    return 'Unable to generate summary.';
  }

  Map<String, dynamic> _buildChatRequestBody({
    required String systemPrompt,
    required String userPrompt,
    required bool stream,
  }) {
    return {
      'model': selectedModel,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'max_tokens': maxTokens,
      'temperature': temperature,
      'stream': stream,
    };
  }

  AiSuggestion _parseOpenAiResponse(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;

      // Check for Ollama error responses
      if (json.containsKey('error')) {
        final error = json['error'];
        final message = error is Map ? error['message'] : error.toString();
        throw RemoteApiException(
          'Ollama: $message',
          providerName: 'Ollama',
        );
      }

      final choices = json['choices'] as List?;

      if (choices == null || choices.isEmpty) {
        throw const RemoteParseException(
          'No response from Ollama',
        );
      }

      final message = choices[0]['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;

      if (content == null || content.isEmpty) {
        throw const RemoteParseException(
          'Empty response from Ollama',
        );
      }

      final (command, explanation) =
          ResponseParser.parseCommandAndExplanation(content);

      return AiSuggestion(
        command: command,
        explanation: explanation,
        confidence: 0.8,
      );
    } on AiServiceException {
      rethrow;
    } on FormatException {
      throw RemoteParseException(
        'Invalid JSON response from Ollama',
        rawResponse: responseBody.length > 200
            ? '${responseBody.substring(0, 200)}...'
            : responseBody,
      );
    }
  }

  /// Throws the appropriate exception based on exit code.
  Never _throwForExitCode(int? exitCode, String stderr) {
    if (exitCode == 127) {
      throw const CurlNotFoundException();
    }
    throw RemoteExecutionException(
      'Ollama request failed (exit $exitCode): $stderr',
      exitCode: exitCode,
      stderr: stderr,
    );
  }
}
