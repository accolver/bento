// @telos L1:function:lib/features/ai/data/services:claude_code_proxy_backend

import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/ai_suggestion.dart';
import '../../domain/services/ai_service.dart';
import '../../domain/services/prompt_templates.dart';
import '../utils/response_parser.dart';
import '../utils/shell_escape.dart';
import '../utils/ssh_utils.dart';
import 'remote_ai_exceptions.dart';
import 'remote_backend.dart';

/// Remote backend that proxies Anthropic API calls through SSH using
/// Claude Code's OAuth credentials.
///
/// ## Security Model (Key-Opaque Architecture)
///
/// Like [CloudProxyBackend], Bento never reads, stores, or transmits
/// credential values. Instead:
/// 1. Token extraction uses `$(claude --print-access-token)` which runs
///    on the remote host — the token value is resolved at execution time
/// 2. Bento only sees the AI response, never the authentication token
/// 3. On 401 errors, a retry is attempted (the CLI handles refresh)
///
/// ## How Token Extraction Works
///
/// Claude Code stores credentials differently per platform:
/// - **macOS**: encrypted macOS Keychain (not accessible via file)
/// - **Linux**: `~/.claude/.credentials` file
///
/// Using `claude --print-access-token` abstracts this away — it works
/// on both platforms, handles token refresh internally, and returns
/// a valid Bearer token regardless of storage backend.
///
/// ## Differences from CloudProxyBackend
///
/// | Aspect              | CloudProxyBackend          | ClaudeCodeProxyBackend       |
/// |---------------------|----------------------------|------------------------------|
/// | Auth source         | Environment variable       | `claude --print-access-token`|
/// | Auth header         | `x-api-key: $ENV_VAR`      | `Authorization: Bearer $(…)` |
/// | Token refresh       | N/A (static env var)       | Handled by Claude Code CLI   |
/// | 401 handling        | Throw immediately          | Retry once                   |
class ClaudeCodeProxyBackend extends RemoteBackend {
  /// Creates a Claude Code proxy backend.
  ///
  /// [model] - Anthropic model to use (defaults to claude-sonnet-4-5).
  /// [maxTokens] - Maximum tokens to generate.
  /// [temperature] - Temperature for generation.
  ClaudeCodeProxyBackend({
    this.model = 'claude-sonnet-4-5-20250514',
    this.maxTokens = 256,
    this.temperature = 0.3,
  });

  /// Anthropic model to use.
  final String model;

  /// Maximum tokens to generate.
  final int maxTokens;

  /// Temperature for generation.
  final double temperature;

  /// Shell subshell command that extracts the Bearer token using
  /// Claude Code's CLI.
  ///
  /// `claude --print-access-token` works on both macOS (Keychain) and
  /// Linux (~/.claude/.credentials), handles token refresh internally,
  /// and returns a valid Bearer token.
  ///
  /// The subshell is embedded in the curl command's Authorization header
  /// so the token value is resolved by the remote shell, never by Bento.
  static const tokenExtraction = r'$(claude --print-access-token 2>/dev/null)';

  @override
  bool get isConfigured => true;

  @override
  String get displayName => 'Claude Code';

  @override
  String get privacyDescription =>
      'API calls routed through remote host via Claude Code credentials. '
      'Tokens are key-opaque — never seen by Bento.';

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

    // Check for auth errors and attempt token refresh
    if (_isAuthError(stdout)) {
      final refreshed = await _attemptTokenRefresh(client);
      if (refreshed) {
        // Retry with refreshed token
        final retrySession =
            await client.execute(curl).timeout(const Duration(seconds: 30));
        final retryStdout = await SshUtils.collectOutput(retrySession.stdout);
        final retryExitCode = await retrySession.exitCode;

        if (retryExitCode != 0) {
          final retryStderr = await SshUtils.collectOutput(retrySession.stderr);
          _throwForExitCode(retryExitCode, retryStderr);
        }

        _checkForApiErrors(retryStdout);
        return _parseResponse(retryStdout);
      }
    }

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
        'Failed to start Claude Code streaming: $e',
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
              final decoded = jsonDecode(data);
              final Map<String, dynamic> json;
              if (decoded is Map<String, dynamic>) {
                json = decoded;
              } else if (decoded is List && decoded.isNotEmpty) {
                json = decoded.first as Map<String, dynamic>;
              } else {
                continue;
              }
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
        yield const AiStreamError(
          'No response from Claude Code',
        );
      }
    } catch (e) {
      yield AiStreamError(
        'Claude Code streaming error: $e',
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
      debugPrint('[ClaudeCodeProxyBackend] Failed to parse summary: $e');
      return 'Unable to generate summary.';
    }
  }

  /// Build the curl command using Anthropic Messages API with Bearer auth.
  ///
  /// Key insight: The token extraction subshell `$(...)` is expanded by
  /// the remote shell, so the actual token value never appears in Bento's
  /// memory.
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

    return 'curl -s${stream ? 'N' : ''} https://api.anthropic.com/v1/messages '
        '-H "Authorization: Bearer $tokenExtraction" '
        "-H 'anthropic-version: 2023-06-01' "
        "-H 'Content-Type: application/json' "
        "-d '$escapedBody'";
  }

  /// Build request body in Anthropic Messages API format.
  Map<String, dynamic> _buildRequestBody({
    required String systemPrompt,
    required String userPrompt,
    required bool stream,
  }) {
    return {
      'model': model,
      'system': systemPrompt,
      'messages': [
        {'role': 'user', 'content': userPrompt},
      ],
      'max_tokens': maxTokens,
      'temperature': temperature,
      if (stream) 'stream': true,
    };
  }

  /// Detect whether a response body indicates an authentication error (401).
  ///
  /// Checks for common patterns in Anthropic error responses that indicate
  /// the token is expired or invalid.
  bool _isAuthError(String responseBody) {
    if (responseBody.isEmpty) return false;

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) return false;
      final json = decoded;

      // Check for error field
      if (json.containsKey('error')) {
        final error = json['error'];
        if (error is Map) {
          final type = error['type'] as String?;
          final status = error['status'] as int?;
          final message = (error['message'] as String?)?.toLowerCase() ?? '';

          if (type == 'authentication_error') return true;
          if (status == 401) return true;
          if (message.contains('unauthorized')) return true;
          if (message.contains('invalid api key')) return true;
          if (message.contains('invalid x-api-key')) return true;
          if (message.contains('invalid bearer token')) return true;
        }
      }

      // Anthropic error format (type: "error", error: {...})
      if (json['type'] == 'error' && json.containsKey('error')) {
        final error = json['error'] as Map<String, dynamic>?;
        final type = error?['type'] as String?;
        if (type == 'authentication_error') return true;
      }
    } catch (_) {
      // Not JSON — not an auth error
    }

    return false;
  }

  /// Attempt to refresh the OAuth token by running
  /// `claude --print-access-token` on the remote host.
  ///
  /// Returns `true` if the refresh command succeeded (exit code 0),
  /// indicating the token file may have been updated.
  /// Returns `false` if the command failed or is not available.
  Future<bool> _attemptTokenRefresh(SSHClient client) async {
    try {
      final session = await client
          .execute('claude --print-access-token 2>/dev/null')
          .timeout(const Duration(seconds: 15));

      final exitCode = await session.exitCode;
      // Drain stdout/stderr to avoid hanging
      await SshUtils.collectOutput(session.stdout);
      await SshUtils.collectOutput(session.stderr);

      return exitCode == 0;
    } catch (e) {
      debugPrint('[ClaudeCodeProxyBackend] Token refresh failed: $e');
      return false;
    }
  }

  /// Check for HTTP-level API errors in the response body.
  ///
  /// Handles rate limits, auth failures, and generic API errors.
  void _checkForApiErrors(String responseBody) {
    if (responseBody.isEmpty) return;

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) return;
      final json = decoded;

      // Check for error field
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
            'Claude Code: Rate limit exceeded. '
            '${retryAfter != null ? 'Retry after ${retryAfter}s.' : 'Please wait.'}',
            retryAfterSeconds: retryAfter,
            providerName: 'Claude Code',
          );
        }

        // Auth failure detection
        if (type == 'authentication_error' ||
            status == 401 ||
            message.toLowerCase().contains('invalid api key') ||
            message.toLowerCase().contains('unauthorized')) {
          throw const RemoteApiException(
            'Claude Code: Authentication failed. '
            'Token may be expired — try running `claude login` on the remote host.',
            providerName: 'Claude Code',
            statusCode: 401,
          );
        }

        // Generic API error
        throw RemoteApiException(
          'Claude Code: $message',
          providerName: 'Claude Code',
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
            'Claude Code: $message',
            providerName: 'Claude Code',
          );
        }

        throw RemoteApiException(
          'Claude Code: $message',
          providerName: 'Claude Code',
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

  /// Parse a non-streaming response into an [AiSuggestion].
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
      'Claude Code request failed (exit $exitCode): $stderr',
      exitCode: exitCode,
      stderr: stderr,
    );
  }

  /// Extract the text content from an Anthropic Messages API response.
  String _extractContentFromResponse(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);

      final Map<String, dynamic> json;
      if (decoded is List && decoded.isNotEmpty) {
        if (decoded.first is Map<String, dynamic>) {
          json = decoded.first as Map<String, dynamic>;
        } else {
          throw RemoteParseException(
            'Unexpected array response from Claude Code',
            rawResponse: responseBody.length > 200
                ? '${responseBody.substring(0, 200)}...'
                : responseBody,
          );
        }
      } else if (decoded is Map<String, dynamic>) {
        json = decoded;
      } else {
        throw RemoteParseException(
          'Unexpected response type from Claude Code',
          rawResponse: responseBody.length > 200
              ? '${responseBody.substring(0, 200)}...'
              : responseBody,
        );
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

      throw const RemoteParseException(
        'Empty response from Claude Code',
      );
    } on AiServiceException {
      rethrow;
    } on FormatException {
      throw RemoteParseException(
        'Invalid response from Claude Code',
        rawResponse: responseBody.length > 200
            ? '${responseBody.substring(0, 200)}...'
            : responseBody,
      );
    }
  }

  /// Extract content delta from a streaming chunk.
  String? _extractStreamDelta(Map<String, dynamic> json) {
    // Anthropic format (content_block_delta)
    final type = json['type'] as String?;
    if (type == 'content_block_delta') {
      final delta = json['delta'] as Map<String, dynamic>?;
      return delta?['text'] as String?;
    }

    return null;
  }
}
