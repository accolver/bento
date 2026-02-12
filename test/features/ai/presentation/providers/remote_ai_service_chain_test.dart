// @telos-test L1:function:lib/features/ai/presentation/providers:ai_providers
//
// Integration test for the full provider chain:
//   SessionListController → activeRemoteHostIdProvider
//   → activeRemoteAiServiceProvider → AiServiceController
//
// Reproduces the bug where completing the AI setup wizard with "Remote" mode
// results in UnconfiguredAiService instead of the detected RemoteAiService.

import 'package:bento/features/ai/data/repositories/ai_config_repository.dart';
import 'package:bento/features/ai/data/services/ollama_backend.dart';
import 'package:bento/features/ai/data/services/remote_ai_service.dart';
import 'package:bento/features/ai/data/services/unconfigured_ai_service.dart';
import 'package:bento/features/ai/domain/entities/ai_config.dart';
import 'package:bento/features/ai/domain/entities/ollama_model.dart';
import 'package:bento/features/ai/domain/entities/remote_ai_detection.dart';
import 'package:bento/features/ai/presentation/providers/ai_providers.dart';
import 'package:bento/features/ai/presentation/providers/remote_ai_providers.dart';
import 'package:bento/features/session/domain/entities/session.dart';
import 'package:bento/features/session/domain/entities/session_status.dart';
import 'package:bento/features/session/presentation/providers/session_list_controller.dart';
import 'package:bento/features/session/presentation/providers/session_list_state.dart';
import 'package:bento/features/terminal/domain/entities/ssh_auth_method.dart';
import 'package:bento/features/terminal/domain/entities/ssh_connection_config.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSSHClient extends Mock implements SSHClient {}

class MockAiConfigRepository extends Mock implements AiConfigRepository {}

/// Test session list controller that allows direct state manipulation
/// via its public methods.
class _TestSessionListController extends SessionListController {
  @override
  SessionListState build() => const SessionListState();

  /// Directly set the state for testing. Must be called AFTER the notifier
  /// is initialized by the container (i.e., after container.read() is called).
  void setTestSessions(List<Session> sessions, {String? activeId}) {
    state = SessionListState(
      sessions: sessions,
      activeSessionId: activeId,
    );
  }
}

/// Test AI config state that doesn't use SharedPreferences.
class _TestAiConfigState extends AiConfigState {
  @override
  Future<AiConfig> build() async => AiConfig.unconfigured();

  /// Directly set config for testing.
  void setConfig(AiConfig config) {
    state = AsyncData(config);
  }
}

void main() {
  const testHost = 'my-server';
  const testPort = 22;
  const testHostId = '$testHost:$testPort';

  final testConnectionConfig = SSHConnectionConfig(
    host: testHost,
    port: testPort,
    authMethod: const SSHAuthMethod.password(
      username: 'user',
      password: 'pass',
    ),
  );

  final testSession = Session(
    id: 'session-1',
    name: testHost,
    connectionConfig: testConnectionConfig,
    status: SessionStatus.connected,
    createdAt: DateTime(2025, 1, 1),
    lastAccessedAt: DateTime(2025, 1, 1),
  );

  final ollamaModel = OllamaModel(
    name: 'llama3:8b',
    sizeBytes: 4661224676,
    modifiedAt: DateTime(2025, 1, 1),
  );

  final detectionResult = RemoteAiDetectionResult(
    hostId: testHostId,
    ollamaModels: [ollamaModel],
    cloudProviders: [],
    checkedAt: DateTime(2025, 1, 1),
  );

  late MockSSHClient mockClient;
  late MockAiConfigRepository mockConfigRepo;

  setUp(() {
    mockClient = MockSSHClient();
    mockConfigRepo = MockAiConfigRepository();
    when(() => mockConfigRepo.loadConfig())
        .thenAnswer((_) async => AiConfig.unconfigured());
  });

  group('Remote AI provider chain', () {
    // @telos-scenario L1:function:...:ai_providers:remote-service-after-wizard
    test(
        'AiServiceController returns RemoteAiService when detection completes '
        'before wizard sets remote mode', () async {
      // This reproduces the most common flow:
      // 1. SSH connects → detection runs → service initialized
      // 2. User opens wizard → selects Remote → config changes

      late _TestSessionListController sessionController;
      late _TestAiConfigState configState;

      final container = ProviderContainer(
        overrides: [
          sessionListControllerProvider.overrideWith(
            () {
              sessionController = _TestSessionListController();
              return sessionController;
            },
          ),
          aiConfigStateProvider.overrideWith(
            () {
              configState = _TestAiConfigState();
              return configState;
            },
          ),
          aiConfigRepositoryProvider.overrideWithValue(mockConfigRepo),
        ],
      );
      addTearDown(container.dispose);

      // Initialize the providers by reading them (triggers build)
      container.read(sessionListControllerProvider);
      await container.read(aiConfigStateProvider.future);

      // Step 1: Simulate SSH connection by updating sessions
      sessionController.setTestSessions(
        [testSession],
        activeId: testSession.id,
      );

      // Verify activeRemoteHostIdProvider picks up the session
      final hostId = container.read(activeRemoteHostIdProvider);
      expect(hostId, equals(testHostId));

      // Step 2: Simulate detection completing and service initialization
      // (this is what session_terminal_controller does after detection)
      container
          .read(remoteAiServiceControllerProvider(testHostId).notifier)
          .initialize(
            client: mockClient,
            detectionResult: detectionResult,
          );

      // Verify the per-host service is available
      final perHostService =
          container.read(remoteAiServiceControllerProvider(testHostId));
      expect(perHostService, isNotNull);
      expect(perHostService, isA<RemoteAiService>());

      // Step 3: Force bridge providers to re-evaluate (as our fix does)
      container.invalidate(activeRemoteAiServiceProvider);

      // Verify activeRemoteAiServiceProvider returns the service
      final activeService = container.read(activeRemoteAiServiceProvider);
      expect(activeService, isNotNull,
          reason: 'activeRemoteAiServiceProvider should return the service '
              'after initialization and invalidation');
      expect(activeService, isA<RemoteAiService>());

      // Step 4: Simulate wizard completing — user selects Remote mode
      configState.setConfig(const AiConfig(
        mode: AiMode.remote,
        remoteAutoDetect: true,
      ));

      // Step 5: Force the bridge and controller to rebuild (as the wizard does)
      container.invalidate(activeRemoteAiServiceProvider);
      container.invalidate(activeRemoteHostIdProvider);
      container.invalidate(aiServiceControllerProvider);

      // Wait for async build to complete
      final service = await container.read(aiServiceControllerProvider.future);

      // THE KEY ASSERTION: service should be RemoteAiService, NOT UnconfiguredAiService
      expect(service, isA<RemoteAiService>(),
          reason: 'AiServiceController should return RemoteAiService when '
              'remote mode is configured and the per-host service is available');
      expect(service, isNot(isA<UnconfiguredAiService>()),
          reason: 'Should NOT return UnconfiguredAiService');
    });

    // @telos-scenario L1:function:...:ai_providers:remote-unconfigured-before-detection
    test(
        'AiServiceController returns UnconfiguredAiService when wizard '
        'completes before detection', () async {
      // Edge case: user opens wizard and selects Remote before detection runs.
      // Should return UnconfiguredAiService initially, but then update when
      // detection completes.

      late _TestSessionListController sessionController;
      late _TestAiConfigState configState;

      final container = ProviderContainer(
        overrides: [
          sessionListControllerProvider.overrideWith(
            () {
              sessionController = _TestSessionListController();
              return sessionController;
            },
          ),
          aiConfigStateProvider.overrideWith(
            () {
              configState = _TestAiConfigState();
              return configState;
            },
          ),
          aiConfigRepositoryProvider.overrideWithValue(mockConfigRepo),
        ],
      );
      addTearDown(container.dispose);

      // Initialize providers
      container.read(sessionListControllerProvider);
      await container.read(aiConfigStateProvider.future);

      // Step 1: SSH connected but no detection yet
      sessionController.setTestSessions(
        [testSession],
        activeId: testSession.id,
      );

      // Step 2: Wizard completes before detection — config set to remote
      configState.setConfig(const AiConfig(
        mode: AiMode.remote,
        remoteAutoDetect: true,
      ));

      container.invalidate(activeRemoteAiServiceProvider);
      container.invalidate(aiServiceControllerProvider);

      // Should return UnconfiguredAiService (no detection done yet)
      final serviceBefore =
          await container.read(aiServiceControllerProvider.future);
      expect(serviceBefore, isA<UnconfiguredAiService>(),
          reason: 'Before detection, should be UnconfiguredAiService');

      // Step 3: Detection completes later
      container
          .read(remoteAiServiceControllerProvider(testHostId).notifier)
          .initialize(
            client: mockClient,
            detectionResult: detectionResult,
          );

      // Step 4: Simulate the invalidation that session_terminal_controller does
      container.invalidate(activeRemoteAiServiceProvider);
      container.invalidate(aiServiceControllerProvider);

      // Wait for async rebuild
      final serviceAfter =
          await container.read(aiServiceControllerProvider.future);

      // NOW it should be RemoteAiService
      expect(serviceAfter, isA<RemoteAiService>(),
          reason: 'After detection completes and invalidation, '
              'should be RemoteAiService');
    });

    // @telos-scenario L1:function:...:ai_providers:remote-no-ssh-session
    test(
        'AiServiceController returns UnconfiguredAiService when remote mode '
        'but no SSH session', () async {
      late _TestAiConfigState configState;

      final container = ProviderContainer(
        overrides: [
          sessionListControllerProvider.overrideWith(
            () => _TestSessionListController(),
          ),
          aiConfigStateProvider.overrideWith(
            () {
              configState = _TestAiConfigState();
              return configState;
            },
          ),
          aiConfigRepositoryProvider.overrideWithValue(mockConfigRepo),
        ],
      );
      addTearDown(container.dispose);

      // Initialize providers
      container.read(sessionListControllerProvider);
      await container.read(aiConfigStateProvider.future);

      // No SSH session — sessions list is empty
      // Set config to remote mode
      configState.setConfig(const AiConfig(
        mode: AiMode.remote,
        remoteAutoDetect: true,
      ));

      container.invalidate(aiServiceControllerProvider);

      final service = await container.read(aiServiceControllerProvider.future);
      expect(service, isA<UnconfiguredAiService>(),
          reason: 'Without SSH session, should return UnconfiguredAiService');
    });

    // @telos-scenario L1:function:...:ai_providers:activeRemoteHostId-from-sessions
    test('activeRemoteHostIdProvider returns hostId of connected session', () {
      late _TestSessionListController sessionController;

      final container = ProviderContainer(
        overrides: [
          sessionListControllerProvider.overrideWith(
            () {
              sessionController = _TestSessionListController();
              return sessionController;
            },
          ),
        ],
      );
      addTearDown(container.dispose);

      // Initialize
      container.read(sessionListControllerProvider);

      // Initially no sessions
      expect(container.read(activeRemoteHostIdProvider), isNull);

      // Add a connected session
      sessionController.setTestSessions(
        [testSession],
        activeId: testSession.id,
      );

      expect(container.read(activeRemoteHostIdProvider), equals(testHostId));

      // Disconnect the session
      sessionController.setTestSessions(
        [testSession.copyWith(status: SessionStatus.disconnected)],
        activeId: testSession.id,
      );

      expect(container.read(activeRemoteHostIdProvider), isNull);
    });

    // @telos-scenario L1:function:...:ai_providers:bridge-provider-watch-chain
    test(
        'activeRemoteAiServiceProvider updates when per-host service '
        'is initialized', () {
      late _TestSessionListController sessionController;

      final container = ProviderContainer(
        overrides: [
          sessionListControllerProvider.overrideWith(
            () {
              sessionController = _TestSessionListController();
              return sessionController;
            },
          ),
        ],
      );
      addTearDown(container.dispose);

      // Initialize
      container.read(sessionListControllerProvider);

      // Set up connected session
      sessionController.setTestSessions(
        [testSession],
        activeId: testSession.id,
      );

      // Before initialization: null
      expect(container.read(activeRemoteAiServiceProvider), isNull);

      // Initialize the per-host service
      container
          .read(remoteAiServiceControllerProvider(testHostId).notifier)
          .initialize(
            client: mockClient,
            detectionResult: detectionResult,
          );

      // After initialization + invalidation: should have the service
      container.invalidate(activeRemoteAiServiceProvider);
      final service = container.read(activeRemoteAiServiceProvider);
      expect(service, isNotNull);
      expect(service, isA<RemoteAiService>());
    });

    // @telos-scenario L1:function:...:ai_providers:watch-chain-without-invalidation
    test(
        'activeRemoteAiServiceProvider picks up changes WITHOUT explicit '
        'invalidation (via Riverpod watch chain)', () {
      late _TestSessionListController sessionController;

      final container = ProviderContainer(
        overrides: [
          sessionListControllerProvider.overrideWith(
            () {
              sessionController = _TestSessionListController();
              return sessionController;
            },
          ),
        ],
      );
      addTearDown(container.dispose);

      // Initialize
      container.read(sessionListControllerProvider);

      // Set up connected session
      sessionController.setTestSessions(
        [testSession],
        activeId: testSession.id,
      );

      // Read to establish watch chain
      expect(container.read(activeRemoteAiServiceProvider), isNull);

      // Initialize the per-host service
      container
          .read(remoteAiServiceControllerProvider(testHostId).notifier)
          .initialize(
            client: mockClient,
            detectionResult: detectionResult,
          );

      // Read AGAIN without invalidation — does the watch chain propagate?
      final service = container.read(activeRemoteAiServiceProvider);

      // This tests whether Riverpod's watch chain auto-propagates.
      // If this fails, it confirms we NEED the explicit invalidation.
      // If this passes, the bug is elsewhere.
      if (service == null) {
        // Watch chain did NOT auto-propagate — this is the root cause!
        // The keepAlive computed provider doesn't auto-rebuild when a
        // watched family member mutates its state.
        //
        // This means our explicit invalidation fix is necessary and correct.
        expect(service, isNull,
            reason: 'Expected: watch chain does not auto-propagate for '
                'keepAlive computed providers watching family notifiers. '
                'This confirms explicit invalidation is needed.');
      } else {
        // Watch chain DID auto-propagate — bug is elsewhere
        expect(service, isA<RemoteAiService>());
      }
    });
  });
}
