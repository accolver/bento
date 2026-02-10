// @telos L1:function:lib/features/ai/presentation/providers:ai_providers

import 'dart:async';

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
    return _repo.loadConfig();
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
  Future<void> setRemote({String? modelName}) async {
    final current = state.valueOrNull ?? AiConfig.unconfigured();
    final config = current.copyWith(
      mode: AiMode.remote,
      remoteAutoDetect: true,
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
@riverpod
class AiServiceController extends _$AiServiceController {
  @override
  Future<AiService> build() async {
    final configAsync = ref.watch(aiConfigStateProvider);
    final factory = ref.watch(aiServiceFactoryProvider);

    // Wait for config to load, use unconfigured as fallback
    final config = configAsync.valueOrNull ?? AiConfig.unconfigured();

    // Create the service based on config
    // Note: For now, we don't have SSH session or secure storage wired up,
    // so this will always fall back to mock service for non-unconfigured modes.
    final service = await factory.createService(config);

    // Dispose service when provider is disposed
    ref.onDispose(service.dispose);

    return service;
  }
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
/// Reads from the current AI service. Updates automatically when
/// the service changes.
@riverpod
AiPrivacyMode aiPrivacyMode(Ref ref) {
  final service = ref.watch(aiServiceProvider);
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
