// @telos-test L1:function:lib/features/ai/data/repositories:ai_config_repository

import 'package:bento/features/ai/data/repositories/ai_config_repository.dart';
import 'package:bento/features/ai/domain/entities/ai_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late AiConfigRepository repository;
  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockSecureStorage = MockFlutterSecureStorage();
    repository = AiConfigRepository(secureStorage: mockSecureStorage);
  });

  group('AiConfigRepository', () {
    group('loadConfig', () {
      // @telos-scenario L1:...:ai_config_repository:load-unconfigured
      test('returns unconfigured when no config exists', () async {
        final config = await repository.loadConfig();

        expect(config.mode, AiMode.unconfigured);
        expect(config.isConfigured, false);
      });

      // @telos-scenario L1:...:ai_config_repository:load-saved-config
      test('loads saved configuration', () async {
        // Save a config first
        final savedConfig = AiConfig(
          mode: AiMode.cloud,
          cloudProvider: CloudAiProvider.claude,
          configuredAt: DateTime(2024, 1, 15),
        );
        await repository.saveConfig(savedConfig);

        // Load it back
        final loadedConfig = await repository.loadConfig();

        expect(loadedConfig.mode, AiMode.cloud);
        expect(loadedConfig.cloudProvider, CloudAiProvider.claude);
        expect(loadedConfig.configuredAt, DateTime(2024, 1, 15));
      });

      // @telos-scenario L1:...:ai_config_repository:load-local-config
      test('loads local AI configuration correctly', () async {
        final savedConfig = AiConfig(
          mode: AiMode.local,
          localModelId: 'phi3-mini',
          localModelPath: '/path/to/model.gguf',
          configuredAt: DateTime(2024, 1, 15),
        );
        await repository.saveConfig(savedConfig);

        final loadedConfig = await repository.loadConfig();

        expect(loadedConfig.mode, AiMode.local);
        expect(loadedConfig.localModelId, 'phi3-mini');
        expect(loadedConfig.localModelPath, '/path/to/model.gguf');
      });

      // @telos-scenario L1:...:ai_config_repository:load-invalid-json
      test('returns unconfigured for invalid JSON', () async {
        SharedPreferences.setMockInitialValues({
          'bento_ai_config': 'not valid json {{{',
        });
        repository = AiConfigRepository(secureStorage: mockSecureStorage);

        final config = await repository.loadConfig();

        expect(config.mode, AiMode.unconfigured);
      });
    });

    group('saveConfig', () {
      // @telos-scenario L1:...:ai_config_repository:save-cloud-config
      test('saves cloud configuration', () async {
        final config = AiConfig(
          mode: AiMode.cloud,
          cloudProvider: CloudAiProvider.gpt4oMini,
          showPrivacyIndicator: true,
        );

        await repository.saveConfig(config);
        final loadedConfig = await repository.loadConfig();

        expect(loadedConfig.mode, AiMode.cloud);
        expect(loadedConfig.cloudProvider, CloudAiProvider.gpt4oMini);
        expect(loadedConfig.showPrivacyIndicator, true);
      });

      // @telos-scenario L1:...:ai_config_repository:save-remote-config
      test('saves remote configuration', () async {
        final config = AiConfig(
          mode: AiMode.remote,
          remoteAutoDetect: true,
          remoteModelName: 'llama3:8b',
        );

        await repository.saveConfig(config);
        final loadedConfig = await repository.loadConfig();

        expect(loadedConfig.mode, AiMode.remote);
        expect(loadedConfig.remoteAutoDetect, true);
        expect(loadedConfig.remoteModelName, 'llama3:8b');
      });
    });

    group('clearConfig', () {
      // @telos-scenario L1:...:ai_config_repository:clear-config
      test('clears saved configuration', () async {
        when(() => mockSecureStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        // Save a config first
        final config = AiConfig(
          mode: AiMode.cloud,
          cloudProvider: CloudAiProvider.claude,
        );
        await repository.saveConfig(config);

        // Clear it
        await repository.clearConfig();

        // Should return unconfigured
        final loadedConfig = await repository.loadConfig();
        expect(loadedConfig.mode, AiMode.unconfigured);

        // Should have deleted the API key too
        verify(() => mockSecureStorage.delete(key: 'bento_ai_api_key'))
            .called(1);
      });
    });

    group('API key management', () {
      // @telos-scenario L1:...:ai_config_repository:save-api-key
      test('saves API key to secure storage', () async {
        when(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        await repository.saveApiKey('sk-or-test-key-123');

        verify(() => mockSecureStorage.write(
              key: 'bento_ai_api_key',
              value: 'sk-or-test-key-123',
            )).called(1);
      });

      // @telos-scenario L1:...:ai_config_repository:get-api-key
      test('gets API key from secure storage', () async {
        when(() => mockSecureStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => 'sk-or-test-key-123');

        final apiKey = await repository.getApiKey();

        expect(apiKey, 'sk-or-test-key-123');
        verify(() => mockSecureStorage.read(key: 'bento_ai_api_key')).called(1);
      });

      // @telos-scenario L1:...:ai_config_repository:get-api-key-null
      test('returns null when no API key stored', () async {
        when(() => mockSecureStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => null);

        final apiKey = await repository.getApiKey();

        expect(apiKey, isNull);
      });

      // @telos-scenario L1:...:ai_config_repository:delete-api-key
      test('deletes API key from secure storage', () async {
        when(() => mockSecureStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        await repository.deleteApiKey();

        verify(() => mockSecureStorage.delete(key: 'bento_ai_api_key'))
            .called(1);
      });

      // @telos-scenario L1:...:ai_config_repository:has-api-key-true
      test('hasApiKey returns true when key exists', () async {
        when(() => mockSecureStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => 'sk-or-test-key');

        final hasKey = await repository.hasApiKey();

        expect(hasKey, true);
      });

      // @telos-scenario L1:...:ai_config_repository:has-api-key-false
      test('hasApiKey returns false when key is null', () async {
        when(() => mockSecureStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => null);

        final hasKey = await repository.hasApiKey();

        expect(hasKey, false);
      });

      // @telos-scenario L1:...:ai_config_repository:has-api-key-empty
      test('hasApiKey returns false when key is empty', () async {
        when(() => mockSecureStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => '');

        final hasKey = await repository.hasApiKey();

        expect(hasKey, false);
      });
    });

    group('serialization edge cases', () {
      // @telos-scenario L1:...:ai_config_repository:all-providers
      test('correctly serializes all cloud providers', () async {
        for (final provider in CloudAiProvider.values) {
          final config = AiConfig(
            mode: AiMode.cloud,
            cloudProvider: provider,
          );
          await repository.saveConfig(config);
          final loaded = await repository.loadConfig();

          expect(loaded.cloudProvider, provider);
        }
      });

      // @telos-scenario L1:...:ai_config_repository:all-modes
      test('correctly serializes all AI modes', () async {
        for (final mode in AiMode.values) {
          final config = AiConfig(mode: mode);
          await repository.saveConfig(config);
          final loaded = await repository.loadConfig();

          expect(loaded.mode, mode);
        }
      });

      // @telos-scenario L1:...:ai_config_repository:timestamps
      test('preserves timestamps correctly', () async {
        final configuredAt = DateTime(2024, 6, 15, 10, 30);
        final lastUsedAt = DateTime(2024, 6, 16, 14, 45);

        final config = AiConfig(
          mode: AiMode.cloud,
          cloudProvider: CloudAiProvider.claude,
          configuredAt: configuredAt,
          lastUsedAt: lastUsedAt,
        );
        await repository.saveConfig(config);
        final loaded = await repository.loadConfig();

        expect(loaded.configuredAt, configuredAt);
        expect(loaded.lastUsedAt, lastUsedAt);
      });
    });
  });
}
