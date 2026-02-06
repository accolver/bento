// @telos-test L1:function:lib/features/ai/domain/services:ai_service_factory

import 'package:bento/features/ai/data/services/mock_ai_service.dart';
import 'package:bento/features/ai/domain/entities/ai_config.dart';
import 'package:bento/features/ai/domain/entities/ai_privacy_mode.dart';
import 'package:bento/features/ai/domain/services/ai_service.dart';
import 'package:bento/features/ai/domain/services/ai_service_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiServiceFactory', () {
    late AiServiceFactory factory;

    setUp(() {
      factory = const AiServiceFactory();
    });

    group('createService', () {
      // @telos-scenario L1:function:...:ai_service_factory:unconfigured-returns-mock
      test('returns MockAiService for unconfigured mode', () async {
        final config = AiConfig.unconfigured();

        final service = await factory.createService(config);

        expect(service, isA<MockAiService>());
        expect(service.serviceName, equals('Mock AI'));
      });

      // @telos-scenario L1:function:...:ai_service_factory:local-without-model-returns-mock
      test('returns MockAiService for local mode without model path', () async {
        const config = AiConfig(mode: AiMode.local);

        final service = await factory.createService(config);

        expect(service, isA<MockAiService>());
      });

      // @telos-scenario L1:function:...:ai_service_factory:local-with-invalid-path-returns-mock
      test('returns MockAiService for local mode with invalid model path',
          () async {
        const config = AiConfig(
          mode: AiMode.local,
          localModelPath: '/nonexistent/path/model.gguf',
        );

        final service = await factory.createService(config);

        // Should fall back to mock since local AI isn't implemented yet
        expect(service, isA<MockAiService>());
      });

      // @telos-scenario L1:function:...:ai_service_factory:cloud-without-storage-returns-mock
      test('returns MockAiService for cloud mode without secure storage',
          () async {
        const config = AiConfig(
          mode: AiMode.cloud,
          cloudProvider: CloudAiProvider.gpt4oMini,
        );

        final service = await factory.createService(config);

        // Should fall back to mock since no storage provided
        expect(service, isA<MockAiService>());
      });

      // @telos-scenario L1:function:...:ai_service_factory:remote-without-session-returns-mock
      test('returns MockAiService for remote mode without SSH session',
          () async {
        const config = AiConfig(mode: AiMode.remote, remoteAutoDetect: true);

        final service = await factory.createService(config);

        // Should fall back to mock since no SSH session provided
        expect(service, isA<MockAiService>());
      });
    });

    group('createMockService', () {
      // @telos-scenario L1:function:...:ai_service_factory:create-mock-service
      test('creates a MockAiService', () {
        final service = factory.createMockService();

        expect(service, isA<MockAiService>());
        expect(service.serviceName, equals('Mock AI'));
        expect(service.privacyMode, equals(AiPrivacyMode.local));
      });
    });

    group('createLocalService', () {
      // @telos-scenario L1:function:...:ai_service_factory:local-not-implemented
      test('throws not implemented exception', () async {
        expect(
          () => factory.createLocalService('/some/path.gguf'),
          throwsA(isA<AiServiceException>()),
        );
      });
    });

    group('createCloudService', () {
      // @telos-scenario L1:function:...:ai_service_factory:cloud-not-implemented
      test('throws not implemented exception', () async {
        expect(
          () => factory.createCloudService('api-key', CloudAiProvider.claude),
          throwsA(isA<AiServiceException>()),
        );
      });
    });

    group('createRemoteService', () {
      // @telos-scenario L1:function:...:ai_service_factory:remote-not-implemented
      test('throws not implemented exception', () async {
        expect(
          () => factory.createRemoteService(null),
          throwsA(isA<AiServiceException>()),
        );
      });
    });
  });
}
