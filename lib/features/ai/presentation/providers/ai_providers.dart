// @telos L1:function:lib/features/ai/presentation/providers:ai_providers

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/services/mock_ai_service.dart';
import '../../domain/entities/ai_config.dart';
import '../../domain/entities/ai_privacy_mode.dart';
import '../../domain/entities/ai_suggestion.dart';
import '../../domain/services/ai_service.dart';
import '../../domain/services/ai_service_factory.dart';

part 'ai_providers.g.dart';

// =============================================================================
// Configuration Providers
// =============================================================================

/// Provider for the AI configuration.
///
/// Manages the user's AI preferences. In the future, this will persist
/// to storage. For now, defaults to unconfigured (mock service).
@riverpod
class AiConfigState extends _$AiConfigState {
  @override
  AiConfig build() => AiConfig.unconfigured();

  /// Update the AI configuration.
  void update(AiConfig config) => state = config;

  /// Reset to unconfigured state.
  void reset() => state = AiConfig.unconfigured();

  /// Set to local AI mode.
  void setLocal({required String modelId, required String modelPath}) {
    state = state.copyWith(
      mode: AiMode.local,
      localModelId: modelId,
      localModelPath: modelPath,
      configuredAt: DateTime.now(),
    );
  }

  /// Set to cloud AI mode.
  void setCloud(CloudAiProvider provider) {
    state = state.copyWith(
      mode: AiMode.cloud,
      cloudProvider: provider,
      configuredAt: DateTime.now(),
    );
  }

  /// Set to remote AI mode.
  void setRemote({String? modelName}) {
    state = state.copyWith(
      mode: AiMode.remote,
      remoteAutoDetect: true,
      remoteModelName: modelName,
      configuredAt: DateTime.now(),
    );
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
    final config = ref.watch(aiConfigStateProvider);
    final factory = ref.watch(aiServiceFactoryProvider);

    // Create the service based on config
    // Note: For now, we don't have SSH session or secure storage wired up,
    // so this will always fall back to mock service for non-unconfigured modes.
    final service = await factory.createService(config);

    // Dispose service when provider is disposed
    ref.onDispose(() {
      service.dispose();
    });

    return service;
  }
}

/// Convenience provider that returns the current AI service synchronously.
///
/// Falls back to MockAiService if the async service isn't ready yet.
/// This is useful for UI code that needs immediate access to a service.
@riverpod
AiService aiService(Ref ref) {
  final asyncService = ref.watch(aiServiceControllerProvider);
  return asyncService.valueOrNull ?? MockAiService();
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
@riverpod
class AiInput extends _$AiInput {
  @override
  String build() => '';

  void update(String value) => state = value;
  void clear() => state = '';
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

/// Provider for AI command suggestions.
///
/// Watches the input provider and generates suggestions when input changes.
/// Uses the current AI service for generation.
@riverpod
class AiSuggestionController extends _$AiSuggestionController {
  @override
  Future<AiSuggestion?> build() async {
    // Watch the input and regenerate when it changes
    final input = ref.watch(aiInputProvider);

    // Don't generate for empty or very short input
    if (input.trim().length < 3) {
      return null;
    }

    // Get the current AI service
    final service = ref.watch(aiServiceProvider);

    // Generate suggestion
    return service.generateCommand(input);
  }

  /// Manually trigger regeneration with current input.
  Future<void> regenerate() async {
    final input = ref.read(aiInputProvider);
    if (input.trim().length < 3) return;

    // Invalidate to trigger rebuild
    ref.invalidateSelf();
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
            break;
        }
      }
    } catch (e) {
      state = (isStreaming: false, tokens: '', suggestion: null);
    }
  }

  /// Stop any ongoing stream and reset state.
  void reset() {
    state = (isStreaming: false, tokens: '', suggestion: null);
  }
}
