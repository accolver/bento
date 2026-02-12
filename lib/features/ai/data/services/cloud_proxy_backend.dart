// @telos L1:function:lib/features/ai/data/services:cloud_proxy_backend

import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/ai_suggestion.dart';
import '../../domain/entities/remote_ai_provider.dart';
import '../../domain/services/ai_service.dart';
import '../../domain/services/prompt_templates.dart';
import '../utils/response_parser.dart';
import '../utils/shell_escape.dart';
import '../utils/ssh_utils.dart';
import 'remote_ai_exceptions.dart';
import 'remote_backend.dart';

/// Regex for validating environment variable names.
///
/// Only uppercase letters, digits, and underscores are allowed.
/// Must start with a letter. Max 128 characters.
final _validEnvVarName = RegExp(r'^[A-Z][A-Z0-9_]{0,127}$');

/// Remote backend that proxies cloud API calls through SSH.
///
/// API calls are executed as `curl` commands on the remote host, using
/// shell variable expansion (`$ANTHROPIC_API_KEY`) for authentication.
/// This means the actual API key value never leaves the remote machine
/// and is never seen by Bento.
///
/// ## Security Model (Key-Opaque Architecture)
///
/// Bento never reads, stores, or transmits API key values. Instead:
/// 1. Detection checks `test -n "$VAR"` — only tests existence, not value
/// 2. API calls use `$ENV_VAR` shell expansion in curl headers
/// 3. The remote shell resolves the variable at execution time
/// 4. Bento only sees the AI response, never the authentication credentials
///
/// ## SSH & Curl Requirements
///
/// - The remote host must have `curl` installed (exit code 127 = missing)
/// - SSH exec channel must be available (standard on OpenSSH servers)
/// - curl must support `-s` (silent) and `-N` (no-buffer, for streaming)
///
/// ## Supported API Formats
///
/// Two formats are supported, determined by [RemoteProviderConfig.apiFormat]:
/// - [ApiFormat.openaiCompatible]: `POST {base}/chat/completions` with
///   `Bearer` auth. Used by OpenAI, Groq, Mistral, xAI, DeepSeek,
///   Fireworks, Together, OpenRouter, Cohere, Google Gemini.
/// - [ApiFormat.anthropicMessages]: `POST {base}/v1/messages` with
///   `x-api-key` auth and `anthropic-version` header. Used by Anthropic.
class CloudProxyBackend extends RemoteBackend {
  /// Creates a cloud proxy backend for the given provider.
  ///
  /// [providerConfig] - API configuration for the target provider.
  /// [envVarName] - Environment variable on the remote host holding the API key.
  CloudProxyBackend({
    required this.providerConfig,
    required this.envVarName,
    this.maxTokens = 256,
    this.temperature = 0.3,
  });

  /// Provider configuration (API URL, format, auth, etc.).
  final RemoteProviderConfig providerConfig;

  /// Which environment variable holds the API key on the remote host.
  final String envVarName;

  /// Maximum tokens to generate.
  final int maxTokens;

  /// Temperature for generation.
  final double temperature;

  @override
  bool get isConfigured => envVarName.isNotEmpty;

  @override
  String get displayName => providerConfig.displayName;

  @override
  String get privacyDescription => 'API calls routed through remote host. '
      'Keys never leave the remote machine.';

  @override
  Future<AiSuggestion> generateCommand(
    SSHClient client,
    String prompt,
  ) async {
    final curl = _buildCurlCommand(
      systemPrompt: PromptTemplates.commandGeneration.system,
      userPrompt: PromptTemplates.commandGeneration.user(prompt),
      stream: false,
    );

    final session =
        await client.execute(curl).timeout(const Duration(seconds: 30));

    final stdout = await SshUtils.collectOutput(session.stdout);
    final exitCode = await session.exitCode;

    if (exitCode != 0) {
      final stderr = await SshUtils.collectOutput(session.stderr);
      _throwForExitCode(exitCode, stderr);
    }

    // Check for HTTP-level errors in the response body before parsing
    _checkForApiErrors(stdout);

    return _parseResponse(stdout);
  }

  @override
  Stream<AiStreamEvent> generateCommandStream(
    SSHClient client,
    String prompt,
  ) async* {
    final curl = _buildCurlCommand(
      systemPrompt: PromptTemplates.commandGeneration.system,
      userPrompt: PromptTemplates.commandGeneration.user(prompt),
      stream: true,
    );

    SSHSession? session;
    try {
      session = await client.execute(curl).timeout(const Duration(seconds: 30));
    } catch (e) {
      yield AiStreamError(
        'Failed to start ${providerConfig.displayName} streaming: $e',
        code: 'remote_exec_failed',
      );
      return;
    }

    final commandBuffer = StringBuffer();

    try {
      await for (final chunk in session.stdout) {
        final text = utf8.decode(chunk);
        for (final line in text.split('\n')) {
          if (line.isEmpty) continue;

          // Handle SSE format
          if (line.startsWith('data: ')) {
            final data = line.substring(6);

            if (data == '[DONE]') {
              final response = commandBuffer.toString().trim();
              final (command, explanation) =
                  ResponseParser.parseCommandAndExplanation(response);
              yield AiStreamComplete(
                AiSuggestion(
                  command: command,
                  explanation: explanation,
                  confidence: 0.85,
                ),
              );
              return;
            }

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final content = _extractStreamDelta(json);
              if (content != null && content.isNotEmpty) {
                commandBuffer.write(content);
                yield AiStreamToken(content);
              }
            } on FormatException {
              // Skip malformed chunks
            }
          }

          // Handle Anthropic event format
          if (line.startsWith('event: ')) {
            // Anthropic uses event: type + data: payload format
            // We handle the data lines above, event lines are metadata
            continue;
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
            confidence: 0.85,
          ),
        );
      } else {
        yield AiStreamError(
          'No response from ${providerConfig.displayName}',
        );
      }
    } catch (e) {
      yield AiStreamError(
        '${providerConfig.displayName} streaming error: $e',
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
        output.length > 1500 ? '${output.substring(0, 1500)}...' : output;

    final curl = _buildCurlCommand(
      systemPrompt: PromptTemplates.summarization.system,
      userPrompt: PromptTemplates.summarization.user(
        command: command,
        output: truncated,
      ),
      stream: false,
    );

    final session =
        await client.execute(curl).timeout(const Duration(seconds: 30));

    final stdout = await SshUtils.collectOutput(session.stdout);
    final exitCode = await session.exitCode;

    if (exitCode != 0) {
      return 'Unable to generate summary.';
    }

    try {
      _checkForApiErrors(stdout);
      return _extractContentFromResponse(stdout);
    } catch (e) {
      debugPrint('[CloudProxyBackend] Failed to parse summary: $e');
      return 'Unable to generate summary.';
    }
  }

  /// Build the curl command for this provider's API.
  ///
  /// Key insight: `\$${envVarName}` is expanded by the remote shell,
  /// so the actual API key value never appears in Bento's memory.
  String _buildCurlCommand({
    required String systemPrompt,
    required String userPrompt,
    required bool stream,
  }) {
    final body = _buildRequestBody(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      stream: stream,
    );
    final escapedBody = ShellEscape.escape(jsonEncode(body));

    switch (providerConfig.apiFormat) {
      case ApiFormat.openaiCompatible:
        return _buildOpenAiCurl(escapedBody, stream);
      case ApiFormat.anthropicMessages:
        return _buildAnthropicCurl(escapedBody, stream);
    }
  }

  /// Validate that the env var name is safe for shell interpolation.
  ///
  /// Prevents shell injection via crafted env var names that could
  /// break out of the double-quoted header context.
  void _validateEnvVarName() {
    if (!_validEnvVarName.hasMatch(envVarName)) {
      throw ArgumentError(
        'Invalid environment variable name: $envVarName. '
        'Must match [A-Z][A-Z0-9_]{0,127}.',
      );
    }
  }

  String _buildOpenAiCurl(String body, bool stream) {
    _validateEnvVarName();
    final endpoint = '${providerConfig.apiBaseUrl}/chat/completions';
    final authValue =
        providerConfig.authHeaderFormat.replaceAll(r'$KEY', '\$$envVarName');

    // Use single quotes for extra headers to prevent shell expansion.
    // Header keys/values are from the const registry so they're safe,
    // but we sanitize as defense-in-depth.
    final extraHeadersBuf = StringBuffer();
    for (final entry in providerConfig.extraHeaders.entries) {
      final key = entry.key.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '');
      final value = entry.value
          .replaceAll(RegExp(r'''[^a-zA-Z0-9\-._~:/?#@!&()*+,;=%]'''), '');
      extraHeadersBuf.write("-H '$key: $value' ");
    }

    return 'curl -s${stream ? 'N' : ''} $endpoint '
        '-H "${providerConfig.authHeaderName}: $authValue" '
        "-H 'Content-Type: application/json' "
        '${extraHeadersBuf.toString()}'
        "-d '$body'";
  }

  String _buildAnthropicCurl(String body, bool stream) {
    _validateEnvVarName();
    return 'curl -s${stream ? 'N' : ''} ${providerConfig.apiBaseUrl}/v1/messages '
        '-H "x-api-key: \$$envVarName" '
        "-H 'anthropic-version: 2023-06-01' "
        "-H 'Content-Type: application/json' "
        "-d '$body'";
  }

  /// Build request body appropriate for the provider's API format.
  Map<String, dynamic> _buildRequestBody({
    required String systemPrompt,
    required String userPrompt,
    required bool stream,
  }) {
    switch (providerConfig.apiFormat) {
      case ApiFormat.openaiCompatible:
        return {
          'model': providerConfig.defaultModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'max_tokens': maxTokens,
          'temperature': temperature,
          if (stream) 'stream': true,
        };
      case ApiFormat.anthropicMessages:
        return {
          'model': providerConfig.defaultModel,
          'system': systemPrompt,
          'messages': [
            {'role': 'user', 'content': userPrompt},
          ],
          'max_tokens': maxTokens,
          'temperature': temperature,
          if (stream) 'stream': true,
        };
    }
  }

  /// Parse a non-streaming response from any supported format.
  AiSuggestion _parseResponse(String responseBody) {
    final content = _extractContentFromResponse(responseBody);
    final (command, explanation) =
        ResponseParser.parseCommandAndExplanation(content);

    return AiSuggestion(
      command: command,
      explanation: explanation,
      confidence: 0.85,
    );
  }

  /// Throws the appropriate exception based on exit code.
  Never _throwForExitCode(int? exitCode, String stderr) {
    if (exitCode == 127) {
      throw const CurlNotFoundException();
    }
    throw RemoteExecutionException(
      '${providerConfig.displayName} request failed (exit $exitCode): $stderr',
      exitCode: exitCode,
      stderr: stderr,
    );
  }

  /// Check for HTTP-level API errors (rate limits, auth failures, etc.)
  /// in the response body before attempting content extraction.
  void _checkForApiErrors(String responseBody) {
    if (responseBody.isEmpty) return;

    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;

      // Check for error field (common across providers)
      if (json.containsKey('error')) {
        final error = json['error'];
        final message = error is Map
            ? (error['message'] as String? ?? error.toString())
            : error.toString();
        final type = error is Map ? (error['type'] as String?) : null;
        final status = error is Map ? (error['status'] as int?) : null;

        // Rate limit detection
        if (type == 'rate_limit_error' ||
            message.toLowerCase().contains('rate limit') ||
            message.toLowerCase().contains('too many requests')) {
          final retryAfter = _extractRetryAfter(message);
          throw RateLimitException(
            '${providerConfig.displayName}: Rate limit exceeded. '
            '${retryAfter != null ? 'Retry after ${retryAfter}s.' : 'Please wait.'}',
            retryAfterSeconds: retryAfter,
            providerName: providerConfig.displayName,
          );
        }

        // Auth failure detection
        if (type == 'authentication_error' ||
            status == 401 ||
            message.toLowerCase().contains('invalid api key') ||
            message.toLowerCase().contains('unauthorized')) {
          throw RemoteApiException(
            '${providerConfig.displayName}: Authentication failed. '
            'Check that the API key is valid on the remote host.',
            providerName: providerConfig.displayName,
            statusCode: 401,
          );
        }

        // Generic API error
        throw RemoteApiException(
          '${providerConfig.displayName}: $message',
          providerName: providerConfig.displayName,
          statusCode: status,
        );
      }

      // Anthropic error format (type: "error", error: {...})
      if (json['type'] == 'error' && json.containsKey('error')) {
        final error = json['error'] as Map<String, dynamic>?;
        final message = error?['message'] as String? ?? 'Unknown error';
        final type = error?['type'] as String?;

        if (type == 'rate_limit_error') {
          throw RateLimitException(
            '${providerConfig.displayName}: $message',
            providerName: providerConfig.displayName,
          );
        }

        throw RemoteApiException(
          '${providerConfig.displayName}: $message',
          providerName: providerConfig.displayName,
        );
      }
    } on AiServiceException {
      rethrow;
    } catch (_) {
      // Not JSON or doesn't have error structure — let content extraction handle it
    }
  }

  /// Try to extract retry-after seconds from an error message.
  int? _extractRetryAfter(String message) {
    final match = RegExp(r'(\d+)\s*seconds?').firstMatch(message);
    if (match != null) return int.tryParse(match.group(1)!);
    return null;
  }

  /// Extract the text content from a response body (handles both formats).
  String _extractContentFromResponse(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;

      // OpenAI-compatible format
      final choices = json['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'] as Map<String, dynamic>?;
        final content = message?['content'] as String?;
        if (content != null && content.isNotEmpty) {
          return content.trim();
        }
      }

      // Anthropic Messages format
      final contentBlocks = json['content'] as List?;
      if (contentBlocks != null && contentBlocks.isNotEmpty) {
        final textBlock = contentBlocks.firstWhere(
          (b) => b['type'] == 'text',
          orElse: () => contentBlocks.first,
        );
        final text = textBlock['text'] as String?;
        if (text != null && text.isNotEmpty) {
          return text.trim();
        }
      }

      throw RemoteParseException(
        'Empty response from ${providerConfig.displayName}',
      );
    } on AiServiceException {
      rethrow;
    } on FormatException {
      throw RemoteParseException(
        'Invalid response from ${providerConfig.displayName}',
        rawResponse: responseBody.length > 200
            ? '${responseBody.substring(0, 200)}...'
            : responseBody,
      );
    }
  }

  /// Extract content delta from a streaming chunk.
  String? _extractStreamDelta(Map<String, dynamic> json) {
    // OpenAI-compatible format
    final choices = json['choices'] as List?;
    if (choices != null && choices.isNotEmpty) {
      final delta = choices[0]['delta'] as Map<String, dynamic>?;
      return delta?['content'] as String?;
    }

    // Anthropic format (content_block_delta)
    final type = json['type'] as String?;
    if (type == 'content_block_delta') {
      final delta = json['delta'] as Map<String, dynamic>?;
      return delta?['text'] as String?;
    }

    return null;
  }
}
