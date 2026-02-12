// @telos L1:function:lib/features/ai/presentation/providers:ai_providers

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/ai_config_repository.dart';
import '../../data/services/local_ai_service.dart';
import '../../data/services/model_download_service.dart';
import '../../data/services/unconfigured_ai_service.dart';
import '../../domain/entities/ai_config.dart';
import '../../domain/entities/ai_privacy_mode.dart';
import '../../domain/entities/ai_suggestion.dart';
// local_ai_model imported indirectly through model_download_service
import '../../domain/services/ai_service.dart';
import '../../domain/services/ai_service_factory.dart';
import 'remote_ai_providers.dart';

part 'ai_providers.g.dart';

/// Debounce duration for AI suggestion generation.
///
/// This prevents rapid-fire API calls while the user is typing.
const _suggestionDebounceDuration = Duration(milliseconds: 500);

// =============================================================================
// Repository & Service Providers
// =============================================================================

/// Provider for the AI configuration repository.
@riverpod
AiConfigRepository aiConfigRepository(Ref ref) {
  return AiConfigRepository();
}

/// Provider for the model download service.
@riverpod
ModelDownloadService modelDownloadService(Ref ref) {
  return ModelDownloadService();
}

// =============================================================================
// Configuration Providers
// =============================================================================

/// Provider for the AI configuration.
///
/// Manages the user's AI preferences with persistence to storage.
/// Loads from repository on build, saves on updates.
///
/// This provider is kept alive to prevent re-loading config on every access.
/// The AI configuration is critical state that should persist for the app's lifetime.
@Riverpod(keepAlive: true)
class AiConfigState extends _$AiConfigState {
  AiConfigRepository get _repo => ref.read(aiConfigRepositoryProvider);

  @override
  Future<AiConfig> build() async {
    // Load persisted config on startup
    debugPrint('[AiConfigState] build() called, loading config...');
    final config = await _repo.loadConfig();
    debugPrint(
        '[AiConfigState] Loaded config: mode=${config.mode}, path=${config.localModelPath}');
    return config;
  }

  /// Save a new AI configuration.
  Future<void> saveConfig(AiConfig config) async {
    await _repo.saveConfig(config);
    state = AsyncData(config);
  }

  /// Reset to unconfigured state.
  Future<void> reset() async {
    await _repo.clearConfig();
    state = AsyncData(AiConfig.unconfigured());
  }

  /// Set to local AI mode.
  Future<void> setLocal({
    required String modelId,
    required String modelPath,
  }) async {
    final current = state.valueOrNull ?? AiConfig.unconfigured();
    final config = current.copyWith(
      mode: AiMode.local,
      localModelId: modelId,
      localModelPath: modelPath,
      configuredAt: DateTime.now(),
    );
    await saveConfig(config);
  }

  /// Set to cloud AI mode.
  Future<void> setCloud(CloudAiProvider provider) async {
    final current = state.valueOrNull ?? AiConfig.unconfigured();
    final config = current.copyWith(
      mode: AiMode.cloud,
      cloudProvider: provider,
      configuredAt: DateTime.now(),
    );
    await saveConfig(config);
  }

  /// Set to remote AI mode.
  Future<void> setRemote({
    String? modelName,
    bool remoteAutoDetect = true,
  }) async {
    final current = state.valueOrNull ?? AiConfig.unconfigured();
    final config = current.copyWith(
      mode: AiMode.remote,
      remoteAutoDetect: remoteAutoDetect,
      remoteModelName: modelName,
      configuredAt: DateTime.now(),
    );
    await saveConfig(config);
  }

  /// Save an API key for cloud AI.
  Future<void> saveApiKey(String apiKey) async {
    await _repo.saveApiKey(apiKey);
  }

  /// Get the stored API key.
  Future<String?> getApiKey() async {
    return _repo.getApiKey();
  }
}

// =============================================================================
// Service Providers
// =============================================================================

/// Provider for the AI service factory.
///
/// The factory creates AI service instances based on configuration.
@riverpod
AiServiceFactory aiServiceFactory(Ref ref) {
  return const AiServiceFactory();
}

/// Provider for the current AI service.
///
/// Creates an appropriate service based on the current configuration.
/// Automatically recreates the service when configuration changes.
///
/// The service is disposed when the provider is disposed or recreated.
/// This provider is kept alive to prevent disposal during async operations.
@Riverpod(keepAlive: true)
class AiServiceController extends _$AiServiceController {
  AiService? _currentService;

  @override
  Future<AiService> build() async {
    // Dispose previous service if exists (only non-remote services we own)
    if (_currentService != null && !_isRemoteService) {
      await _currentService!.dispose();
    }
    _currentService = null;
    _isRemoteService = false;

    final factory = ref.watch(aiServiceFactoryProvider);
    final configRepository = ref.watch(aiConfigRepositoryProvider);

    // IMPORTANT: Establish all ref.watch() subscriptions BEFORE any await.
    // In Riverpod, watches after an await may not properly trigger rebuilds.
    final remoteService = ref.watch(activeRemoteAiServiceProvider);

    // Wait for config to fully load (don't use valueOrNull which returns null while loading)
    final config = await ref.watch(aiConfigStateProvider.future);

    // For remote mode, use the per-host RemoteAiService if available.
    // This bridges the per-host remote AI system to the global service.
    if (config.mode == AiMode.remote) {
      if (remoteService != null) {
        _currentService = remoteService;
        _isRemoteService = true;
        debugPrint(
          '[AiServiceController] Using remote service: '
          '${remoteService.serviceName}',
        );
        return remoteService;
      }

      // Remote mode but no service available yet. Return UnconfiguredAiService
      // directly — don't fall through to the factory which would also return
      // UnconfiguredAiService but through a longer path. The watch on
      // activeRemoteAiServiceProvider (keepAlive) ensures this build() will
      // be re-triggered when the remote service becomes available.
      //
      // NOTE: We intentionally removed a ref.read(activeRemoteHostIdProvider)
      // fallback that was here before. Using ref.read() after an await is a
      // Riverpod anti-pattern — the provider may have been invalidated during
      // the await, making the read stale. The ref.watch() on
      // activeRemoteAiServiceProvider (established before the await) is the
      // correct mechanism and is sufficient with keepAlive: true.
      debugPrint(
        '[AiServiceController] Remote mode but no service available yet '
        '— will rebuild when activeRemoteAiServiceProvider changes',
      );
      final unconfigured = const UnconfiguredAiService();
      _currentService = unconfigured;
      return unconfigured;
    }

    // Create the service based on config (local, cloud, or fallback)
    final service = await factory.createService(
      config,
      configRepository: configRepository,
    );

    _currentService = service;

    // Register cleanup - this is safe now since provider is keepAlive
    ref.onDispose(() {
      if (!_isRemoteService) {
        _currentService?.dispose();
      }
      _currentService = null;
    });

    return service;
  }

  /// Whether the current service is a remote service (owned by RemoteAiServiceController).
  /// We don't dispose remote services here — they're managed per-host.
  bool _isRemoteService = false;
}

/// Convenience provider that returns the current AI service synchronously.
///
/// Falls back to UnconfiguredAiService if the async service isn't ready yet.
/// This is useful for UI code that needs immediate access to a service.
@riverpod
AiService aiService(Ref ref) {
  final asyncService = ref.watch(aiServiceControllerProvider);
  return asyncService.valueOrNull ?? const UnconfiguredAiService();
}

// =============================================================================
// UI State Providers
// =============================================================================

/// Provider for AI panel visibility state.
///
/// Controls whether the AI Ghostwriter bottom sheet is open.
@riverpod
class AiPanelVisible extends _$AiPanelVisible {
  @override
  bool build() => false;

  void open() => state = true;
  void close() => state = false;
  void toggle() => state = !state;
}

/// Provider for the natural language input text.
///
/// Stores the user's input in the AI Ghostwriter panel.
/// Automatically triggers debounced suggestion generation on updates.
@riverpod
class AiInput extends _$AiInput {
  @override
  String build() => '';

  /// Update the input value and trigger debounced suggestion generation.
  void update(String value) {
    state = value;
    // Trigger debounced generation
    ref.read(aiSuggestionControllerProvider.notifier).onInputChanged(value);
  }

  void clear() {
    state = '';
    // Clear suggestions too
    ref.read(aiSuggestionControllerProvider.notifier).onInputChanged('');
  }
}

/// Provider for the current AI privacy mode.
///
/// Reads from the current AI service, but if the service is unconfigured,
/// derives the mode from the saved config (so "Remote" still shows in the
/// badge even while the remote service is initializing).
@riverpod
AiPrivacyMode aiPrivacyMode(Ref ref) {
  final service = ref.watch(aiServiceProvider);

  // If the service reports a real mode, use it
  if (service is! UnconfiguredAiService) {
    return service.privacyMode;
  }

  // Service is unconfigured — check what mode the user actually selected
  final config = ref.watch(aiConfigStateProvider).valueOrNull;
  if (config != null) {
    return switch (config.mode) {
      AiMode.local => AiPrivacyMode.local,
      AiMode.cloud => AiPrivacyMode.cloud,
      AiMode.remote => AiPrivacyMode.remote,
      AiMode.unconfigured => AiPrivacyMode.local,
    };
  }

  return service.privacyMode;
}

// Keep the old provider for backwards compatibility during transition
@riverpod
class AiPrivacyModeState extends _$AiPrivacyModeState {
  @override
  AiPrivacyMode build() {
    // Read from the service instead of managing state directly
    return ref.watch(aiPrivacyModeProvider);
  }

  // These are no-ops now - mode is determined by service
  void setLocal() {}
  void setCloud() {}
}

// =============================================================================
// Suggestion Provider
// =============================================================================

/// Provider for AI command suggestions with debouncing.
///
/// Watches the input provider and generates suggestions when input changes.
/// Uses debouncing to prevent rapid-fire generation requests while typing.
/// Automatically cancels in-flight requests when a new request is made.
///
/// **Concurrency Safety**: Only one generation runs at a time. New requests
/// cancel any in-progress generation to prevent native crashes in llama.cpp.
@riverpod
class AiSuggestionController extends _$AiSuggestionController {
  Timer? _debounceTimer;
  String? _lastGeneratedInput;

  /// Tracks if a generation is currently in progress.
  bool _isGenerating = false;

  /// The input that is currently being generated (or was requested).
  String? _pendingInput;

  @override
  Future<AiSuggestion?> build() async {
    // Clean up timer when provider is disposed
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    // Watch the input
    final input = ref.watch(aiInputProvider);

    // Don't generate for empty or very short input
    if (input.trim().length < 3) {
      _lastGeneratedInput = null;
      return null;
    }

    // If input hasn't changed from last generation, return current state
    if (input == _lastGeneratedInput && state.hasValue) {
      return state.value;
    }

    // Return current value while debouncing
    // The actual generation will be triggered by _debouncedGenerate
    return state.valueOrNull;
  }

  /// Trigger debounced generation for the given input.
  ///
  /// Call this when input changes to start the debounce timer.
  void onInputChanged(String input) {
    // Cancel any pending timer
    _debounceTimer?.cancel();

    // Don't generate for empty or very short input
    if (input.trim().length < 3) {
      state = const AsyncData(null);
      _lastGeneratedInput = null;
      _pendingInput = null;
      return;
    }

    // Track what input we want to generate for
    _pendingInput = input;

    // Start debounce timer
    _debounceTimer = Timer(_suggestionDebounceDuration, () {
      _generate(input);
    });
  }

  /// Generate suggestion for the given input.
  ///
  /// Only one generation runs at a time. If called while another generation
  /// is in progress, it will stop the current one first.
  Future<void> _generate(String input) async {
    // Skip if input hasn't changed
    if (input == _lastGeneratedInput) return;

    // Get the current AI service
    final service = ref.read(aiServiceProvider);

    // If already generating, stop the current generation first
    if (_isGenerating) {
      if (service is LocalAiService) {
        await service.stopGeneration();
        // Wait a bit for native resources to clean up
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    // Mark as generating
    _isGenerating = true;

    // Mark as loading
    state = const AsyncLoading();

    try {
      _lastGeneratedInput = input;
      final suggestion = await service.generateCommand(input);

      // Only update if this is still the latest request and no new request pending
      if (_lastGeneratedInput == input && _pendingInput == input) {
        state = AsyncData(suggestion);
      }
    } catch (e) {
      // Only update error if this is still the latest request
      if (_lastGeneratedInput == input && _pendingInput == input) {
        state = AsyncError(e, StackTrace.current);
      }
    } finally {
      _isGenerating = false;

      // If there's a newer pending input, generate for it
      if (_pendingInput != null && _pendingInput != input) {
        final pending = _pendingInput!;
        // Small delay to let native resources settle
        await Future.delayed(const Duration(milliseconds: 50));
        _generate(pending);
      }
    }
  }

  /// Manually trigger regeneration with current input.
  Future<void> regenerate() async {
    final input = ref.read(aiInputProvider);
    if (input.trim().length < 3) return;

    // Cancel debounce and generate immediately
    _debounceTimer?.cancel();
    _lastGeneratedInput = null; // Force regeneration
    await _generate(input);
  }
}

/// Provider for streaming AI generation state.
///
/// Tracks whether streaming is in progress and the accumulated tokens.
@riverpod
class AiStreamState extends _$AiStreamState {
  @override
  ({bool isStreaming, String tokens, AiSuggestion? suggestion}) build() {
    return (isStreaming: false, tokens: '', suggestion: null);
  }

  /// Start streaming generation for the given input.
  Future<void> startStream(String input) async {
    final service = ref.read(aiServiceProvider);

    state = (isStreaming: true, tokens: '', suggestion: null);

    try {
      await for (final event in service.generateCommandStream(input)) {
        switch (event) {
          case AiStreamToken(:final token):
            state = (
              isStreaming: true,
              tokens: state.tokens + token,
              suggestion: null,
            );
          case AiStreamComplete(:final suggestion):
            state = (
              isStreaming: false,
              tokens: suggestion.command,
              suggestion: suggestion,
            );
          case AiStreamError():
            state = (isStreaming: false, tokens: '', suggestion: null);
          // Could expose error state if needed
        }
      }
    } on Exception {
      state = (isStreaming: false, tokens: '', suggestion: null);
    }
  }

  /// Stop any ongoing stream and reset state.
  void reset() {
    state = (isStreaming: false, tokens: '', suggestion: null);
  }
}
