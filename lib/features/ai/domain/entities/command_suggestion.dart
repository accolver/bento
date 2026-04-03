// @telos L2:contract:service-ai-gateway

import 'ai_privacy_mode.dart';

/// Spec-aligned AI command suggestion used by domain usecases.
class CommandSuggestion {
  const CommandSuggestion({
    required this.command,
    required this.explanation,
    required this.confidence,
    required this.privacyMode,
    this.alternatives = const [],
  });

  final String command;
  final String explanation;
  final double confidence;
  final AiPrivacyMode privacyMode;
  final List<String> alternatives;

  @override
  bool operator ==(Object other) {
    return other is CommandSuggestion &&
        other.command == command &&
        other.explanation == explanation &&
        other.confidence == confidence &&
        other.privacyMode == privacyMode &&
        _listEquals(other.alternatives, alternatives);
  }

  @override
  int get hashCode => Object.hash(
        command,
        explanation,
        confidence,
        privacyMode,
        Object.hashAll(alternatives),
      );
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;

  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }

  return true;
}
