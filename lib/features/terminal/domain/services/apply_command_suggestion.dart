// @telos L1:function:lib/features/terminal/domain/services:applyCommandSuggestion

import 'dart:math' as math;
import 'dart:ui';

import '../entities/command_suggestion_chip.dart';
import '../entities/prompt_input_state.dart';

// @telos L1:function:lib/features/terminal/domain/services:applyCommandSuggestion
PromptInputState applyCommandSuggestion({
  required PromptInputState current,
  required CommandSuggestionChip suggestion,
}) {
  final safeRange = _clampRange(suggestion.replacementRange, current.text.length);
  final replacement = _withTrailingSpaceIfNeeded(
    suggestion.insertText,
    suggestion.appendSpace,
    current.text,
    safeRange,
  );

  final nextText = current.text.replaceRange(
    safeRange.start,
    safeRange.end,
    replacement,
  );

  return current.copyWith(
    text: nextText,
    cursorOffset: safeRange.start + replacement.length,
  );
}

// @telos L1:function:lib/features/terminal/domain/services:applyCommandSuggestion
TextRange _clampRange(TextRange range, int length) {
  final start = math.max(0, math.min(range.start, length));
  final end = math.max(0, math.min(range.end, length));

  if (end < start) {
    return TextRange(start: end, end: start);
  }

  return TextRange(start: start, end: end);
}

// @telos L1:function:lib/features/terminal/domain/services:applyCommandSuggestion
String _withTrailingSpaceIfNeeded(
  String insertText,
  bool appendSpace,
  String currentText,
  TextRange replacementRange,
) {
  if (!appendSpace || insertText.endsWith(' ')) {
    return insertText;
  }

  if (replacementRange.end < currentText.length &&
      currentText[replacementRange.end] == ' ') {
    return insertText;
  }

  return '$insertText ';
}
