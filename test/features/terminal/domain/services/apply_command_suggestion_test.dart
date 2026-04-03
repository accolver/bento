// @telos-test L1:function:lib/features/terminal/domain/services:applyCommandSuggestion

import 'dart:ui';

import 'package:bento/features/terminal/domain/entities/command_suggestion_chip.dart';
import 'package:bento/features/terminal/domain/entities/prompt_input_state.dart';
import 'package:bento/features/terminal/domain/services/apply_command_suggestion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('applyCommandSuggestion', () {
    // @telos-scenario L1:function:lib/features/terminal/domain/services:applyCommandSuggestion:replace-partial-command-token
    test('replaces partial command token and appends trailing space when configured', () {
      final result = applyCommandSuggestion(
        current: _state('kub', 3),
        suggestion: const CommandSuggestionChip(
          id: 'kubectl',
          kind: CommandSuggestionKind.command,
          label: 'kubectl',
          insertText: 'kubectl',
          replacementRange: TextRange(start: 0, end: 3),
          appendSpace: true,
        ),
      );

      expect(result.text, 'kubectl ');
      expect(result.cursorOffset, 8);
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/services:applyCommandSuggestion:replace-subcommand-only
    test('replaces only subcommand token and preserves leading command', () {
      final result = applyCommandSuggestion(
        current: _state('docker co', 9),
        suggestion: const CommandSuggestionChip(
          id: 'compose',
          kind: CommandSuggestionKind.subcommand,
          label: 'compose',
          insertText: 'compose',
          replacementRange: TextRange(start: 7, end: 9),
          appendSpace: true,
        ),
      );

      expect(result.text, 'docker compose ');
      expect(result.cursorOffset, 15);
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/services:applyCommandSuggestion:insert-symbol-at-cursor-without-deleting-surrounding-text
    test('inserts symbol text at cursor and preserves full line', () {
      final result = applyCommandSuggestion(
        current: _state('cat file.txt', 12),
        suggestion: const CommandSuggestionChip(
          id: 'pipe',
          kind: CommandSuggestionKind.symbol,
          label: '|',
          insertText: ' | ',
          replacementRange: TextRange(start: 12, end: 12),
        ),
      );

      expect(result.text, 'cat file.txt | ');
      expect(result.cursorOffset, 15);
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/services:applyCommandSuggestion:preserve-trailing-text-after-cursor
    test('preserves trailing text outside replacement range', () {
      final result = applyCommandSuggestion(
        current: _state('git st main', 6),
        suggestion: const CommandSuggestionChip(
          id: 'status',
          kind: CommandSuggestionKind.subcommand,
          label: 'status',
          insertText: 'status',
          replacementRange: TextRange(start: 4, end: 6),
        ),
      );

      expect(result.text, 'git status main');
      expect(result.cursorOffset, 10);
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/services:applyCommandSuggestion:ignore-invalid-replacement-ranges-safely
    test('clamps out-of-bounds replacement range and does not throw', () {
      expect(
        () => applyCommandSuggestion(
          current: _state('git', 3),
          suggestion: const CommandSuggestionChip(
            id: 'git-status',
            kind: CommandSuggestionKind.history,
            label: 'git status',
            insertText: 'git status',
            replacementRange: TextRange(start: -1, end: 99),
          ),
        ),
        returnsNormally,
      );

      final result = applyCommandSuggestion(
        current: _state('git', 3),
        suggestion: const CommandSuggestionChip(
          id: 'git-status',
          kind: CommandSuggestionKind.history,
          label: 'git status',
          insertText: 'git status',
          replacementRange: TextRange(start: -1, end: 99),
        ),
      );

      expect(result.text, 'git status');
      expect(result.cursorOffset, 10);
    });
  });
}

PromptInputState _state(String text, int cursorOffset) {
  return PromptInputState(
    text: text,
    cursorOffset: cursorOffset,
    isAtPrompt: true,
    isEditing: true,
    isInTuiMode: false,
    canShowRibbon: true,
  );
}
