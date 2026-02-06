// @telos L1:function:lib/features/ai/domain/entities:ai_suggestion

import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_suggestion.freezed.dart';

/// Represents an AI-generated command suggestion.
///
/// Contains the suggested command, an explanation of what it does,
/// and a confidence score indicating how certain the AI is about
/// the suggestion.
@freezed
class AiSuggestion with _$AiSuggestion {
  const factory AiSuggestion({
    /// The suggested CLI command.
    required String command,

    /// A brief explanation of what the command does.
    required String explanation,

    /// Confidence score from 0.0 to 1.0.
    /// - >= 0.9: High confidence (green)
    /// - >= 0.7: Medium confidence (yellow)
    /// - < 0.7: Low confidence (orange)
    required double confidence,

    /// Alternative suggestions if available.
    @Default([]) List<String> alternatives,
  }) = _AiSuggestion;

  const AiSuggestion._();

  /// Returns the confidence as a percentage string.
  String get confidencePercent => '${(confidence * 100).round()}%';

  /// Returns true if this is a high confidence suggestion (>= 90%).
  bool get isHighConfidence => confidence >= 0.9;

  /// Returns true if this is a medium confidence suggestion (70-89%).
  bool get isMediumConfidence => confidence >= 0.7 && confidence < 0.9;

  /// Returns true if this is a low confidence suggestion (< 70%).
  bool get isLowConfidence => confidence < 0.7;
}
