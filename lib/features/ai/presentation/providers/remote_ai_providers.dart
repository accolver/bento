// @telos L1:function:lib/features/ai/presentation/providers:remote_ai_providers

import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/claude_code_proxy_backend.dart';
import '../../data/services/cloud_proxy_backend.dart';
import '../../data/services/ollama_backend.dart';
import '../../data/services/remote_ai_detector.dart';
import '../../data/services/remote_ai_service.dart';
import '../../data/services/remote_backend.dart';
import '../../domain/entities/ollama_model.dart';
import '../../domain/entities/remote_ai_config.dart';
import '../../domain/entities/remote_ai_detection.dart';
import '../../domain/entities/remote_ai_provider.dart';

import '../../../session/domain/entities/session_status.dart';
import '../../../session/presentation/providers/session_list_controller.dart';

part 'remote_ai_providers.g.dart';

// =============================================================================
// Core Detection Infrastructure
// =============================================================================

/// Singleton detector instance, kept alive for the app's lifetime.
///
/// Manages detection, caching, and event streaming across all SSH sessions.
@Riverpod(keepAlive: true)
RemoteAiDetector remoteAiDetector(Ref ref) {
  final detector = RemoteAiDetector();
  ref.onDispose(() => detector.dispose());
  return detector;
}

/// Stream of detection events from all SSH connections.
///
/// UI widgets can watch this to show notifications when providers are
/// detected on newly connected hosts.
@riverpod
Stream<RemoteAiDetectionEvent> remoteAiDetectionEvents(Ref ref) {
  final detector = ref.watch(remoteAiDetectorProvider);
  return detector.detectionEvents;
}

// =============================================================================
// Per-Host Detection Results
// =============================================================================

/// Detection result for a specific host.
///
/// Triggers detection if not cached, returns cached result otherwise.
/// Use [remoteAiDetectionResultProvider(hostId)] to get results for a
/// specific SSH host.
@riverpod
class RemoteAiDetectionState extends _$RemoteAiDetectionState {
  @override
  Future<RemoteAiDetectionResult?> build(String hostId) async {
    final detector = ref.watch(remoteAiDetectorProvider);

    // Check cache first
    final cached = detector.getCachedResult(hostId);
    if (cached != null) return cached;

    // No cached result — return null (detection must be triggered explicitly)
    return null;
  }

  /// Trigger detection for this host with the given SSH client.
  Future<RemoteAiDetectionResult> detect(SSHClient client) async {
    final detector = ref.read(remoteAiDetectorProvider);
    state = const AsyncLoading();

    try {
      final result = await detector.detect(
        hostId: this.hostId,
        client: client,
      );
      state = AsyncData(result);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Clear cached result and reset state.
  void clear() {
    final detector = ref.read(remoteAiDetectorProvider);
    detector.clearCache(this.hostId);
    state = const AsyncData(null);
  }
}

/// Ollama models detected on a specific host.
///
/// Convenience provider that extracts the Ollama model list from the
/// detection result.
@riverpod
List<OllamaModel> ollamaModels(Ref ref, String hostId) {
  final result = ref.watch(remoteAiDetectionStateProvider(hostId));
  return result.valueOrNull?.ollamaModels ?? [];
}

/// Cloud providers detected on a specific host.
///
/// Convenience provider that extracts the cloud provider list from the
/// detection result.
@riverpod
List<DetectedCloudProvider> detectedCloudProviders(Ref ref, String hostId) {
  final result = ref.watch(remoteAiDetectionStateProvider(hostId));
  return result.valueOrNull?.cloudProviders ?? [];
}

// =============================================================================
// Per-Host Remote AI Configuration
// =============================================================================

/// Per-host remote AI configuration.
///
/// Stores the user's backend preference (Ollama vs cloud, which model/provider)
/// for each SSH host they connect to. Persisted via SharedPreferences.
@Riverpod(keepAlive: true)
class RemoteAiConfigState extends _$RemoteAiConfigState {
  static const _keyPrefix = 'bento_remote_ai_config_';

  @override
  RemoteAiConfig? build(String hostId) {
    // Load persisted config asynchronously, update state when ready
    _loadFromPrefs();
    return null;
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('$_keyPrefix$hostId');
      if (json != null) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        final config = _configFromJson(map);
        if (state == null) {
          state = config;
        }
      }
    } catch (e) {
      debugPrint('[RemoteAiConfigState] Failed to load config for $hostId: $e');
    }
  }

  /// Save a configuration for this host.
  Future<void> save(RemoteAiConfig config) async {
    state = config;
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_configToJson(config));
      await prefs.setString('$_keyPrefix$hostId', json);
      debugPrint('[RemoteAiConfigState] Saved config for $hostId');
    } catch (e) {
      debugPrint('[RemoteAiConfigState] Failed to save config for $hostId: $e');
    }
  }

  /// Clear saved configuration (revert to auto-select).
  Future<void> clear() async {
    state = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_keyPrefix$hostId');
    } catch (e) {
      debugPrint(
        '[RemoteAiConfigState] Failed to clear config for $hostId: $e',
      );
    }
  }

  Map<String, dynamic> _configToJson(RemoteAiConfig config) {
    return {
      'hostId': config.hostId,
      'backendType': config.backendType.name,
      'ollamaModel': config.ollamaModel,
      'cloudProvider': config.cloudProvider?.name,
      'envVarName': config.envVarName,
      'ollamaPort': config.ollamaPort,
    };
  }

  RemoteAiConfig _configFromJson(Map<String, dynamic> json) {
    return RemoteAiConfig(
      hostId: json['hostId'] as String? ?? hostId,
      backendType: RemoteBackendType.values.firstWhere(
        (b) => b.name == json['backendType'],
        orElse: () => RemoteBackendType.ollama,
      ),
      ollamaModel: json['ollamaModel'] as String?,
      cloudProvider: json['cloudProvider'] != null
          ? RemoteCloudProvider.values.firstWhere(
              (p) => p.name == json['cloudProvider'],
              orElse: () => RemoteCloudProvider.anthropic,
            )
          : null,
      envVarName: json['envVarName'] as String?,
      ollamaPort: json['ollamaPort'] as int? ?? 11434,
    );
  }
}

// =============================================================================
// Per-Host Remote AI Service
// =============================================================================

/// Remote AI service for a specific host.
///
/// Creates and manages a [RemoteAiService] instance based on the host's
/// detection results and user configuration. The service is ready to use
/// for generating commands, streaming, and summarizing output.
@Riverpod(keepAlive: true)
class RemoteAiServiceController extends _$RemoteAiServiceController {
  RemoteAiService? _service;

  @override
  RemoteAiService? build(String hostId) {
    ref.onDispose(() {
      _service?.dispose();
      _service = null;
    });
    return null;
  }

  /// Initialize the remote AI service with an SSH client and detection result.
  ///
  /// Call this after detection completes and the user has (optionally)
  /// selected a provider.
  RemoteAiService initialize({
    required SSHClient client,
    required RemoteAiDetectionResult detectionResult,
    RemoteAiConfig? config,
  }) {
    // Dispose any previous service
    _service?.dispose();

    // Determine backend from config or auto-select
    final backend = _createBackend(detectionResult, config);

    _service = RemoteAiService(
      client: client,
      backend: backend,
    );

    state = _service;
    debugPrint(
      '[RemoteAiServiceController] Initialized for $hostId '
      'with ${backend.displayName}',
    );
    return _service!;
  }

  /// Switch to a different backend.
  void switchBackend(RemoteBackend newBackend) {
    _service?.switchBackend(newBackend);
    // Trigger state update for listeners
    state = _service;
  }

  /// Handle SSH disconnection.
  void onDisconnected() {
    _service?.onDisconnected();
    state = _service;
  }

  /// Handle SSH reconnection.
  void onReconnected(SSHClient newClient) {
    _service?.onReconnected(newClient);
    state = _service;
  }

  /// Dispose the service.
  void teardown() {
    _service?.dispose();
    _service = null;
    state = null;
  }

  RemoteBackend _createBackend(
    RemoteAiDetectionResult result,
    RemoteAiConfig? config,
  ) {
    // If user has a saved config, use it
    if (config != null) {
      switch (config.backendType) {
        case RemoteBackendType.claudeCode:
          if (result.claudeCodeDetected) {
            return ClaudeCodeProxyBackend();
          }
        case RemoteBackendType.ollama:
          if (config.ollamaModel != null && result.hasOllama) {
            return OllamaBackend(
              selectedModel: config.ollamaModel!,
              availableModels: result.ollamaModels,
              port: config.ollamaPort,
            );
          }
        case RemoteBackendType.cloudProxy:
          if (config.cloudProvider != null && config.envVarName != null) {
            final providerConfig =
                RemoteProviderRegistry.forProvider(config.cloudProvider!);
            if (providerConfig != null) {
              return CloudProxyBackend(
                providerConfig: providerConfig,
                envVarName: config.envVarName!,
                detectionMethod: result.detectionMethod,
              );
            }
          }
      }
    }

    // Auto-select Claude Code as highest priority
    if (result.claudeCodeDetected) {
      debugPrint('[RemoteAiServiceController] Auto-selecting Claude Code');
      return ClaudeCodeProxyBackend();
    }

    // Auto-select: prefer cloud providers (ranked), then Ollama
    if (result.hasCloudProviders) {
      final best = result.bestCloudProvider!;
      final providerConfig = RemoteProviderRegistry.forProvider(best.provider);
      if (providerConfig != null) {
        return CloudProxyBackend(
          providerConfig: providerConfig,
          envVarName: best.envVarName,
          detectionMethod: result.detectionMethod,
        );
      }
    }

    if (result.hasOllama) {
      return OllamaBackend(
        selectedModel: result.ollamaModels.first.name,
        availableModels: result.ollamaModels,
      );
    }

    // Fallback — shouldn't reach here if detection found anything
    throw StateError('No AI providers available to create backend');
  }
}

// =============================================================================
// Active Remote AI Service (bridges per-host to global)
// =============================================================================

/// Derives the hostId of the first connected SSH session.
///
/// This is used to bridge the per-host [RemoteAiServiceController] to
/// the global [AiServiceController] — when the user has configured
/// remote mode and has an active SSH session, we use that host's
/// remote AI service as the global one.
///
/// Kept alive to prevent garbage collection between async rebuilds of
/// [AiServiceController]. Without keepAlive, this auto-dispose provider
/// could be GC'd after the controller's initial build, breaking the
/// watch chain that should trigger rebuilds when the remote service
/// becomes available.
@Riverpod(keepAlive: true)
String? activeRemoteHostId(Ref ref) {
  final sessionState = ref.watch(sessionListControllerProvider);
  final connectedSession = sessionState.sessions
      .where((s) => s.status == SessionStatus.connected)
      .firstOrNull;
  if (connectedSession == null) return null;
  return '${connectedSession.connectionConfig.host}:'
      '${connectedSession.connectionConfig.port}';
}

/// The active remote AI service (from the currently connected SSH host).
///
/// Returns null if no SSH session is connected or no remote service
/// has been initialized for the connected host.
///
/// Kept alive to prevent garbage collection between async rebuilds of
/// [AiServiceController]. Without keepAlive, this provider could be
/// GC'd after the controller's initial build returns UnconfiguredAiService,
/// breaking the watch chain that should trigger a rebuild when the
/// remote service is later initialized.
@Riverpod(keepAlive: true)
RemoteAiService? activeRemoteAiService(Ref ref) {
  final hostId = ref.watch(activeRemoteHostIdProvider);
  if (hostId == null) {
    debugPrint('[activeRemoteAiService] No active host ID — returning null');
    return null;
  }
  final service = ref.watch(remoteAiServiceControllerProvider(hostId));
  debugPrint(
    '[activeRemoteAiService] hostId=$hostId, '
    'service=${service != null ? service.serviceName : "null"}',
  );
  return service;
}
