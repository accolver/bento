// @telos L2:contract:component-command-ribbon

import 'dart:math' as math;

/// Canonical editable prompt state for a terminal session.
class PromptInputState {
  const PromptInputState({
    required this.text,
    required this.cursorOffset,
    required this.isAtPrompt,
    required this.isEditing,
    required this.isInTuiMode,
    required this.canShowRibbon,
  });

  const PromptInputState.initial()
      : text = '',
        cursorOffset = 0,
        isAtPrompt = false,
        isEditing = false,
        isInTuiMode = false,
        canShowRibbon = false;

  final String text;
  final int cursorOffset;
  final bool isAtPrompt;
  final bool isEditing;
  final bool isInTuiMode;
  final bool canShowRibbon;

  PromptInputState copyWith({
    String? text,
    int? cursorOffset,
    bool? isAtPrompt,
    bool? isEditing,
    bool? isInTuiMode,
    bool? canShowRibbon,
  }) {
    final nextText = text ?? this.text;
    final nextCursor = cursorOffset ?? this.cursorOffset;

    return PromptInputState(
      text: nextText,
      cursorOffset: math.max(0, math.min(nextCursor, nextText.length)),
      isAtPrompt: isAtPrompt ?? this.isAtPrompt,
      isEditing: isEditing ?? this.isEditing,
      isInTuiMode: isInTuiMode ?? this.isInTuiMode,
      canShowRibbon: canShowRibbon ?? this.canShowRibbon,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PromptInputState &&
        other.text == text &&
        other.cursorOffset == cursorOffset &&
        other.isAtPrompt == isAtPrompt &&
        other.isEditing == isEditing &&
        other.isInTuiMode == isInTuiMode &&
        other.canShowRibbon == canShowRibbon;
  }

  @override
  int get hashCode => Object.hash(
        text,
        cursorOffset,
        isAtPrompt,
        isEditing,
        isInTuiMode,
        canShowRibbon,
      );

  @override
  String toString() {
    return 'PromptInputState(text: $text, cursorOffset: $cursorOffset, '
        'isAtPrompt: $isAtPrompt, isEditing: $isEditing, '
        'isInTuiMode: $isInTuiMode, canShowRibbon: $canShowRibbon)';
  }
}
