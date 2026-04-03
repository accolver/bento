// @telos L1:function:lib/features/terminal/presentation/providers:prompt_input_controller

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/prompt_input_state.dart';

final promptInputControllerProvider = StateNotifierProvider.family<
    PromptInputController, PromptInputState, String>(
  (ref, sessionId) => PromptInputController(sessionId),
);

/// Session-scoped controller for Bento's best-known editable prompt state.
class PromptInputController extends StateNotifier<PromptInputState> {
  // @telos L1:function:lib/features/terminal/presentation/providers:prompt_input_controller
  PromptInputController(this.sessionId) : super(const PromptInputState.initial());

  final String sessionId;

  // @telos L1:function:lib/features/terminal/presentation/providers:prompt_input_controller
  void onPromptDetected() {
    if (state.isInTuiMode) {
      return;
    }

    state = state.copyWith(
      isAtPrompt: true,
      isEditing: true,
      canShowRibbon: true,
      text: '',
      cursorOffset: 0,
    );
  }

  // @telos L1:function:lib/features/terminal/presentation/providers:prompt_input_controller
  void onCommandStarted() {
    state = state.copyWith(
      isAtPrompt: false,
      isEditing: false,
      canShowRibbon: false,
      text: '',
      cursorOffset: 0,
    );
  }

  // @telos L1:function:lib/features/terminal/presentation/providers:prompt_input_controller
  void onTuiModeEntered() {
    state = state.copyWith(
      isInTuiMode: true,
      isAtPrompt: false,
      isEditing: false,
      canShowRibbon: false,
    );
  }

  // @telos L1:function:lib/features/terminal/presentation/providers:prompt_input_controller
  void onTuiModeExited() {
    state = state.copyWith(
      isInTuiMode: false,
      isAtPrompt: false,
      isEditing: false,
      canShowRibbon: false,
      text: '',
      cursorOffset: 0,
    );
  }

  // @telos L1:function:lib/features/terminal/presentation/providers:prompt_input_controller
  void insertText(String text) {
    final cursor = _clampOffset(state.cursorOffset, state.text.length);
    final next = state.text.replaceRange(cursor, cursor, text);

    state = state.copyWith(
      text: next,
      cursorOffset: cursor + text.length,
      isEditing: true,
    );
  }

  // @telos L1:function:lib/features/terminal/presentation/providers:prompt_input_controller
  void replaceRange(TextRange range, String replacement) {
    final safeRange = _clampRange(range, state.text.length);
    final next = state.text.replaceRange(
      safeRange.start,
      safeRange.end,
      replacement,
    );

    state = state.copyWith(
      text: next,
      cursorOffset: safeRange.start + replacement.length,
      isEditing: true,
    );
  }

  // @telos L1:function:lib/features/terminal/presentation/providers:prompt_input_controller
  void moveCursor(int newOffset) {
    state = state.copyWith(
      cursorOffset: _clampOffset(newOffset, state.text.length),
    );
  }

  // @telos L1:function:lib/features/terminal/presentation/providers:prompt_input_controller
  void deleteBackward() {
    final cursor = _clampOffset(state.cursorOffset, state.text.length);
    if (cursor == 0 || state.text.isEmpty) {
      state = state.copyWith(cursorOffset: 0);
      return;
    }

    final next = state.text.replaceRange(cursor - 1, cursor, '');
    state = state.copyWith(
      text: next,
      cursorOffset: cursor - 1,
      isEditing: true,
    );
  }

  // @telos L1:function:lib/features/terminal/presentation/providers:prompt_input_controller
  void clear() {
    state = state.copyWith(text: '', cursorOffset: 0);
  }

  // @telos L1:function:lib/features/terminal/presentation/providers:prompt_input_controller
  void overwriteText(String text) {
    state = state.copyWith(
      text: text,
      cursorOffset: text.length,
      isEditing: true,
    );
  }

  // @telos L1:function:lib/features/terminal/presentation/providers:prompt_input_controller
  int _clampOffset(int offset, int length) {
    return math.max(0, math.min(offset, length));
  }

  // @telos L1:function:lib/features/terminal/presentation/providers:prompt_input_controller
  TextRange _clampRange(TextRange range, int length) {
    final start = _clampOffset(range.start, length);
    final end = _clampOffset(range.end, length);

    if (end < start) {
      return TextRange(start: end, end: start);
    }

    return TextRange(start: start, end: end);
  }
}
