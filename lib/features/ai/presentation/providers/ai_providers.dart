// @telos L1:function:lib/features/ai/presentation/providers:ai_providers

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/services/mock_ai_service.dart';
import '../../domain/entities/ai_privacy_mode.dart';
import '../../domain/entities/ai_suggestion.dart';

part 'ai_providers.g.dart';

/// Provider for the AI service.
///
/// Currently provides the mock service. Will be replaced with real AI gateway.
@riverpod
MockAiService aiService(Ref ref) {
  return MockAiService();
}

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
/// Indicates whether AI processing is local or cloud-based.
@riverpod
class AiPrivacyModeState extends _$AiPrivacyModeState {
  @override
  AiPrivacyMode build() => AiPrivacyMode.local;

  void setLocal() => state = AiPrivacyMode.local;
  void setCloud() => state = AiPrivacyMode.cloud;
}

/// Provider for AI command suggestions.
///
/// Watches the input provider and generates suggestions when input changes.
/// Uses debouncing to avoid excessive API calls.
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

    // Generate suggestion
    final service = ref.read(aiServiceProvider);
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
