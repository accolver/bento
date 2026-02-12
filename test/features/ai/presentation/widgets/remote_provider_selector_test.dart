// @telos-test L2:contract:lib/features/ai/presentation/widgets:remote_provider_selector

import 'package:bento/features/ai/data/services/remote_ai_service.dart';
import 'package:bento/features/ai/domain/entities/ollama_model.dart';
import 'package:bento/features/ai/domain/entities/remote_ai_config.dart';
import 'package:bento/features/ai/domain/entities/remote_ai_detection.dart';
import 'package:bento/features/ai/domain/entities/remote_ai_provider.dart';
import 'package:bento/features/ai/presentation/providers/remote_ai_providers.dart';
import 'package:bento/features/ai/presentation/widgets/remote_provider_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testHostId = 'test-host:22';
  const testHostname = 'my-server';

  final ollamaModel1 = OllamaModel(
    name: 'llama3:8b',
    sizeBytes: 4661224676,
    modifiedAt: DateTime(2025, 1, 1),
  );

  final ollamaModel2 = OllamaModel(
    name: 'codellama:7b',
    sizeBytes: 3825820160,
    modifiedAt: DateTime(2025, 1, 1),
  );

  final cloudAnthropic = DetectedCloudProvider(
    provider: RemoteCloudProvider.anthropic,
    envVarName: 'ANTHROPIC_API_KEY',
    displayName: 'Claude (Anthropic)',
    defaultModel: 'claude-sonnet-4-20250514',
    qualityRank: 1,
  );

  final cloudOpenAI = DetectedCloudProvider(
    provider: RemoteCloudProvider.openai,
    envVarName: 'OPENAI_API_KEY',
    displayName: 'GPT-4o (OpenAI)',
    defaultModel: 'gpt-4o',
    qualityRank: 2,
  );

  final detectionBoth = RemoteAiDetectionResult(
    hostId: testHostId,
    ollamaModels: [ollamaModel1, ollamaModel2],
    cloudProviders: [cloudAnthropic, cloudOpenAI],
    checkedAt: DateTime.now(),
  );

  final detectionOnlyOllama = RemoteAiDetectionResult(
    hostId: testHostId,
    ollamaModels: [ollamaModel1],
    cloudProviders: [],
    checkedAt: DateTime.now(),
  );

  final detectionOnlyCloud = RemoteAiDetectionResult(
    hostId: testHostId,
    ollamaModels: [],
    cloudProviders: [cloudAnthropic, cloudOpenAI],
    checkedAt: DateTime.now(),
  );

  Widget createTestWidget({
    required RemoteAiDetectionResult detectionResult,
    VoidCallback? onSelected,
  }) {
    return ProviderScope(
      overrides: [
        // Service controller returns null (no active service)
        remoteAiServiceControllerProvider(testHostId).overrideWith(
          () => _TestServiceController(),
        ),
        // Config state returns null
        remoteAiConfigStateProvider(testHostId).overrideWith(
          () => _TestConfigState(),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 600,
            child: RemoteProviderSelector(
              hostId: testHostId,
              hostname: testHostname,
              detectionResult: detectionResult,
              onSelected: onSelected,
            ),
          ),
        ),
      ),
    );
  }

  group('RemoteProviderSelector', () {
    // @telos-scenario L2:contract:...:remote_provider_selector:shows-title
    testWidgets('shows title with hostname', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionBoth,
      ));
      await tester.pump();

      expect(find.textContaining('AI Providers on my-server'), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_provider_selector:shows-cloud-section
    testWidgets('shows Cloud Providers section header', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionBoth,
      ));
      await tester.pump();

      expect(find.text('Cloud Providers'), findsOneWidget);
      expect(find.text('Keys on remote host'), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_provider_selector:shows-ollama-section
    testWidgets('shows Ollama section header', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionBoth,
      ));
      await tester.pump();

      expect(find.text('Ollama'), findsOneWidget);
      expect(find.text('Local inference on server'), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_provider_selector:shows-cloud-providers
    testWidgets('shows cloud provider names', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionBoth,
      ));
      await tester.pump();

      expect(find.text('Claude (Anthropic)'), findsOneWidget);
      expect(find.text('GPT-4o (OpenAI)'), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_provider_selector:shows-env-var
    testWidgets('shows environment variable name for cloud providers',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionOnlyCloud,
      ));
      await tester.pump();

      expect(find.textContaining(r'$ANTHROPIC_API_KEY'), findsOneWidget);
      expect(find.textContaining(r'$OPENAI_API_KEY'), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_provider_selector:shows-best-badge
    testWidgets('shows Best badge on recommended provider', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionBoth,
      ));
      await tester.pump();

      // Anthropic is qualityRank 1, so it should have the "Best" badge
      expect(find.text('Best'), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_provider_selector:shows-ollama-models
    testWidgets('shows Ollama model names', (tester) async {
      // Use only Ollama so models appear without scrolling
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionOnlyOllama,
      ));
      await tester.pump();

      // displayName capitalizes first letter of base name
      expect(find.text('Llama3'), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_provider_selector:shows-model-size
    testWidgets('shows Ollama model size', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionOnlyOllama,
      ));
      await tester.pump();

      expect(find.textContaining('4.7 GB'), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_provider_selector:privacy-badges-cloud
    testWidgets('shows Cloud via remote privacy badges', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionOnlyCloud,
      ));
      await tester.pump();

      // Cloud providers get "Cloud via remote" badge
      expect(find.text('Cloud via remote'), findsNWidgets(2));
    });

    // @telos-scenario L2:contract:...:remote_provider_selector:privacy-badges-ollama
    testWidgets('shows Local inference privacy badge', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionOnlyOllama,
      ));
      await tester.pump();

      // Ollama models get "Local inference" badge
      expect(find.text('Local inference'), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_provider_selector:cloud-icon
    testWidgets('shows cloud_outlined icon for cloud providers',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionOnlyCloud,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.cloud_outlined), findsNWidgets(2));
    });

    // @telos-scenario L2:contract:...:remote_provider_selector:memory-icon
    testWidgets('shows memory icon for Ollama models', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionOnlyOllama,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.memory), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_provider_selector:no-cloud-section-if-none
    testWidgets('hides Cloud section when no cloud providers', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionOnlyOllama,
      ));
      await tester.pump();

      expect(find.text('Cloud Providers'), findsNothing);
    });

    // @telos-scenario L2:contract:...:remote_provider_selector:no-ollama-section-if-none
    testWidgets('hides Ollama section when no Ollama models', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionOnlyCloud,
      ));
      await tester.pump();

      // The Ollama section header should not appear
      expect(find.text('Local inference on server'), findsNothing);
    });

    // @telos-scenario L2:contract:...:remote_provider_selector:shield-icon
    testWidgets('shows shield icon in privacy badges', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionOnlyCloud,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.shield_outlined), findsNWidgets(2));
    });

    // @telos-scenario L2:contract:...:remote_provider_selector:title-icon
    testWidgets('shows auto_awesome icon in title', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionBoth,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });
  });
}

/// Test implementation that returns null (no active service).
class _TestServiceController extends RemoteAiServiceController {
  @override
  RemoteAiService? build(String hostId) => null;
}

/// Test implementation that returns null config.
class _TestConfigState extends RemoteAiConfigState {
  @override
  RemoteAiConfig? build(String hostId) => null;
}
