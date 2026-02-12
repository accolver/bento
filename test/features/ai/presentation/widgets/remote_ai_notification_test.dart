// @telos-test L2:contract:lib/features/ai/presentation/widgets:remote_ai_notification

import 'package:bento/features/ai/domain/entities/ollama_model.dart';
import 'package:bento/features/ai/domain/entities/remote_ai_detection.dart';
import 'package:bento/features/ai/domain/entities/remote_ai_provider.dart';
import 'package:bento/features/ai/presentation/providers/remote_ai_providers.dart';
import 'package:bento/features/ai/presentation/widgets/remote_ai_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Test data
  const testHostId = 'test-host:22';
  const testHostname = 'my-server';

  final ollamaModel = OllamaModel(
    name: 'llama3:8b',
    sizeBytes: 4661224676,
    modifiedAt: DateTime(2025, 1, 1),
  );

  final cloudProvider = DetectedCloudProvider(
    provider: RemoteCloudProvider.anthropic,
    envVarName: 'ANTHROPIC_API_KEY',
    displayName: 'Claude (Anthropic)',
    defaultModel: 'claude-sonnet-4-20250514',
    qualityRank: 1,
  );

  final cloudProvider2 = DetectedCloudProvider(
    provider: RemoteCloudProvider.openai,
    envVarName: 'OPENAI_API_KEY',
    displayName: 'GPT-4o (OpenAI)',
    defaultModel: 'gpt-4o',
    qualityRank: 2,
  );

  final cloudProvider3 = DetectedCloudProvider(
    provider: RemoteCloudProvider.groq,
    envVarName: 'GROQ_API_KEY',
    displayName: 'Groq',
    defaultModel: 'llama-3.3-70b-versatile',
    qualityRank: 4,
  );

  final detectionWithProviders = RemoteAiDetectionResult(
    hostId: testHostId,
    ollamaModels: [ollamaModel],
    cloudProviders: [cloudProvider, cloudProvider2],
    checkedAt: DateTime.now(),
  );

  final detectionOnlyOllama = RemoteAiDetectionResult(
    hostId: testHostId,
    ollamaModels: [ollamaModel],
    cloudProviders: [],
    checkedAt: DateTime.now(),
  );

  final detectionOnlyCloud = RemoteAiDetectionResult(
    hostId: testHostId,
    ollamaModels: [],
    cloudProviders: [cloudProvider],
    checkedAt: DateTime.now(),
  );

  final detectionManyCloud = RemoteAiDetectionResult(
    hostId: testHostId,
    ollamaModels: [],
    cloudProviders: [cloudProvider, cloudProvider2, cloudProvider3],
    checkedAt: DateTime.now(),
  );

  final emptyDetection = RemoteAiDetectionResult.empty(testHostId);

  Widget createTestWidget({
    required RemoteAiDetectionResult? detectionResult,
    VoidCallback? onConfigure,
  }) {
    return ProviderScope(
      overrides: [
        remoteAiDetectionStateProvider(testHostId).overrideWith(
          () {
            final notifier = _TestDetectionState();
            notifier.testResult = detectionResult;
            return notifier;
          },
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: RemoteAiNotification(
            hostId: testHostId,
            hostname: testHostname,
            onConfigure: onConfigure ?? () {},
          ),
        ),
      ),
    );
  }

  group('RemoteAiNotification', () {
    // @telos-scenario L2:contract:...:remote_ai_notification:shows-provider-count
    testWidgets('shows provider count when providers detected', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionWithProviders,
      ));
      await tester.pumpAndSettle();

      // 1 Ollama + 2 cloud = 3 providers
      expect(find.textContaining('3 AI providers found'), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_ai_notification:singular-provider
    testWidgets('shows singular text for single provider', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionOnlyCloud,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('1 AI provider found'), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_ai_notification:shows-summary-ollama
    testWidgets('shows Ollama in summary when detected', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionOnlyOllama,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ollama'), findsOneWidget);
      expect(find.textContaining('1 model'), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_ai_notification:shows-summary-cloud
    testWidgets('shows cloud provider names in summary', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionWithProviders,
      ));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Claude (Anthropic)'),
        findsOneWidget,
      );
    });

    // @telos-scenario L2:contract:...:remote_ai_notification:truncates-many-providers
    testWidgets('truncates when more than 2 cloud providers', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionManyCloud,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('+1 more'), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_ai_notification:shows-hostname
    testWidgets('shows hostname in summary', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionOnlyCloud,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('my-server'), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_ai_notification:configure-button
    testWidgets('shows Configure text', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionOnlyCloud,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Configure'), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_ai_notification:tap-calls-configure
    testWidgets('tap calls onConfigure callback', (tester) async {
      var configureCount = 0;

      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionOnlyCloud,
        onConfigure: () => configureCount++,
      ));
      await tester.pumpAndSettle();

      // Tap the banner (InkWell area)
      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(configureCount, equals(1));
    });

    // @telos-scenario L2:contract:...:remote_ai_notification:dismiss-hides
    testWidgets('dismiss button hides the notification', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionOnlyCloud,
      ));
      await tester.pumpAndSettle();

      // Should be visible
      expect(find.text('Configure'), findsOneWidget);

      // Tap the close icon
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Should be hidden
      expect(find.text('Configure'), findsNothing);
    });

    // @telos-scenario L2:contract:...:remote_ai_notification:hidden-no-providers
    testWidgets('hidden when no providers detected', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: emptyDetection,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Configure'), findsNothing);
      expect(find.byType(RemoteAiNotification), findsOneWidget);
      // Widget renders SizedBox.shrink
    });

    // @telos-scenario L2:contract:...:remote_ai_notification:hidden-null-result
    testWidgets('hidden when detection result is null', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: null,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Configure'), findsNothing);
    });

    // @telos-scenario L2:contract:...:remote_ai_notification:has-icon
    testWidgets('shows auto_awesome icon', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionOnlyCloud,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_ai_notification:has-chevron
    testWidgets('shows chevron_right icon', (tester) async {
      await tester.pumpWidget(createTestWidget(
        detectionResult: detectionOnlyCloud,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });
}

/// Test implementation of RemoteAiDetectionState that returns a fixed result.
class _TestDetectionState extends RemoteAiDetectionState {
  RemoteAiDetectionResult? testResult;

  @override
  Future<RemoteAiDetectionResult?> build(String hostId) async {
    return testResult;
  }
}
