// @telos-test L1:function:lib/features/ai/data/services:cloud_ai_service

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bento/features/ai/data/repositories/ai_config_repository.dart';
import 'package:bento/features/ai/data/services/cloud_ai_service.dart';
import 'package:bento/features/ai/domain/entities/ai_config.dart';
import 'package:bento/features/ai/domain/entities/ai_privacy_mode.dart';
import 'package:bento/features/ai/domain/services/ai_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAiConfigRepository extends Mock implements AiConfigRepository {}

class MockDio extends Mock implements Dio {}

class MockResponse<T> extends Mock implements Response<T> {}

void main() {
  late MockAiConfigRepository mockConfigRepository;
  late MockDio mockDio;
  late CloudAiService service;

  setUp(() {
    mockConfigRepository = MockAiConfigRepository();
    mockDio = MockDio();

    // Default: API key is available
    when(() => mockConfigRepository.getApiKey())
        .thenAnswer((_) async => 'sk-test-api-key');
    when(() => mockConfigRepository.hasApiKey()).thenAnswer((_) async => true);

    service = CloudAiService(
      configRepository: mockConfigRepository,
      provider: CloudAiProvider.gpt4oMini,
      dio: mockDio,
    );
  });

  group('CloudAiService', () {
    group('properties', () {
      // @telos-scenario L1:...:cloud_ai_service:service-name
      test('serviceName includes provider name', () {
        expect(service.serviceName, contains('GPT-4o Mini'));
      });

      // @telos-scenario L1:...:cloud_ai_service:privacy-mode
      test('privacyMode is cloud', () {
        expect(service.privacyMode, equals(AiPrivacyMode.cloud));
      });

      // @telos-scenario L1:...:cloud_ai_service:provider-names
      test('different providers have correct names', () {
        final claudeService = CloudAiService(
          configRepository: mockConfigRepository,
          provider: CloudAiProvider.claude,
          dio: mockDio,
        );
        expect(claudeService.serviceName, contains('Claude'));

        final llamaService = CloudAiService(
          configRepository: mockConfigRepository,
          provider: CloudAiProvider.llama3,
          dio: mockDio,
        );
        expect(llamaService.serviceName, contains('Llama 3'));

        final geminiService = CloudAiService(
          configRepository: mockConfigRepository,
          provider: CloudAiProvider.gemini,
          dio: mockDio,
        );
        expect(geminiService.serviceName, contains('Gemini'));
      });
    });

    group('isAvailable', () {
      // @telos-scenario L1:...:cloud_ai_service:available-with-key
      test('returns true when API key exists', () async {
        when(() => mockConfigRepository.getApiKey())
            .thenAnswer((_) async => 'sk-test-key');

        final result = await service.isAvailable();

        expect(result, isTrue);
      });

      // @telos-scenario L1:...:cloud_ai_service:unavailable-without-key
      test('returns false when API key is null', () async {
        when(() => mockConfigRepository.getApiKey())
            .thenAnswer((_) async => null);

        final result = await service.isAvailable();

        expect(result, isFalse);
      });

      // @telos-scenario L1:...:cloud_ai_service:unavailable-empty-key
      test('returns false when API key is empty', () async {
        when(() => mockConfigRepository.getApiKey())
            .thenAnswer((_) async => '');

        final result = await service.isAvailable();

        expect(result, isFalse);
      });
    });

    group('generateCommand', () {
      // @telos-scenario L1:...:cloud_ai_service:successful-generation
      test('returns AiSuggestion on successful API call', () async {
        final mockResponse = Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/chat/completions'),
          statusCode: 200,
          data: {
            'choices': [
              {
                'message': {
                  'content': 'ls -la',
                },
              }
            ],
          },
        );

        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => mockResponse);

        final result = await service.generateCommand('list all files');

        expect(result.command, equals('ls -la'));
        expect(result.confidence, equals(0.85));
        // Explanation comes from parsed response or default
        expect(result.explanation, isNotEmpty);
      });

      // @telos-scenario L1:...:cloud_ai_service:strips-markdown
      test('strips markdown code blocks from response', () async {
        final mockResponse = Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/chat/completions'),
          statusCode: 200,
          data: {
            'choices': [
              {
                'message': {
                  'content': '```bash\nls -la\n```',
                },
              }
            ],
          },
        );

        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => mockResponse);

        final result = await service.generateCommand('list all files');

        expect(result.command, equals('ls -la'));
      });

      // @telos-scenario L1:...:cloud_ai_service:strips-prompt-character
      test('strips leading prompt characters', () async {
        final mockResponse = Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/chat/completions'),
          statusCode: 200,
          data: {
            'choices': [
              {
                'message': {
                  'content': r'$ ls -la',
                },
              }
            ],
          },
        );

        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => mockResponse);

        final result = await service.generateCommand('list all files');

        expect(result.command, equals('ls -la'));
      });

      // @telos-scenario L1:...:cloud_ai_service:no-api-key-error
      test('throws when no API key configured', () async {
        when(() => mockConfigRepository.getApiKey())
            .thenAnswer((_) async => null);

        expect(
          () => service.generateCommand('list files'),
          throwsA(isA<AiServiceException>().having(
            (e) => e.code,
            'code',
            equals('no_api_key'),
          )),
        );
      });

      // @telos-scenario L1:...:cloud_ai_service:empty-response-error
      test('throws on empty response', () async {
        final mockResponse = Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/chat/completions'),
          statusCode: 200,
          data: {
            'choices': [],
          },
        );

        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => mockResponse);

        expect(
          () => service.generateCommand('list files'),
          throwsA(isA<AiServiceException>().having(
            (e) => e.code,
            'code',
            equals('empty_response'),
          )),
        );
      });

      // @telos-scenario L1:...:cloud_ai_service:uses-correct-model
      test('sends correct model ID to API', () async {
        final claudeService = CloudAiService(
          configRepository: mockConfigRepository,
          provider: CloudAiProvider.claude,
          dio: mockDio,
        );

        final mockResponse = Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/chat/completions'),
          statusCode: 200,
          data: {
            'choices': [
              {
                'message': {'content': 'ls'}
              }
            ],
          },
        );

        Map<String, dynamic>? capturedData;
        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenAnswer((invocation) async {
          capturedData = invocation.namedArguments[const Symbol('data')]
              as Map<String, dynamic>;
          return mockResponse;
        });

        await claudeService.generateCommand('test');

        expect(capturedData?['model'], equals('anthropic/claude-3.5-sonnet'));
      });
    });

    group('error handling', () {
      // @telos-scenario L1:...:cloud_ai_service:401-invalid-key
      test('handles 401 as invalid key', () async {
        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/chat/completions'),
          response: Response(
            requestOptions: RequestOptions(path: '/chat/completions'),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => service.generateCommand('test'),
          throwsA(isA<AiServiceException>()
              .having((e) => e.code, 'code', equals('invalid_key'))
              .having((e) => e.isRetryable, 'isRetryable', isFalse)),
        );
      });

      // @telos-scenario L1:...:cloud_ai_service:429-rate-limit
      test('handles 429 as rate limit with retry', () async {
        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/chat/completions'),
          response: Response(
            requestOptions: RequestOptions(path: '/chat/completions'),
            statusCode: 429,
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => service.generateCommand('test'),
          throwsA(isA<AiServiceException>()
              .having((e) => e.code, 'code', equals('rate_limit'))
              .having((e) => e.isRetryable, 'isRetryable', isTrue)),
        );
      });

      // @telos-scenario L1:...:cloud_ai_service:503-service-unavailable
      test('handles 503 as service unavailable', () async {
        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/chat/completions'),
          response: Response(
            requestOptions: RequestOptions(path: '/chat/completions'),
            statusCode: 503,
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => service.generateCommand('test'),
          throwsA(isA<AiServiceException>()
              .having((e) => e.code, 'code', equals('service_unavailable'))
              .having((e) => e.isRetryable, 'isRetryable', isTrue)),
        );
      });

      // @telos-scenario L1:...:cloud_ai_service:timeout-error
      test('handles timeout as retryable', () async {
        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/chat/completions'),
          type: DioExceptionType.connectionTimeout,
        ));

        expect(
          () => service.generateCommand('test'),
          throwsA(isA<AiServiceException>()
              .having((e) => e.code, 'code', equals('timeout'))
              .having((e) => e.isRetryable, 'isRetryable', isTrue)),
        );
      });

      // @telos-scenario L1:...:cloud_ai_service:network-error
      test('handles connection error as retryable', () async {
        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/chat/completions'),
          type: DioExceptionType.connectionError,
        ));

        expect(
          () => service.generateCommand('test'),
          throwsA(isA<AiServiceException>()
              .having((e) => e.code, 'code', equals('network'))
              .having((e) => e.isRetryable, 'isRetryable', isTrue)),
        );
      });

      // @telos-scenario L1:...:cloud_ai_service:parses-api-error
      test('parses error message from API response', () async {
        when(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/chat/completions'),
          response: Response(
            requestOptions: RequestOptions(path: '/chat/completions'),
            statusCode: 400,
            data: {
              'error': {
                'message': 'Invalid model specified',
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => service.generateCommand('test'),
          throwsA(isA<AiServiceException>().having(
            (e) => e.message,
            'message',
            equals('Invalid model specified'),
          )),
        );
      });
    });

    group('generateCommandStream', () {
      // @telos-scenario L1:...:cloud_ai_service:stream-tokens
      test('yields tokens from SSE stream', () async {
        // Create a mock stream controller to simulate SSE
        final streamController = StreamController<List<int>>();

        final mockResponseBody = _MockResponseBody(streamController.stream);

        when(() => mockDio.post<ResponseBody>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response<ResponseBody>(
              requestOptions: RequestOptions(path: '/chat/completions'),
              statusCode: 200,
              data: mockResponseBody,
            ));

        final events = <AiStreamEvent>[];
        final subscription = service.generateCommandStream('test').listen(
              events.add,
              onDone: () {},
            );

        // Simulate SSE chunks
        streamController.add(
          utf8.encode('data: {"choices":[{"delta":{"content":"ls"}}]}\n\n'),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));

        streamController.add(
          utf8.encode('data: {"choices":[{"delta":{"content":" -la"}}]}\n\n'),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));

        streamController.add(utf8.encode('data: [DONE]\n\n'));
        await streamController.close();

        await subscription.asFuture<void>();
        await subscription.cancel();

        // Verify tokens were yielded
        expect(events.whereType<AiStreamToken>().length, equals(2));
        expect(events.whereType<AiStreamToken>().map((e) => e.token).join(),
            equals('ls -la'));

        // Verify complete event
        final complete = events.whereType<AiStreamComplete>().first;
        expect(complete.suggestion.command, equals('ls -la'));
      });

      // @telos-scenario L1:...:cloud_ai_service:stream-error-on-no-key
      test('yields error when no API key', () async {
        when(() => mockConfigRepository.getApiKey())
            .thenAnswer((_) async => null);

        final events = await service.generateCommandStream('test').toList();

        expect(events.length, equals(1));
        expect(events.first, isA<AiStreamError>());
        expect((events.first as AiStreamError).code, equals('no_api_key'));
      });
    });

    group('dispose', () {
      // @telos-scenario L1:...:cloud_ai_service:dispose-closes-dio
      test('closes Dio client', () async {
        when(() => mockDio.close()).thenReturn(null);

        await service.dispose();

        verify(() => mockDio.close()).called(1);
      });
    });
  });
}

/// Mock ResponseBody that provides a stream
class _MockResponseBody implements ResponseBody {
  _MockResponseBody(Stream<List<int>> inputStream) {
    _stream = inputStream.map((data) => Uint8List.fromList(data));
  }

  late Stream<Uint8List> _stream;

  @override
  Stream<Uint8List> get stream => _stream;

  @override
  set stream(Stream<Uint8List> value) {
    _stream = value;
  }

  @override
  Map<String, List<String>> headers = {};

  @override
  bool isRedirect = false;

  @override
  List<RedirectRecord>? redirects;

  @override
  int statusCode = 200;

  @override
  String? statusMessage = 'OK';

  @override
  int contentLength = -1;

  @override
  Map<String, dynamic> extra = {};

  @override
  Future<void> close() async {}
}
