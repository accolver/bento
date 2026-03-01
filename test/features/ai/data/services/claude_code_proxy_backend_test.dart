// @telos-test L1:function:lib/features/ai/data/services:claude_code_proxy_backend

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bento/features/ai/data/services/claude_code_proxy_backend.dart';
import 'package:bento/features/ai/data/services/remote_ai_exceptions.dart';
import 'package:bento/features/ai/data/services/remote_backend.dart';
import 'package:bento/features/ai/domain/entities/ai_suggestion.dart';
import 'package:bento/features/ai/domain/services/ai_service.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// --- Mocks ---

class MockSSHClient extends Mock implements SSHClient {}

class MockSSHSession extends Mock implements SSHSession {}

// --- Helpers ---

MockSSHSession _createSession({
  String stdoutData = '',
  String stderrData = '',
  int? exitCode = 0,
}) {
  final session = MockSSHSession();
  when(() => session.stdout).thenAnswer((_) {
    if (stdoutData.isEmpty) return const Stream<Uint8List>.empty();
    return Stream.value(Uint8List.fromList(utf8.encode(stdoutData)));
  });
  when(() => session.stderr).thenAnswer((_) {
    if (stderrData.isEmpty) return const Stream<Uint8List>.empty();
    return Stream.value(Uint8List.fromList(utf8.encode(stderrData)));
  });
  when(() => session.exitCode).thenReturn(exitCode);
  return session;
}

/// Creates a streaming session that emits SSE lines as stdout chunks.
MockSSHSession _createStreamingSession({
  required List<String> sseLines,
  int? exitCode = 0,
}) {
  final session = MockSSHSession();
  final combined = sseLines.join('\n');
  when(() => session.stdout).thenAnswer((_) {
    return Stream.value(Uint8List.fromList(utf8.encode(combined)));
  });
  when(() => session.stderr).thenAnswer(
    (_) => const Stream<Uint8List>.empty(),
  );
  when(() => session.exitCode).thenReturn(exitCode);
  return session;
}

void main() {
  late MockSSHClient client;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    client = MockSSHClient();
  });

  group('ClaudeCodeProxyBackend', () {
    // =========================================================================
    // Type hierarchy
    // =========================================================================
    // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:extends-remote-backend
    test('extends RemoteBackend', () {
      final backend = ClaudeCodeProxyBackend();
      expect(backend, isA<RemoteBackend>());
    });

    // =========================================================================
    // Properties
    // =========================================================================
    group('properties', () {
      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:display-name
      test('displayName returns "Claude Code"', () {
        final backend = ClaudeCodeProxyBackend();
        expect(backend.displayName, 'Claude Code');
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:is-configured-true
      test('isConfigured always returns true', () {
        final backend = ClaudeCodeProxyBackend();
        expect(backend.isConfigured, isTrue);
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:privacy-description
      test('privacyDescription mentions key-opaque', () {
        final backend = ClaudeCodeProxyBackend();
        expect(backend.privacyDescription, contains('key-opaque'));
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:default-params
      test('maxTokens defaults to 256 and temperature to 0.3', () {
        final backend = ClaudeCodeProxyBackend();
        expect(backend.maxTokens, 256);
        expect(backend.temperature, 0.3);
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:custom-params
      test('maxTokens and temperature can be overridden', () {
        final backend = ClaudeCodeProxyBackend(
          maxTokens: 1024,
          temperature: 0.7,
        );
        expect(backend.maxTokens, 1024);
        expect(backend.temperature, 0.7);
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:custom-model
      test('model can be overridden', () {
        final backend = ClaudeCodeProxyBackend(
          model: 'claude-3-haiku-20240307',
        );
        expect(backend.model, 'claude-3-haiku-20240307');
      });
    });

    // =========================================================================
    // Curl command building
    // =========================================================================
    group('curl command building', () {
      late ClaudeCodeProxyBackend backend;

      setUp(() {
        backend = ClaudeCodeProxyBackend();
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:curl-uses-bearer-auth
      test('uses Authorization: Bearer (not x-api-key)', () async {
        final response = jsonEncode({
          'content': [
            {'type': 'text', 'text': 'ls -la'},
          ],
        });
        final session = _createSession(stdoutData: response);

        String? capturedCommand;
        when(() => client.execute(any())).thenAnswer((invocation) {
          capturedCommand = invocation.positionalArguments[0] as String;
          return Future.value(session);
        });

        await backend.generateCommand(client, 'list files');

        expect(capturedCommand, isNotNull);
        expect(capturedCommand, contains('Authorization: Bearer'));
        expect(capturedCommand, isNot(contains('x-api-key')));
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:curl-contains-token-extraction
      test('contains the token extraction subshell', () async {
        final response = jsonEncode({
          'content': [
            {'type': 'text', 'text': 'ls -la'},
          ],
        });
        final session = _createSession(stdoutData: response);

        String? capturedCommand;
        when(() => client.execute(any())).thenAnswer((invocation) {
          capturedCommand = invocation.positionalArguments[0] as String;
          return Future.value(session);
        });

        await backend.generateCommand(client, 'list files');

        expect(capturedCommand, isNotNull);
        // Should contain the python3 subshell for token extraction
        expect(capturedCommand, contains(r'$(python3'));
        expect(capturedCommand, contains('.claude/.credentials'));
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:curl-uses-anthropic-endpoint
      test('uses Anthropic /v1/messages endpoint', () async {
        final response = jsonEncode({
          'content': [
            {'type': 'text', 'text': 'ls -la'},
          ],
        });
        final session = _createSession(stdoutData: response);

        String? capturedCommand;
        when(() => client.execute(any())).thenAnswer((invocation) {
          capturedCommand = invocation.positionalArguments[0] as String;
          return Future.value(session);
        });

        await backend.generateCommand(client, 'list files');

        expect(capturedCommand, isNotNull);
        expect(
          capturedCommand,
          contains('https://api.anthropic.com/v1/messages'),
        );
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:curl-includes-anthropic-version
      test('includes anthropic-version header', () async {
        final response = jsonEncode({
          'content': [
            {'type': 'text', 'text': 'ls -la'},
          ],
        });
        final session = _createSession(stdoutData: response);

        String? capturedCommand;
        when(() => client.execute(any())).thenAnswer((invocation) {
          capturedCommand = invocation.positionalArguments[0] as String;
          return Future.value(session);
        });

        await backend.generateCommand(client, 'list files');

        expect(capturedCommand, isNotNull);
        expect(capturedCommand, contains('anthropic-version: 2023-06-01'));
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:curl-body-anthropic-format
      test('builds body with system as top-level field', () async {
        final response = jsonEncode({
          'content': [
            {'type': 'text', 'text': 'ls -la'},
          ],
        });
        final session = _createSession(stdoutData: response);

        String? capturedCommand;
        when(() => client.execute(any())).thenAnswer((invocation) {
          capturedCommand = invocation.positionalArguments[0] as String;
          return Future.value(session);
        });

        await backend.generateCommand(client, 'list files');

        expect(capturedCommand, isNotNull);
        expect(capturedCommand, contains('"system":'));
        expect(capturedCommand, contains('"role":"user"'));
        expect(capturedCommand, contains('"max_tokens":256'));
        expect(capturedCommand, contains('"temperature":0.3'));
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:curl-silent-non-streaming
      test('uses -s flag for non-streaming requests', () async {
        final response = jsonEncode({
          'content': [
            {'type': 'text', 'text': 'ls'},
          ],
        });
        final session = _createSession(stdoutData: response);

        String? capturedCommand;
        when(() => client.execute(any())).thenAnswer((invocation) {
          capturedCommand = invocation.positionalArguments[0] as String;
          return Future.value(session);
        });

        await backend.generateCommand(client, 'list');

        expect(capturedCommand, isNotNull);
        expect(capturedCommand, contains('curl -s '));
      });
    });

    // =========================================================================
    // Response parsing
    // =========================================================================
    group('response parsing', () {
      late ClaudeCodeProxyBackend backend;

      setUp(() {
        backend = ClaudeCodeProxyBackend();
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:parse-anthropic-response
      test('parses Anthropic-format response correctly', () async {
        final response = jsonEncode({
          'content': [
            {
              'type': 'text',
              'text': 'ls -la\nList all files with details',
            },
          ],
        });
        final session = _createSession(stdoutData: response);
        when(() => client.execute(any()))
            .thenAnswer((_) => Future.value(session));

        final result = await backend.generateCommand(client, 'list files');

        expect(result, isA<AiSuggestion>());
        expect(result.command, 'ls -la');
        expect(result.explanation, 'List all files with details');
        expect(result.confidence, 0.85);
      });
    });

    // =========================================================================
    // Auth error detection
    // =========================================================================
    group('auth error detection', () {
      late ClaudeCodeProxyBackend backend;

      setUp(() {
        backend = ClaudeCodeProxyBackend();
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:auth-error-by-type
      test('detects authentication_error type', () async {
        final errorResponse = jsonEncode({
          'error': {
            'type': 'authentication_error',
            'message': 'Invalid bearer token',
          },
        });

        // First call returns auth error, token refresh fails
        final errorSession = _createSession(stdoutData: errorResponse);
        final refreshSession = _createSession(
          stdoutData: '',
          exitCode: 1,
        );

        var callCount = 0;
        when(() => client.execute(any())).thenAnswer((invocation) {
          callCount++;
          final cmd = invocation.positionalArguments[0] as String;
          if (cmd.contains('--print-access-token')) {
            return Future.value(refreshSession);
          }
          return Future.value(errorSession);
        });

        // Should throw because refresh failed and error persists
        expect(
          () => backend.generateCommand(client, 'list files'),
          throwsA(
            isA<RemoteApiException>().having(
              (e) => e.statusCode,
              'statusCode',
              401,
            ),
          ),
        );
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:auth-error-by-status
      test('detects status 401', () async {
        final errorResponse = jsonEncode({
          'error': {
            'status': 401,
            'message': 'Unauthorized',
          },
        });

        final errorSession = _createSession(stdoutData: errorResponse);
        final refreshSession = _createSession(
          stdoutData: '',
          exitCode: 1,
        );

        when(() => client.execute(any())).thenAnswer((invocation) {
          final cmd = invocation.positionalArguments[0] as String;
          if (cmd.contains('--print-access-token')) {
            return Future.value(refreshSession);
          }
          return Future.value(errorSession);
        });

        expect(
          () => backend.generateCommand(client, 'list files'),
          throwsA(
            isA<RemoteApiException>().having(
              (e) => e.statusCode,
              'statusCode',
              401,
            ),
          ),
        );
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:auth-error-retry-on-refresh
      test('retries after successful token refresh', () async {
        final errorResponse = jsonEncode({
          'error': {
            'type': 'authentication_error',
            'message': 'Invalid bearer token',
          },
        });
        final successResponse = jsonEncode({
          'content': [
            {'type': 'text', 'text': 'ls -la\nList files'},
          ],
        });

        final errorSession = _createSession(stdoutData: errorResponse);
        final refreshSession = _createSession(
          stdoutData: 'new-token',
          exitCode: 0,
        );
        final successSession = _createSession(stdoutData: successResponse);

        var curlCallCount = 0;
        when(() => client.execute(any())).thenAnswer((invocation) {
          final cmd = invocation.positionalArguments[0] as String;
          if (cmd.contains('--print-access-token')) {
            return Future.value(refreshSession);
          }
          curlCallCount++;
          if (curlCallCount == 1) {
            return Future.value(errorSession);
          }
          return Future.value(successSession);
        });

        final result = await backend.generateCommand(client, 'list files');

        expect(result.command, 'ls -la');
        expect(curlCallCount, 2); // First attempt + retry
      });
    });

    // =========================================================================
    // Error handling
    // =========================================================================
    group('error handling', () {
      late ClaudeCodeProxyBackend backend;

      setUp(() {
        backend = ClaudeCodeProxyBackend();
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:exit-code-127
      test('exit code 127 throws CurlNotFoundException', () async {
        final session = _createSession(
          stderrData: 'bash: curl: command not found',
          exitCode: 127,
        );
        when(() => client.execute(any()))
            .thenAnswer((_) => Future.value(session));

        expect(
          () => backend.generateCommand(client, 'list files'),
          throwsA(isA<CurlNotFoundException>()),
        );
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:non-zero-exit-code
      test('non-zero exit code throws RemoteExecutionException', () async {
        final session = _createSession(
          stderrData: 'Connection refused',
          exitCode: 7,
        );
        when(() => client.execute(any()))
            .thenAnswer((_) => Future.value(session));

        expect(
          () => backend.generateCommand(client, 'list files'),
          throwsA(
            isA<RemoteExecutionException>().having(
              (e) => e.exitCode,
              'exitCode',
              7,
            ),
          ),
        );
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:rate-limit
      test('rate limit error throws RateLimitException', () async {
        final response = jsonEncode({
          'type': 'error',
          'error': {
            'type': 'rate_limit_error',
            'message': 'Rate limit exceeded',
          },
        });
        final session = _createSession(stdoutData: response);
        when(() => client.execute(any()))
            .thenAnswer((_) => Future.value(session));

        expect(
          () => backend.generateCommand(client, 'list files'),
          throwsA(isA<RateLimitException>()),
        );
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:empty-response
      test('empty response throws RemoteParseException', () async {
        final response = jsonEncode({'id': 'test', 'object': 'chat'});
        final session = _createSession(stdoutData: response);
        when(() => client.execute(any()))
            .thenAnswer((_) => Future.value(session));

        expect(
          () => backend.generateCommand(client, 'list files'),
          throwsA(isA<RemoteParseException>()),
        );
      });
    });

    // =========================================================================
    // generateCommandStream
    // =========================================================================
    group('generateCommandStream', () {
      late ClaudeCodeProxyBackend backend;

      setUp(() {
        backend = ClaudeCodeProxyBackend();
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:stream-uses-sN-flag
      test('uses -sN flag for streaming requests', () async {
        final session = _createStreamingSession(sseLines: [
          'data: [DONE]',
        ]);

        String? capturedCommand;
        when(() => client.execute(any())).thenAnswer((invocation) {
          capturedCommand = invocation.positionalArguments[0] as String;
          return Future.value(session);
        });

        await backend.generateCommandStream(client, 'list files').toList();

        expect(capturedCommand, isNotNull);
        expect(capturedCommand, contains('curl -sN'));
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:stream-anthropic-sse
      test('parses Anthropic SSE format tokens', () async {
        final session = _createStreamingSession(sseLines: [
          'event: content_block_delta',
          'data: ${jsonEncode({
                'type': 'content_block_delta',
                'delta': {'text': 'ls'},
              })}',
          '',
          'event: content_block_delta',
          'data: ${jsonEncode({
                'type': 'content_block_delta',
                'delta': {'text': ' -la'},
              })}',
          '',
          'data: [DONE]',
        ]);

        when(() => client.execute(any()))
            .thenAnswer((_) => Future.value(session));

        final events =
            await backend.generateCommandStream(client, 'list files').toList();

        final tokens =
            events.whereType<AiStreamToken>().map((e) => e.token).toList();
        expect(tokens, contains('ls'));
        expect(tokens, contains(' -la'));

        final complete = events.whereType<AiStreamComplete>().first;
        expect(complete.suggestion.confidence, 0.85);
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:stream-done-yields-complete
      test('data: [DONE] yields AiStreamComplete', () async {
        final session = _createStreamingSession(sseLines: [
          'event: content_block_delta',
          'data: ${jsonEncode({
                'type': 'content_block_delta',
                'delta': {'text': 'ls -la'},
              })}',
          '',
          'data: [DONE]',
        ]);

        when(() => client.execute(any()))
            .thenAnswer((_) => Future.value(session));

        final events =
            await backend.generateCommandStream(client, 'list files').toList();

        final complete = events.whereType<AiStreamComplete>().toList();
        expect(complete, hasLength(1));
        expect(complete.first.suggestion.command, 'ls -la');
        expect(complete.first.suggestion.confidence, 0.85);
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:stream-execute-failure
      test('execute failure yields AiStreamError', () async {
        when(() => client.execute(any()))
            .thenThrow(Exception('Connection lost'));

        final events =
            await backend.generateCommandStream(client, 'list files').toList();

        expect(events, hasLength(1));
        expect(events.first, isA<AiStreamError>());
        final error = events.first as AiStreamError;
        expect(error.code, 'remote_exec_failed');
        expect(error.message, contains('Claude Code'));
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:stream-empty-yields-error
      test('stream ending without content yields AiStreamError', () async {
        final session = _createStreamingSession(sseLines: []);

        when(() => client.execute(any()))
            .thenAnswer((_) => Future.value(session));

        final events =
            await backend.generateCommandStream(client, 'list files').toList();

        expect(events, hasLength(1));
        expect(events.first, isA<AiStreamError>());
        final error = events.first as AiStreamError;
        expect(error.message, contains('No response'));
      });
    });

    // =========================================================================
    // summarizeOutput
    // =========================================================================
    group('summarizeOutput', () {
      late ClaudeCodeProxyBackend backend;

      setUp(() {
        backend = ClaudeCodeProxyBackend();
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:summarize-success
      test('returns content on success', () async {
        final response = jsonEncode({
          'content': [
            {'type': 'text', 'text': '3 files found in directory'},
          ],
        });
        final session = _createSession(stdoutData: response);
        when(() => client.execute(any()))
            .thenAnswer((_) => Future.value(session));

        final result = await backend.summarizeOutput(
          client,
          'ls',
          'file1\nfile2\nfile3',
        );

        expect(result, '3 files found in directory');
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:summarize-exit-code-failure
      test('returns fallback message on non-zero exit code', () async {
        final session = _createSession(
          stderrData: 'Connection timeout',
          exitCode: 28,
        );
        when(() => client.execute(any()))
            .thenAnswer((_) => Future.value(session));

        final result = await backend.summarizeOutput(
          client,
          'ls',
          'some output',
        );

        expect(result, 'Unable to generate summary.');
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:summarize-api-error-fallback
      test('returns fallback message on API error', () async {
        final response = jsonEncode({
          'error': {'message': 'Model not found'},
        });
        final session = _createSession(stdoutData: response);
        when(() => client.execute(any()))
            .thenAnswer((_) => Future.value(session));

        final result = await backend.summarizeOutput(
          client,
          'ls',
          'some output',
        );

        expect(result, 'Unable to generate summary.');
      });
    });

    // =========================================================================
    // Token extraction constant
    // =========================================================================
    group('token extraction', () {
      // @telos-scenario L1:function:lib/features/ai/data/services:claude_code_proxy_backend:token-extraction-constant
      test('tokenExtraction contains python3 and grep fallback', () {
        expect(
          ClaudeCodeProxyBackend.tokenExtraction,
          contains('python3'),
        );
        expect(
          ClaudeCodeProxyBackend.tokenExtraction,
          contains('claudeApiKey'),
        );
        expect(
          ClaudeCodeProxyBackend.tokenExtraction,
          contains('oauthToken'),
        );
        expect(
          ClaudeCodeProxyBackend.tokenExtraction,
          contains('grep'),
        );
      });
    });
  });
}
