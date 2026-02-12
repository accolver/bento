// @telos-test L1:function:lib/features/ai/domain/entities:remote_ai_config

import 'package:bento/features/ai/domain/entities/remote_ai_config.dart';
import 'package:bento/features/ai/domain/entities/remote_ai_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RemoteAiConfig', () {
    group('ollama factory', () {
      // @telos-scenario L1:...:remote_ai_config:ollama-factory-sets-fields
      test('sets correct backendType and ollamaModel', () {
        final config = RemoteAiConfig.ollama(
          hostId: 'gpu-server',
          model: 'llama3:8b',
        );

        expect(config.hostId, 'gpu-server');
        expect(config.backendType, RemoteBackendType.ollama);
        expect(config.ollamaModel, 'llama3:8b');
        expect(config.cloudProvider, isNull);
        expect(config.envVarName, isNull);
      });

      // @telos-scenario L1:...:remote_ai_config:ollama-default-port
      test('uses default ollamaPort of 11434', () {
        final config = RemoteAiConfig.ollama(
          hostId: 'gpu-server',
          model: 'llama3:8b',
        );

        expect(config.ollamaPort, 11434);
      });

      // @telos-scenario L1:...:remote_ai_config:ollama-custom-port
      test('accepts custom port', () {
        final config = RemoteAiConfig.ollama(
          hostId: 'gpu-server',
          model: 'llama3:8b',
          port: 9999,
        );

        expect(config.ollamaPort, 9999);
      });
    });

    group('cloudProxy factory', () {
      // @telos-scenario L1:...:remote_ai_config:cloud-proxy-factory-sets-fields
      test('sets correct backendType, cloudProvider, and envVarName', () {
        final config = RemoteAiConfig.cloudProxy(
          hostId: 'dev-machine',
          provider: RemoteCloudProvider.anthropic,
          envVarName: 'ANTHROPIC_API_KEY',
        );

        expect(config.hostId, 'dev-machine');
        expect(config.backendType, RemoteBackendType.cloudProxy);
        expect(config.cloudProvider, RemoteCloudProvider.anthropic);
        expect(config.envVarName, 'ANTHROPIC_API_KEY');
        expect(config.ollamaModel, isNull);
      });
    });

    group('isValid', () {
      // @telos-scenario L1:...:remote_ai_config:is-valid-ollama-with-model
      test('returns true for ollama with model set', () {
        final config = RemoteAiConfig.ollama(
          hostId: 'gpu-server',
          model: 'llama3:8b',
        );

        expect(config.isValid, isTrue);
      });

      // @telos-scenario L1:...:remote_ai_config:is-valid-ollama-without-model
      test('returns false for ollama without model', () {
        final config = RemoteAiConfig(
          hostId: 'gpu-server',
          backendType: RemoteBackendType.ollama,
          // ollamaModel intentionally omitted
        );

        expect(config.isValid, isFalse);
      });

      // @telos-scenario L1:...:remote_ai_config:is-valid-cloud-proxy-complete
      test('returns true for cloudProxy with both provider and envVarName', () {
        final config = RemoteAiConfig.cloudProxy(
          hostId: 'dev-machine',
          provider: RemoteCloudProvider.openai,
          envVarName: 'OPENAI_API_KEY',
        );

        expect(config.isValid, isTrue);
      });

      // @telos-scenario L1:...:remote_ai_config:is-valid-cloud-proxy-missing-provider
      test('returns false for cloudProxy missing provider', () {
        final config = RemoteAiConfig(
          hostId: 'dev-machine',
          backendType: RemoteBackendType.cloudProxy,
          envVarName: 'OPENAI_API_KEY',
          // cloudProvider intentionally omitted
        );

        expect(config.isValid, isFalse);
      });

      // @telos-scenario L1:...:remote_ai_config:is-valid-cloud-proxy-missing-env-var
      test('returns false for cloudProxy missing envVarName', () {
        final config = RemoteAiConfig(
          hostId: 'dev-machine',
          backendType: RemoteBackendType.cloudProxy,
          cloudProvider: RemoteCloudProvider.openai,
          // envVarName intentionally omitted
        );

        expect(config.isValid, isFalse);
      });
    });

    group('copyWith', () {
      // @telos-scenario L1:...:remote_ai_config:copy-with
      test('creates modified copy while preserving other fields', () {
        final original = RemoteAiConfig.ollama(
          hostId: 'gpu-server',
          model: 'llama3:8b',
        );

        final modified = original.copyWith(ollamaModel: 'mistral:7b');

        expect(modified.hostId, 'gpu-server');
        expect(modified.backendType, RemoteBackendType.ollama);
        expect(modified.ollamaModel, 'mistral:7b');
        expect(modified.ollamaPort, 11434);
        // Original is unchanged (immutable)
        expect(original.ollamaModel, 'llama3:8b');
      });
    });

    group('equality', () {
      // @telos-scenario L1:...:remote_ai_config:equality
      test('two configs with same values are equal', () {
        final a = RemoteAiConfig.ollama(
          hostId: 'gpu-server',
          model: 'llama3:8b',
        );
        final b = RemoteAiConfig.ollama(
          hostId: 'gpu-server',
          model: 'llama3:8b',
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('two configs with different values are not equal', () {
        final a = RemoteAiConfig.ollama(
          hostId: 'gpu-server',
          model: 'llama3:8b',
        );
        final b = RemoteAiConfig.ollama(
          hostId: 'gpu-server',
          model: 'mistral:7b',
        );

        expect(a, isNot(equals(b)));
      });
    });
  });
}
