// @telos-test L1:function:lib/features/ai/domain/entities:remote_ai_detection

import 'package:bento/features/ai/domain/entities/ollama_model.dart';
import 'package:bento/features/ai/domain/entities/remote_ai_detection.dart';
import 'package:bento/features/ai/domain/entities/remote_ai_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RemoteAiDetectionResult', () {
    final ollamaModel = OllamaModel(
      name: 'llama3:8b',
      modifiedAt: DateTime.now(),
      sizeBytes: 4300000000,
    );

    final anthropicProvider = DetectedCloudProvider(
      provider: RemoteCloudProvider.anthropic,
      envVarName: 'ANTHROPIC_API_KEY',
      displayName: 'Claude (Anthropic)',
      defaultModel: 'claude-sonnet-4-20250514',
      qualityRank: 1,
    );

    final openaiProvider = DetectedCloudProvider(
      provider: RemoteCloudProvider.openai,
      envVarName: 'OPENAI_API_KEY',
      displayName: 'GPT-4o (OpenAI)',
      defaultModel: 'gpt-4o',
      qualityRank: 2,
    );

    // @telos-scenario L1:...:remote_ai_detection:empty-result
    test('empty result has no providers', () {
      final result = RemoteAiDetectionResult.empty('test-host');
      expect(result.hasAnyProvider, false);
      expect(result.hasOllama, false);
      expect(result.hasCloudProviders, false);
      expect(result.providerCount, 0);
      expect(result.bestCloudProvider, isNull);
    });

    // @telos-scenario L1:...:remote_ai_detection:ollama-only
    test('ollama-only result', () {
      final result = RemoteAiDetectionResult(
        hostId: 'test-host',
        ollamaModels: [ollamaModel],
        checkedAt: DateTime.now(),
      );
      expect(result.hasAnyProvider, true);
      expect(result.hasOllama, true);
      expect(result.hasCloudProviders, false);
      expect(result.providerCount, 1);
      expect(result.bestCloudProvider, isNull);
    });

    // @telos-scenario L1:...:remote_ai_detection:cloud-only
    test('cloud-only result returns best provider', () {
      final result = RemoteAiDetectionResult(
        hostId: 'test-host',
        cloudProviders: [openaiProvider, anthropicProvider],
        checkedAt: DateTime.now(),
      );
      expect(result.hasAnyProvider, true);
      expect(result.hasOllama, false);
      expect(result.hasCloudProviders, true);
      expect(result.providerCount, 2);
      // bestCloudProvider returns first in list
      expect(result.bestCloudProvider, openaiProvider);
    });

    // @telos-scenario L1:...:remote_ai_detection:mixed-result
    test('mixed result counts correctly', () {
      final result = RemoteAiDetectionResult(
        hostId: 'test-host',
        ollamaModels: [ollamaModel],
        cloudProviders: [anthropicProvider, openaiProvider],
        checkedAt: DateTime.now(),
      );
      expect(result.hasAnyProvider, true);
      expect(result.hasOllama, true);
      expect(result.hasCloudProviders, true);
      // Ollama counts as 1 + 2 cloud providers = 3
      expect(result.providerCount, 3);
    });

    // @telos-scenario L1:...:remote_ai_detection:staleness
    test('isStale returns true after 5 minutes', () {
      final result = RemoteAiDetectionResult(
        hostId: 'test-host',
        checkedAt: DateTime.now().subtract(const Duration(minutes: 6)),
      );
      expect(result.isStale, true);
    });

    // @telos-scenario L1:...:remote_ai_detection:not-stale
    test('isStale returns false within 5 minutes', () {
      final result = RemoteAiDetectionResult(
        hostId: 'test-host',
        checkedAt: DateTime.now(),
      );
      expect(result.isStale, false);
    });
  });

  group('DetectedCloudProvider', () {
    // @telos-scenario L1:...:remote_ai_detection:provider-equality
    test('equality based on provider and envVarName', () {
      final a = DetectedCloudProvider(
        provider: RemoteCloudProvider.anthropic,
        envVarName: 'ANTHROPIC_API_KEY',
        displayName: 'Claude',
        defaultModel: 'claude-sonnet-4-20250514',
        qualityRank: 1,
      );
      final b = DetectedCloudProvider(
        provider: RemoteCloudProvider.anthropic,
        envVarName: 'ANTHROPIC_API_KEY',
        displayName: 'Claude (different name)',
        defaultModel: 'different-model',
        qualityRank: 99,
      );
      expect(a, equals(b));
    });

    // @telos-scenario L1:...:remote_ai_detection:provider-inequality
    test('different providers are not equal', () {
      final a = DetectedCloudProvider(
        provider: RemoteCloudProvider.anthropic,
        envVarName: 'ANTHROPIC_API_KEY',
        displayName: 'Claude',
        defaultModel: 'claude-sonnet-4-20250514',
        qualityRank: 1,
      );
      final b = DetectedCloudProvider(
        provider: RemoteCloudProvider.openai,
        envVarName: 'OPENAI_API_KEY',
        displayName: 'GPT-4o',
        defaultModel: 'gpt-4o',
        qualityRank: 2,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
