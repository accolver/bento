// @telos-test L1:function:lib/features/ai/domain/services:ai_service_factory

import 'package:bento/features/ai/data/repositories/ai_config_repository.dart';
import 'package:bento/features/ai/data/services/cloud_ai_service.dart';
import 'package:bento/features/ai/data/services/unconfigured_ai_service.dart';
import 'package:bento/features/ai/domain/entities/ai_config.dart';
import 'package:bento/features/ai/domain/entities/ai_privacy_mode.dart';
import 'package:bento/features/ai/domain/services/ai_service.dart';
import 'package:bento/features/ai/domain/services/ai_service_factory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAiConfigRepository extends Mock implements AiConfigRepository {}

void main() {
  group('AiServiceFactory', () {
    late AiServiceFactory factory;

    setUp(() {
      factory = const AiServiceFactory();
    });

    group('createService', () {
      // @telos-scenario L1:function:...:ai_service_factory:unconfigured-returns-unconfigured
      test('returns UnconfiguredAiService for unconfigured mode', () async {
        final config = AiConfig.unconfigured();

        final service = await factory.createService(config);

        expect(service, isA<UnconfiguredAiService>());
        expect(service.serviceName, equals('Not Configured'));
      });

      // @telos-scenario L1:function:...:ai_service_factory:local-without-model-returns-unconfigured
      test('returns UnconfiguredAiService for local mode without model path',
          () async {
        const config = AiConfig(mode: AiMode.local);

        final service = await factory.createService(config);

        expect(service, isA<UnconfiguredAiService>());
      });

      // @telos-scenario L1:function:...:ai_service_factory:local-with-invalid-path-returns-unconfigured
      test(
          'returns UnconfiguredAiService for local mode with invalid model path',
          () async {
        const config = AiConfig(
          mode: AiMode.local,
          localModelPath: '/nonexistent/path/model.gguf',
        );

        final service = await factory.createService(config);

        // Should fall back to unconfigured since model doesn't exist
        expect(service, isA<UnconfiguredAiService>());
      });

      // @telos-scenario L1:function:...:ai_service_factory:cloud-without-storage-returns-unconfigured
      test(
          'returns UnconfiguredAiService for cloud mode without secure storage',
          () async {
        const config = AiConfig(
          mode: AiMode.cloud,
          cloudProvider: CloudAiProvider.gpt4oMini,
        );

        final service = await factory.createService(config);

        // Should fall back to unconfigured since no storage provided
        expect(service, isA<UnconfiguredAiService>());
      });

      // @telos-scenario L1:function:...:ai_service_factory:remote-without-session-returns-unconfigured
      test('returns UnconfiguredAiService for remote mode without SSH session',
          () async {
        const config = AiConfig(mode: AiMode.remote, remoteAutoDetect: true);

        final service = await factory.createService(config);

        // Should fall back to unconfigured since no SSH session provided
        expect(service, isA<UnconfiguredAiService>());
      });
    });

    group('createUnconfiguredService', () {
      // @telos-scenario L1:function:...:ai_service_factory:create-unconfigured-service
      test('creates an UnconfiguredAiService', () {
        final service = factory.createUnconfiguredService();

        expect(service, isA<UnconfiguredAiService>());
        expect(service.serviceName, equals('Not Configured'));
        expect(service.privacyMode, equals(AiPrivacyMode.local));
      });
    });

    group('createLocalService', () {
      // @telos-scenario L1:function:...:ai_service_factory:local-not-implemented
      test('throws exception for non-existent model path', () async {
        expect(
          () => factory.createLocalService('/some/path.gguf'),
          throwsA(isA<AiServiceException>()),
        );
      });
    });

    group('createCloudService', () {
      // @telos-scenario L1:function:...:ai_service_factory:cloud-creates-service
      test('creates CloudAiService with repository and provider', () {
        final mockRepo = MockAiConfigRepository();
        final service = factory.createCloudService(
          mockRepo,
          CloudAiProvider.claude,
        );

        expect(service, isA<CloudAiService>());
        expect(service.serviceName, contains('Claude'));
        expect(service.privacyMode, equals(AiPrivacyMode.cloud));
      });
    });

    group('createRemoteService', () {
      // @telos-scenario L1:function:...:ai_service_factory:remote-not-implemented
      test('throws exception for null SSH session', () async {
        expect(
          () => factory.createRemoteService(null),
          throwsA(isA<AiServiceException>()),
        );
      });
    });
  });
}
