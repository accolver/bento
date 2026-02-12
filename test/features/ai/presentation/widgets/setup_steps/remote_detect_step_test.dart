// @telos-test L2:contract:lib/features/ai/presentation/widgets/setup_steps:remote_detect_step

import 'package:bento/features/ai/domain/entities/ollama_model.dart';
import 'package:bento/features/ai/domain/entities/remote_ai_detection.dart';
import 'package:bento/features/ai/domain/entities/remote_ai_provider.dart';
import 'package:bento/features/ai/presentation/providers/remote_ai_providers.dart';
import 'package:bento/features/ai/presentation/widgets/setup_steps/remote_detect_step.dart';
import 'package:bento/features/session/domain/entities/session.dart';
import 'package:bento/features/session/domain/entities/session_status.dart';
import 'package:bento/features/session/presentation/providers/session_list_controller.dart';
import 'package:bento/features/session/presentation/providers/session_list_state.dart';
import 'package:bento/features/terminal/domain/entities/ssh_auth_method.dart';
import 'package:bento/features/terminal/domain/entities/ssh_connection_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testConfig = SSHConnectionConfig(
    host: 'my-server.local',
    authMethod: const SSHAuthMethod.password(
      username: 'user',
      password: 'pass',
    ),
    port: 22,
  );

  final connectedSession = Session(
    id: 'session-1',
    name: 'my-server',
    connectionConfig: testConfig,
    status: SessionStatus.connected,
    createdAt: DateTime(2025, 1, 1),
    lastAccessedAt: DateTime(2025, 1, 1),
  );

  final connectedSessionState = SessionListState(
    sessions: [connectedSession],
    activeSessionId: 'session-1',
  );

  const noSessionState = SessionListState();

  const testHostId = 'my-server.local:22';

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

  final detectionWithProviders = RemoteAiDetectionResult(
    hostId: testHostId,
    ollamaModels: [ollamaModel],
    cloudProviders: [cloudProvider],
    checkedAt: DateTime.now(),
  );

  Widget createTestWidget({
    required SessionListState sessionState,
    RemoteAiDetectionResult? detectionResult,
    bool isDetecting = false,
    VoidCallback? onComplete,
    ValueChanged<bool>? onAutoDetectChanged,
  }) {
    return ProviderScope(
      overrides: [
        sessionListControllerProvider.overrideWith(
          () {
            final controller = _TestSessionListController();
            controller.testState = sessionState;
            return controller;
          },
        ),
        if (sessionState.sessions.isNotEmpty)
          remoteAiDetectionStateProvider(testHostId).overrideWith(
            () {
              final notifier = _TestDetectionState();
              notifier.testResult = detectionResult;
              notifier.testIsLoading = isDetecting;
              return notifier;
            },
          ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              height: 1200,
              child: RemoteDetectStep(
                onComplete: onComplete ?? () {},
                onAutoDetectChanged: onAutoDetectChanged,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('RemoteDetectStep', () {
    // @telos-scenario L2:contract:...:remote_detect_step:shows-title
    testWidgets('shows title and subtitle', (tester) async {
      await tester.pumpWidget(createTestWidget(
        sessionState: noSessionState,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Remote AI Detection'), findsOneWidget);
      expect(
        find.text('Use AI on servers you connect to via SSH'),
        findsOneWidget,
      );
    });

    // @telos-scenario L2:contract:...:remote_detect_step:auto-detect-toggle
    testWidgets('shows auto-detect toggle', (tester) async {
      await tester.pumpWidget(createTestWidget(
        sessionState: noSessionState,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Auto-detect AI providers'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_detect_step:auto-detect-toggle-callback
    testWidgets('auto-detect toggle fires callback', (tester) async {
      bool? toggleValue;

      await tester.pumpWidget(createTestWidget(
        sessionState: noSessionState,
        onAutoDetectChanged: (value) => toggleValue = value,
      ));
      await tester.pumpAndSettle();

      // Toggle is on by default, tap to turn off
      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(toggleValue, equals(false));
    });

    // @telos-scenario L2:contract:...:remote_detect_step:privacy-info
    testWidgets('shows privacy info', (tester) async {
      await tester.pumpWidget(createTestWidget(
        sessionState: noSessionState,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Privacy First'), findsOneWidget);
      expect(
        find.textContaining('Bento never reads your API key values'),
        findsOneWidget,
      );
    });

    // @telos-scenario L2:contract:...:remote_detect_step:what-bento-detects-no-ssh
    testWidgets('shows What Bento detects when no SSH', (tester) async {
      await tester.pumpWidget(createTestWidget(
        sessionState: noSessionState,
      ));
      await tester.pumpAndSettle();

      expect(find.text('What Bento detects'), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_detect_step:how-it-works-no-ssh
    testWidgets('shows How it works when no SSH', (tester) async {
      await tester.pumpWidget(createTestWidget(
        sessionState: noSessionState,
      ));
      await tester.pumpAndSettle();

      expect(find.text('How it works'), findsOneWidget);
      expect(
        find.text('Connect to a server via SSH'),
        findsOneWidget,
      );
    });

    // @telos-scenario L2:contract:...:remote_detect_step:done-button-no-providers
    testWidgets('shows Done button when no providers detected', (tester) async {
      await tester.pumpWidget(createTestWidget(
        sessionState: noSessionState,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Done'), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_detect_step:done-button-calls-complete
    testWidgets('Done button calls onComplete', (tester) async {
      var completeCalled = false;

      await tester.pumpWidget(createTestWidget(
        sessionState: noSessionState,
        onComplete: () => completeCalled = true,
      ));
      await tester.pumpAndSettle();

      // Scroll down to make the button visible
      await tester.scrollUntilVisible(
        find.text('Done'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done'));
      await tester.pump();

      expect(completeCalled, isTrue);
    });

    // @telos-scenario L2:contract:...:remote_detect_step:shows-detection-results
    testWidgets('shows detection results when SSH connected', (tester) async {
      await tester.pumpWidget(createTestWidget(
        sessionState: connectedSessionState,
        detectionResult: detectionWithProviders,
      ));
      await tester.pumpAndSettle();

      // Should show found providers
      expect(find.textContaining('Found on'), findsOneWidget);
      expect(find.text('Llama3'), findsOneWidget);
      expect(find.text('Claude (Anthropic)'), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_detect_step:enable-button-with-providers
    testWidgets('shows Enable Remote AI button when providers found',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        sessionState: connectedSessionState,
        detectionResult: detectionWithProviders,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Enable Remote AI'), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_detect_step:no-detection-found
    testWidgets('shows no providers message when detection returns empty',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        sessionState: connectedSessionState,
        detectionResult: RemoteAiDetectionResult.empty(testHostId),
      ));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No AI providers found'),
        findsOneWidget,
      );
    });

    // @telos-scenario L2:contract:...:remote_detect_step:best-badge
    testWidgets('shows Best badge on recommended cloud provider',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        sessionState: connectedSessionState,
        detectionResult: detectionWithProviders,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Best'), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_detect_step:local-badge
    testWidgets('shows Local badge for Ollama models', (tester) async {
      await tester.pumpWidget(createTestWidget(
        sessionState: connectedSessionState,
        detectionResult: detectionWithProviders,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Local'), findsOneWidget);
    });
  });
}

/// Test implementation that returns a fixed session state.
class _TestSessionListController extends SessionListController {
  SessionListState testState = const SessionListState();

  @override
  SessionListState build() => testState;
}

/// Test implementation that returns a fixed detection result.
class _TestDetectionState extends RemoteAiDetectionState {
  RemoteAiDetectionResult? testResult;
  bool testIsLoading = false;

  @override
  Future<RemoteAiDetectionResult?> build(String hostId) async {
    return testResult;
  }
}
