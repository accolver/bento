// @telos-test L1:function:lib/features/ai/data/services:cloud_proxy_backend

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bento/features/ai/data/services/cloud_proxy_backend.dart';
import 'package:bento/features/ai/data/services/remote_ai_exceptions.dart';
import 'package:bento/features/ai/domain/entities/ai_suggestion.dart';
import 'package:bento/features/ai/domain/entities/remote_ai_provider.dart';
import 'package:bento/features/ai/domain/services/ai_service.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// --- Mocks ---

class MockSSHClient extends Mock implements SSHClient {}

class MockSSHSession extends Mock implements SSHSession {}

// --- Test provider configs ---

const _openaiConfig = RemoteProviderConfig(
  provider: RemoteCloudProvider.openai,
  envVars: ['OPENAI_API_KEY'],
  displayName: 'GPT-4o (OpenAI)',
  apiBaseUrl: 'https://api.openai.com/v1',
  defaultModel: 'gpt-4o',
  apiFormat: ApiFormat.openaiCompatible,
  authHeaderName: 'Authorization',
  authHeaderFormat: r'Bearer $KEY',
  qualityRank: 2,
);

const _anthropicConfig = RemoteProviderConfig(
  provider: RemoteCloudProvider.anthropic,
  envVars: ['ANTHROPIC_API_KEY'],
  displayName: 'Claude (Anthropic)',
  apiBaseUrl: 'https://api.anthropic.com',
  defaultModel: 'claude-sonnet-4-20250514',
  apiFormat: ApiFormat.anthropicMessages,
  authHeaderName: 'x-api-key',
  authHeaderFormat: r'$KEY',
  qualityRank: 1,
  extraHeaders: {'anthropic-version': '2023-06-01'},
);

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
  // Emit all SSE lines as a single chunk (simulating buffered output)
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

  group('CloudProxyBackend', () {
    // =========================================================================
    // Properties
    // =========================================================================
    group('properties', () {
      // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:is-configured-true
      test('isConfigured returns true when envVarName is non-empty', () {
        final backend = CloudProxyBackend(
          providerConfig: _openaiConfig,
          envVarName: 'OPENAI_API_KEY',
        );
        expect(backend.isConfigured, isTrue);
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:is-configured-false
      test('isConfigured returns false when envVarName is empty', () {
        final backend = CloudProxyBackend(
          providerConfig: _openaiConfig,
          envVarName: '',
        );
        expect(backend.isConfigured, isFalse);
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:display-name
      test('displayName returns providerConfig.displayName', () {
        final backend = CloudProxyBackend(
          providerConfig: _anthropicConfig,
          envVarName: 'ANTHROPIC_API_KEY',
        );
        expect(backend.displayName, 'Claude (Anthropic)');
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:privacy-description
      test('privacyDescription returns expected string', () {
        final backend = CloudProxyBackend(
          providerConfig: _openaiConfig,
          envVarName: 'OPENAI_API_KEY',
        );
        expect(
          backend.privacyDescription,
          'API calls routed through remote host. '
          'Keys never leave the remote machine.',
        );
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:default-params
      test('maxTokens defaults to 256 and temperature to 0.3', () {
        final backend = CloudProxyBackend(
          providerConfig: _openaiConfig,
          envVarName: 'OPENAI_API_KEY',
        );
        expect(backend.maxTokens, 256);
        expect(backend.temperature, 0.3);
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:custom-params
      test('maxTokens and temperature can be overridden', () {
        final backend = CloudProxyBackend(
          providerConfig: _openaiConfig,
          envVarName: 'OPENAI_API_KEY',
          maxTokens: 1024,
          temperature: 0.7,
        );
        expect(backend.maxTokens, 1024);
        expect(backend.temperature, 0.7);
      });
    });

    // =========================================================================
    // OpenAI-compatible format
    // =========================================================================
    group('OpenAI-compatible format', () {
      late CloudProxyBackend backend;

      setUp(() {
        backend = CloudProxyBackend(
          providerConfig: _openaiConfig,
          envVarName: 'OPENAI_API_KEY',
        );
      });

      group('curl command building', () {
        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:openai-curl-url
        test('uses /chat/completions endpoint', () async {
          final response = jsonEncode({
            'choices': [
              {
                'message': {'content': 'ls -la\nList all files'},
              },
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
            contains('https://api.openai.com/v1/chat/completions'),
          );
        });

        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:openai-curl-auth
        test('uses shell variable expansion for auth header', () async {
          final response = jsonEncode({
            'choices': [
              {
                'message': {'content': 'ls -la'},
              },
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
          // Should use shell variable expansion, NOT the actual key value
          expect(
            capturedCommand,
            contains(r'Authorization: Bearer $OPENAI_API_KEY'),
          );
        });

        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:openai-curl-body
        test('builds correct request body with model and messages', () async {
          final response = jsonEncode({
            'choices': [
              {
                'message': {'content': 'ls -la'},
              },
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
          // Body should contain model
          expect(capturedCommand, contains('"model":"gpt-4o"'));
          // Body should contain system and user messages
          expect(capturedCommand, contains('"role":"system"'));
          expect(capturedCommand, contains('"role":"user"'));
          // Body should contain max_tokens and temperature
          expect(capturedCommand, contains('"max_tokens":256'));
          expect(capturedCommand, contains('"temperature":0.3'));
          // Content-Type header
          expect(capturedCommand, contains('Content-Type: application/json'));
        });

        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:openai-curl-silent
        test('uses -s flag for non-streaming requests', () async {
          final response = jsonEncode({
            'choices': [
              {
                'message': {'content': 'ls'},
              },
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
          // Should have -s but NOT -sN for non-streaming
          expect(capturedCommand, contains('curl -s '));
        });
      });

      group('response parsing', () {
        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:openai-parse-response
        test('parses OpenAI-format response correctly', () async {
          final response = jsonEncode({
            'choices': [
              {
                'message': {
                  'content': 'ls -la\nList all files with details',
                },
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

        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:openai-parse-no-newline
        test('parses response without newline separator (single line)',
            () async {
          final response = jsonEncode({
            'choices': [
              {
                'message': {'content': 'ls -la'},
              },
            ],
          });
          final session = _createSession(stdoutData: response);
          when(() => client.execute(any()))
              .thenAnswer((_) => Future.value(session));

          final result = await backend.generateCommand(client, 'list files');

          expect(result.command, 'ls -la');
          expect(result.explanation, 'Generated command');
          expect(result.confidence, 0.85);
        });
      });
    });

    // =========================================================================
    // Anthropic Messages format
    // =========================================================================
    group('Anthropic Messages format', () {
      late CloudProxyBackend backend;

      setUp(() {
        backend = CloudProxyBackend(
          providerConfig: _anthropicConfig,
          envVarName: 'ANTHROPIC_API_KEY',
        );
      });

      group('curl command building', () {
        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:anthropic-curl-url
        test('uses /v1/messages endpoint', () async {
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

        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:anthropic-curl-auth
        test('uses x-api-key header with shell variable expansion', () async {
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
            contains(r'x-api-key: $ANTHROPIC_API_KEY'),
          );
        });

        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:anthropic-curl-version-header
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
          expect(
            capturedCommand,
            contains('anthropic-version: 2023-06-01'),
          );
        });

        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:anthropic-curl-body
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
          // Anthropic format uses "system" as a top-level field, not in messages
          expect(capturedCommand, contains('"system":'));
          expect(
              capturedCommand, contains('"model":"claude-sonnet-4-20250514"'));
          // Only user message in messages array (no system message)
          expect(capturedCommand, contains('"role":"user"'));
          expect(capturedCommand, contains('"max_tokens":256'));
          expect(capturedCommand, contains('"temperature":0.3'));
        });
      });

      group('response parsing', () {
        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:anthropic-parse-response
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
    });

    // =========================================================================
    // Error handling
    // =========================================================================
    group('error handling', () {
      late CloudProxyBackend openaiBackend;
      late CloudProxyBackend anthropicBackend;

      setUp(() {
        openaiBackend = CloudProxyBackend(
          providerConfig: _openaiConfig,
          envVarName: 'OPENAI_API_KEY',
        );
        anthropicBackend = CloudProxyBackend(
          providerConfig: _anthropicConfig,
          envVarName: 'ANTHROPIC_API_KEY',
        );
      });

      group('exit code errors', () {
        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:exit-code-127-curl-not-found
        test('exit code 127 throws CurlNotFoundException', () async {
          final session = _createSession(
            stderrData: 'bash: curl: command not found',
            exitCode: 127,
          );
          when(() => client.execute(any()))
              .thenAnswer((_) => Future.value(session));

          expect(
            () => openaiBackend.generateCommand(client, 'list files'),
            throwsA(isA<CurlNotFoundException>()),
          );
        });

        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:non-zero-exit-code
        test('non-zero exit code throws RemoteExecutionException', () async {
          final session = _createSession(
            stderrData: 'Connection refused',
            exitCode: 7,
          );
          when(() => client.execute(any()))
              .thenAnswer((_) => Future.value(session));

          expect(
            () => openaiBackend.generateCommand(client, 'list files'),
            throwsA(
              isA<RemoteExecutionException>().having(
                (e) => e.exitCode,
                'exitCode',
                7,
              ),
            ),
          );
        });
      });

      group('API errors', () {
        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:generic-api-error
        test('generic API error throws RemoteApiException', () async {
          final response = jsonEncode({
            'error': {'message': 'Model not found'},
          });
          final session = _createSession(stdoutData: response);
          when(() => client.execute(any()))
              .thenAnswer((_) => Future.value(session));

          expect(
            () => openaiBackend.generateCommand(client, 'list files'),
            throwsA(
              isA<RemoteApiException>().having(
                (e) => e.message,
                'message',
                contains('Model not found'),
              ),
            ),
          );
        });

        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:anthropic-error-format
        test('Anthropic error format (type: "error") throws correctly',
            () async {
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
            () => anthropicBackend.generateCommand(client, 'list files'),
            throwsA(isA<RateLimitException>()),
          );
        });

        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:anthropic-error-generic
        test(
            'Anthropic error format with non-rate-limit type throws RemoteApiException',
            () async {
          final response = jsonEncode({
            'type': 'error',
            'error': {
              'type': 'invalid_request_error',
              'message': 'Invalid model',
            },
          });
          final session = _createSession(stdoutData: response);
          when(() => client.execute(any()))
              .thenAnswer((_) => Future.value(session));

          expect(
            () => anthropicBackend.generateCommand(client, 'list files'),
            throwsA(isA<RemoteApiException>()),
          );
        });

        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:non-json-response-no-throw
        test('non-JSON response does not throw from error check', () async {
          // Non-JSON will fail at content extraction, not at error check
          final session = _createSession(stdoutData: '<html>Not Found</html>');
          when(() => client.execute(any()))
              .thenAnswer((_) => Future.value(session));

          // Should throw RemoteParseException (from content extraction),
          // NOT from _checkForApiErrors
          expect(
            () => openaiBackend.generateCommand(client, 'list files'),
            throwsA(isA<RemoteParseException>()),
          );
        });

        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:empty-response
        test('empty response throws RemoteParseException', () async {
          // Empty JSON object with no choices/content
          final response = jsonEncode({'id': 'test', 'object': 'chat'});
          final session = _createSession(stdoutData: response);
          when(() => client.execute(any()))
              .thenAnswer((_) => Future.value(session));

          expect(
            () => openaiBackend.generateCommand(client, 'list files'),
            throwsA(isA<RemoteParseException>()),
          );
        });
      });

      group('rate limiting', () {
        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:rate-limit-by-type
        test('rate_limit_error type throws RateLimitException', () async {
          final response = jsonEncode({
            'error': {
              'type': 'rate_limit_error',
              'message': 'Rate limit exceeded. Try again in 30 seconds.',
            },
          });
          final session = _createSession(stdoutData: response);
          when(() => client.execute(any()))
              .thenAnswer((_) => Future.value(session));

          expect(
            () => openaiBackend.generateCommand(client, 'list files'),
            throwsA(
              isA<RateLimitException>().having(
                (e) => e.retryAfterSeconds,
                'retryAfterSeconds',
                30,
              ),
            ),
          );
        });

        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:rate-limit-by-message
        test('"Too many requests" message throws RateLimitException', () async {
          final response = jsonEncode({
            'error': {'message': 'Too many requests'},
          });
          final session = _createSession(stdoutData: response);
          when(() => client.execute(any()))
              .thenAnswer((_) => Future.value(session));

          expect(
            () => openaiBackend.generateCommand(client, 'list files'),
            throwsA(isA<RateLimitException>()),
          );
        });

        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:rate-limit-retry-after-60
        test('extracts retry-after seconds from message', () async {
          final response = jsonEncode({
            'error': {
              'type': 'rate_limit_error',
              'message': 'Rate limit exceeded, retry after 60 seconds.',
            },
          });
          final session = _createSession(stdoutData: response);
          when(() => client.execute(any()))
              .thenAnswer((_) => Future.value(session));

          expect(
            () => openaiBackend.generateCommand(client, 'list files'),
            throwsA(
              isA<RateLimitException>().having(
                (e) => e.retryAfterSeconds,
                'retryAfterSeconds',
                60,
              ),
            ),
          );
        });

        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:rate-limit-no-retry-seconds
        test('rate limit without seconds has null retryAfterSeconds', () async {
          final response = jsonEncode({
            'error': {
              'type': 'rate_limit_error',
              'message': 'Rate limit exceeded. Please wait.',
            },
          });
          final session = _createSession(stdoutData: response);
          when(() => client.execute(any()))
              .thenAnswer((_) => Future.value(session));

          expect(
            () => openaiBackend.generateCommand(client, 'list files'),
            throwsA(
              isA<RateLimitException>().having(
                (e) => e.retryAfterSeconds,
                'retryAfterSeconds',
                isNull,
              ),
            ),
          );
        });
      });

      group('auth failures', () {
        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:auth-failure-by-type
        test('authentication_error type throws RemoteApiException with 401',
            () async {
          final response = jsonEncode({
            'error': {
              'type': 'authentication_error',
              'message': 'Invalid API key',
            },
          });
          final session = _createSession(stdoutData: response);
          when(() => client.execute(any()))
              .thenAnswer((_) => Future.value(session));

          expect(
            () => openaiBackend.generateCommand(client, 'list files'),
            throwsA(
              isA<RemoteApiException>().having(
                (e) => e.statusCode,
                'statusCode',
                401,
              ),
            ),
          );
        });

        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:auth-failure-by-status
        test('status 401 throws RemoteApiException with 401', () async {
          final response = jsonEncode({
            'error': {
              'status': 401,
              'message': 'Unauthorized',
            },
          });
          final session = _createSession(stdoutData: response);
          when(() => client.execute(any()))
              .thenAnswer((_) => Future.value(session));

          expect(
            () => openaiBackend.generateCommand(client, 'list files'),
            throwsA(
              isA<RemoteApiException>().having(
                (e) => e.statusCode,
                'statusCode',
                401,
              ),
            ),
          );
        });

        // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:auth-failure-by-message
        test('"invalid api key" message throws RemoteApiException with 401',
            () async {
          final response = jsonEncode({
            'error': {'message': 'invalid api key provided'},
          });
          final session = _createSession(stdoutData: response);
          when(() => client.execute(any()))
              .thenAnswer((_) => Future.value(session));

          expect(
            () => openaiBackend.generateCommand(client, 'list files'),
            throwsA(
              isA<RemoteApiException>().having(
                (e) => e.statusCode,
                'statusCode',
                401,
              ),
            ),
          );
        });
      });
    });

    // =========================================================================
    // generateCommandStream
    // =========================================================================
    group('generateCommandStream', () {
      late CloudProxyBackend openaiBackend;
      late CloudProxyBackend anthropicBackend;

      setUp(() {
        openaiBackend = CloudProxyBackend(
          providerConfig: _openaiConfig,
          envVarName: 'OPENAI_API_KEY',
        );
        anthropicBackend = CloudProxyBackend(
          providerConfig: _anthropicConfig,
          envVarName: 'ANTHROPIC_API_KEY',
        );
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:stream-uses-sN-flag
      test('uses -sN flag for streaming requests', () async {
        final session = _createStreamingSession(sseLines: [
          'data: [DONE]',
        ]);

        String? capturedCommand;
        when(() => client.execute(any())).thenAnswer((invocation) {
          capturedCommand = invocation.positionalArguments[0] as String;
          return Future.value(session);
        });

        // Consume the stream
        await openaiBackend
            .generateCommandStream(client, 'list files')
            .toList();

        expect(capturedCommand, isNotNull);
        expect(capturedCommand, contains('curl -sN'));
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:stream-openai-sse
      test('parses OpenAI SSE format tokens', () async {
        final session = _createStreamingSession(sseLines: [
          'data: ${jsonEncode({
                'choices': [
                  {
                    'delta': {'content': 'ls'},
                  },
                ],
              })}',
          '',
          'data: ${jsonEncode({
                'choices': [
                  {
                    'delta': {'content': ' -la'},
                  },
                ],
              })}',
          '',
          'data: [DONE]',
        ]);

        when(() => client.execute(any()))
            .thenAnswer((_) => Future.value(session));

        final events = await openaiBackend
            .generateCommandStream(client, 'list files')
            .toList();

        // Should have token events and a complete event
        final tokens =
            events.whereType<AiStreamToken>().map((e) => e.token).toList();
        expect(tokens, contains('ls'));
        expect(tokens, contains(' -la'));

        final complete = events.whereType<AiStreamComplete>().first;
        expect(complete.suggestion.confidence, 0.85);
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:stream-anthropic-sse
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

        final events = await anthropicBackend
            .generateCommandStream(client, 'list files')
            .toList();

        final tokens =
            events.whereType<AiStreamToken>().map((e) => e.token).toList();
        expect(tokens, contains('ls'));
        expect(tokens, contains(' -la'));

        final complete = events.whereType<AiStreamComplete>().first;
        expect(complete.suggestion.confidence, 0.85);
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:stream-done-yields-complete
      test('data: [DONE] yields AiStreamComplete with confidence 0.85',
          () async {
        final session = _createStreamingSession(sseLines: [
          'data: ${jsonEncode({
                'choices': [
                  {
                    'delta': {'content': 'ls -la'},
                  },
                ],
              })}',
          '',
          'data: [DONE]',
        ]);

        when(() => client.execute(any()))
            .thenAnswer((_) => Future.value(session));

        final events = await openaiBackend
            .generateCommandStream(client, 'list files')
            .toList();

        final complete = events.whereType<AiStreamComplete>().toList();
        expect(complete, hasLength(1));
        expect(complete.first.suggestion.command, 'ls -la');
        expect(complete.first.suggestion.confidence, 0.85);
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:stream-execute-failure
      test('execute failure yields AiStreamError with remote_exec_failed code',
          () async {
        when(() => client.execute(any()))
            .thenThrow(Exception('Connection lost'));

        final events = await openaiBackend
            .generateCommandStream(client, 'list files')
            .toList();

        expect(events, hasLength(1));
        expect(events.first, isA<AiStreamError>());
        final error = events.first as AiStreamError;
        expect(error.code, 'remote_exec_failed');
        expect(error.message, contains('GPT-4o (OpenAI)'));
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:stream-no-done-with-content
      test('stream ending without [DONE] but with content yields complete',
          () async {
        final session = _createStreamingSession(sseLines: [
          'data: ${jsonEncode({
                'choices': [
                  {
                    'delta': {'content': 'pwd'},
                  },
                ],
              })}',
        ]);

        when(() => client.execute(any()))
            .thenAnswer((_) => Future.value(session));

        final events = await openaiBackend
            .generateCommandStream(client, 'where am i')
            .toList();

        final complete = events.whereType<AiStreamComplete>().toList();
        expect(complete, hasLength(1));
        expect(complete.first.suggestion.command, 'pwd');
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:stream-empty-yields-error
      test('stream ending without content yields AiStreamError', () async {
        final session = _createStreamingSession(sseLines: []);

        when(() => client.execute(any()))
            .thenAnswer((_) => Future.value(session));

        final events = await openaiBackend
            .generateCommandStream(client, 'list files')
            .toList();

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
      late CloudProxyBackend backend;

      setUp(() {
        backend = CloudProxyBackend(
          providerConfig: _openaiConfig,
          envVarName: 'OPENAI_API_KEY',
        );
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:summarize-success
      test('returns content on success', () async {
        final response = jsonEncode({
          'choices': [
            {
              'message': {'content': '3 files found in directory'},
            },
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

      // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:summarize-truncates-output
      test('truncates output longer than 1500 chars', () async {
        final longOutput = 'x' * 2000;
        final response = jsonEncode({
          'choices': [
            {
              'message': {'content': 'Long output summary'},
            },
          ],
        });
        final session = _createSession(stdoutData: response);

        String? capturedCommand;
        when(() => client.execute(any())).thenAnswer((invocation) {
          capturedCommand = invocation.positionalArguments[0] as String;
          return Future.value(session);
        });

        await backend.summarizeOutput(client, 'cat bigfile', longOutput);

        expect(capturedCommand, isNotNull);
        // The truncated output (1500 chars + "...") should be in the command,
        // NOT the full 2000 chars
        // Verify the full 2000-char string is NOT present
        expect(capturedCommand, isNot(contains(longOutput)));
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:summarize-short-output-not-truncated
      test('does not truncate output shorter than 1500 chars', () async {
        final shortOutput = 'x' * 100;
        final response = jsonEncode({
          'choices': [
            {
              'message': {'content': 'Short output summary'},
            },
          ],
        });
        final session = _createSession(stdoutData: response);

        String? capturedCommand;
        when(() => client.execute(any())).thenAnswer((invocation) {
          capturedCommand = invocation.positionalArguments[0] as String;
          return Future.value(session);
        });

        await backend.summarizeOutput(client, 'echo test', shortOutput);

        expect(capturedCommand, isNotNull);
        // Short output should be included as-is
        expect(capturedCommand, contains(shortOutput));
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:summarize-exit-code-failure
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

      // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:summarize-api-error-fallback
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

      // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:summarize-parse-error-fallback
      test('returns fallback message on parse error', () async {
        final session = _createSession(stdoutData: 'not json at all');
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
    // Command parsing edge cases
    // =========================================================================
    group('command parsing', () {
      late CloudProxyBackend backend;

      setUp(() {
        backend = CloudProxyBackend(
          providerConfig: _openaiConfig,
          envVarName: 'OPENAI_API_KEY',
        );
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:parse-code-block
      test('strips markdown code blocks from response', () async {
        final response = jsonEncode({
          'choices': [
            {
              'message': {'content': '```bash\nls -la\nList files\n```'},
            },
          ],
        });
        final session = _createSession(stdoutData: response);
        when(() => client.execute(any()))
            .thenAnswer((_) => Future.value(session));

        final result = await backend.generateCommand(client, 'list files');

        expect(result.command, 'ls -la');
        expect(result.explanation, 'List files');
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:parse-dollar-prefix
      test('strips dollar-sign prefix from command', () async {
        final response = jsonEncode({
          'choices': [
            {
              'message': {'content': r'$ ls -la'},
            },
          ],
        });
        final session = _createSession(stdoutData: response);
        when(() => client.execute(any()))
            .thenAnswer((_) => Future.value(session));

        final result = await backend.generateCommand(client, 'list files');

        expect(result.command, 'ls -la');
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:cloud_proxy_backend:parse-pipe-in-command
      test('preserves pipe characters in commands', () async {
        // With newline-based parsing, pipes in the command are preserved
        final response = jsonEncode({
          'choices': [
            {
              'message': {
                'content': 'ls -la | grep test\nFilter files matching test',
              },
            },
          ],
        });
        final session = _createSession(stdoutData: response);
        when(() => client.execute(any()))
            .thenAnswer((_) => Future.value(session));

        final result = await backend.generateCommand(client, 'find test files');

        // Pipe is preserved in the command (first line)
        expect(result.command, 'ls -la | grep test');
        // Explanation is on the second line
        expect(result.explanation, 'Filter files matching test');
      });
    });
  });
}
