// @telos-test L2:contract:lib/features/ai/domain/services:ai_service

import 'package:bento/features/ai/data/services/mock_ai_service.dart';
import 'package:bento/features/ai/domain/entities/ai_privacy_mode.dart';
import 'package:bento/features/ai/domain/entities/ai_suggestion.dart';
import 'package:bento/features/ai/domain/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiService interface compliance', () {
    group('MockAiService', () {
      late MockAiService service;

      setUp(() {
        service = MockAiService(
          minDelay: Duration.zero,
          maxDelay: const Duration(milliseconds: 10),
        );
      });

      tearDown(() async {
        await service.dispose();
      });

      // @telos-scenario L2:...:ai_service:implements-interface
      test('implements AiService interface', () {
        expect(service, isA<AiService>());
      });

      // @telos-scenario L2:...:ai_service:has-service-name
      test('has serviceName property', () {
        expect(service.serviceName, isNotEmpty);
        expect(service.serviceName, equals('Mock AI'));
      });

      // @telos-scenario L2:...:ai_service:has-privacy-mode
      test('has privacyMode property', () {
        expect(service.privacyMode, equals(AiPrivacyMode.local));
      });

      // @telos-scenario L2:...:ai_service:is-available
      test('isAvailable returns true', () async {
        final available = await service.isAvailable();
        expect(available, isTrue);
      });

      // @telos-scenario L2:...:ai_service:generate-command-returns-suggestion
      test('generateCommand returns AiSuggestion', () async {
        final suggestion = await service.generateCommand('list files');

        expect(suggestion, isNotNull);
        expect(suggestion.command, isNotEmpty);
        expect(suggestion.explanation, isNotEmpty);
        expect(suggestion.confidence, greaterThanOrEqualTo(0));
        expect(suggestion.confidence, lessThanOrEqualTo(1));
      });

      // @telos-scenario L2:...:ai_service:stream-yields-events
      test('generateCommandStream yields token events', () async {
        final events = <AiStreamEvent>[];

        await for (final event in service.generateCommandStream('list files')) {
          events.add(event);
        }

        expect(events, isNotEmpty);

        // Should have token events
        final tokens = events.whereType<AiStreamToken>().toList();
        expect(tokens, isNotEmpty);

        // Should end with complete event
        final completeEvents = events.whereType<AiStreamComplete>().toList();
        expect(completeEvents, hasLength(1));

        // Complete event should have suggestion
        expect(completeEvents.first.suggestion, isNotNull);
        expect(completeEvents.first.suggestion.command, isNotEmpty);
      });

      // @telos-scenario L2:...:ai_service:stream-tokens-match-final
      test('stream tokens match final suggestion', () async {
        final events = <AiStreamEvent>[];

        await for (final event in service.generateCommandStream('list files')) {
          events.add(event);
        }

        // Collect all tokens
        final tokenText =
            events.whereType<AiStreamToken>().map((e) => e.token).join();

        // Get final suggestion
        final complete = events.whereType<AiStreamComplete>().first;

        // Tokens should form the final command
        expect(tokenText, equals(complete.suggestion.command));
      });

      // @telos-scenario L2:...:ai_service:dispose-is-safe
      test('dispose can be called safely', () async {
        // Should not throw
        await service.dispose();

        // Can be called multiple times
        await service.dispose();
      });
    });
  });

  group('AiStreamEvent types', () {
    // @telos-scenario L2:...:ai_service:stream-token-has-text
    test('AiStreamToken has token text', () {
      const token = AiStreamToken('hello');
      expect(token.token, equals('hello'));
      expect(token.toString(), contains('hello'));
    });

    // @telos-scenario L2:...:ai_service:stream-complete-has-suggestion
    test('AiStreamComplete has suggestion', () {
      const suggestion = AiSuggestion(
        command: 'ls -la',
        explanation: 'List files',
        confidence: 0.9,
      );
      final complete = AiStreamComplete(suggestion);

      expect(complete.suggestion, equals(suggestion));
      expect(complete.toString(), contains('ls -la'));
    });

    // @telos-scenario L2:...:ai_service:stream-error-has-message
    test('AiStreamError has message', () {
      const error = AiStreamError('Something went wrong', code: 'test_error');

      expect(error.message, equals('Something went wrong'));
      expect(error.code, equals('test_error'));
      expect(error.toString(), contains('Something went wrong'));
    });
  });

  group('AiServiceException', () {
    // @telos-scenario L2:...:ai_service:exception-has-message
    test('has message', () {
      const exception = AiServiceException('Test error');
      expect(exception.message, equals('Test error'));
      expect(exception.toString(), contains('Test error'));
    });

    // @telos-scenario L2:...:ai_service:exception-has-code
    test('can have code', () {
      const exception = AiServiceException(
        'Test error',
        code: 'test_code',
      );
      expect(exception.code, equals('test_code'));
    });

    // @telos-scenario L2:...:ai_service:exception-has-original-error
    test('can wrap original error', () {
      final originalError = Exception('Original');
      final exception = AiServiceException(
        'Wrapped error',
        originalError: originalError,
      );
      expect(exception.originalError, equals(originalError));
    });

    // @telos-scenario L2:...:ai_service:exception-retryable-flag
    test('has isRetryable flag', () {
      const retryable = AiServiceException(
        'Network error',
        isRetryable: true,
      );
      const notRetryable = AiServiceException(
        'Invalid key',
        isRetryable: false,
      );

      expect(retryable.isRetryable, isTrue);
      expect(notRetryable.isRetryable, isFalse);
    });
  });
}
