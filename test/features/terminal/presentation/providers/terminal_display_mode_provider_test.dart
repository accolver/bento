// @telos-test L1:function:lib/features/terminal/presentation/providers:terminal_display_mode_provider

import 'package:bento/features/terminal/domain/entities/terminal_mode.dart';
import 'package:bento/features/terminal/domain/entities/tui_mode_state.dart';
import 'package:bento/features/terminal/presentation/providers/terminal_display_mode_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TerminalDisplayModeState', () {
    // @telos-scenario L1:...:terminal_display_mode_provider:initial-state-blocks
    test('initial state with semantic blocks enabled uses blocks mode', () {
      final state =
          TerminalDisplayModeState.initial(enableSemanticBlocks: true);

      expect(state.currentMode, equals(TerminalMode.blocks));
      expect(state.previousMode, equals(TerminalMode.blocks));
      expect(state.isInTuiMode, isFalse);
      expect(state.isInBlocksMode, isTrue);
      expect(state.tuiState.isActive, isFalse);
    });

    // @telos-scenario L1:...:terminal_display_mode_provider:initial-state-classic
    test('initial state with semantic blocks disabled uses classic mode', () {
      final state =
          TerminalDisplayModeState.initial(enableSemanticBlocks: false);

      expect(state.currentMode, equals(TerminalMode.classic));
      expect(state.previousMode, equals(TerminalMode.classic));
      expect(state.isInClassicMode, isTrue);
    });

    // @telos-scenario L1:...:terminal_display_mode_provider:copy-with
    test('copyWith creates modified copy preserving other values', () {
      final original =
          TerminalDisplayModeState.initial(enableSemanticBlocks: true);

      final modified = original.copyWith(
        currentMode: TerminalMode.tui,
        tuiState: TuiModeState.active(activatedAt: DateTime.now()),
      );

      expect(modified.currentMode, equals(TerminalMode.tui));
      expect(modified.previousMode, equals(TerminalMode.blocks)); // preserved
      expect(modified.tuiState.isActive, isTrue);
    });

    // @telos-scenario L1:...:terminal_display_mode_provider:mode-checks
    test('mode checking properties work correctly', () {
      final tuiState = TerminalDisplayModeState(
        currentMode: TerminalMode.tui,
        previousMode: TerminalMode.blocks,
        tuiState: const TuiModeState.inactive(),
      );

      expect(tuiState.isInTuiMode, isTrue);
      expect(tuiState.isInBlocksMode, isFalse);
      expect(tuiState.isInClassicMode, isFalse);
    });
  });

  group('TerminalDisplayModeState transitions', () {
    // @telos-scenario L1:...:terminal_display_mode_provider:enter-tui-from-blocks
    test('transitioning to TUI mode preserves previous mode', () {
      var state = TerminalDisplayModeState.initial(enableSemanticBlocks: true);

      // Simulate enterTuiMode
      state = state.copyWith(
        previousMode: state.currentMode,
        currentMode: TerminalMode.tui,
        tuiState: TuiModeState.active(
          activatedAt: DateTime.now(),
          triggeringCommand: 'vim',
        ),
      );

      expect(state.currentMode, equals(TerminalMode.tui));
      expect(state.previousMode, equals(TerminalMode.blocks));
      expect(state.tuiState.triggeringCommand, equals('vim'));
    });

    // @telos-scenario L1:...:terminal_display_mode_provider:exit-tui-to-blocks
    test('exiting TUI mode returns to previous mode', () {
      // Start in TUI mode (came from blocks)
      var state = TerminalDisplayModeState(
        currentMode: TerminalMode.tui,
        previousMode: TerminalMode.blocks,
        tuiState: TuiModeState.active(activatedAt: DateTime.now()),
      );

      // Simulate exitTuiMode
      state = state.copyWith(
        currentMode: state.previousMode,
        tuiState: const TuiModeState.inactive(),
      );

      expect(state.currentMode, equals(TerminalMode.blocks));
      expect(state.isInBlocksMode, isTrue);
      expect(state.tuiState.isActive, isFalse);
    });

    // @telos-scenario L1:...:terminal_display_mode_provider:enter-tui-from-classic
    test('transitioning to TUI mode from classic preserves classic', () {
      var state = TerminalDisplayModeState.initial(enableSemanticBlocks: false);

      // Simulate enterTuiMode
      state = state.copyWith(
        previousMode: state.currentMode,
        currentMode: TerminalMode.tui,
        tuiState: TuiModeState.active(activatedAt: DateTime.now()),
      );

      expect(state.currentMode, equals(TerminalMode.tui));
      expect(state.previousMode, equals(TerminalMode.classic));
    });

    // @telos-scenario L1:...:terminal_display_mode_provider:exit-tui-to-classic
    test('exiting TUI mode returns to classic when that was previous', () {
      var state = TerminalDisplayModeState(
        currentMode: TerminalMode.tui,
        previousMode: TerminalMode.classic,
        tuiState: TuiModeState.active(activatedAt: DateTime.now()),
      );

      // Simulate exitTuiMode
      state = state.copyWith(
        currentMode: state.previousMode,
        tuiState: const TuiModeState.inactive(),
      );

      expect(state.currentMode, equals(TerminalMode.classic));
      expect(state.isInClassicMode, isTrue);
    });

    // @telos-scenario L1:...:terminal_display_mode_provider:toggle-blocks-classic
    test('toggling semantic blocks switches between blocks and classic', () {
      var state = TerminalDisplayModeState.initial(enableSemanticBlocks: true);
      expect(state.currentMode, equals(TerminalMode.blocks));

      // Toggle to classic
      final newMode = state.currentMode == TerminalMode.blocks
          ? TerminalMode.classic
          : TerminalMode.blocks;
      state = state.copyWith(
        currentMode: newMode,
        previousMode: newMode,
      );

      expect(state.currentMode, equals(TerminalMode.classic));

      // Toggle back to blocks
      final newerMode = state.currentMode == TerminalMode.blocks
          ? TerminalMode.classic
          : TerminalMode.blocks;
      state = state.copyWith(
        currentMode: newerMode,
        previousMode: newerMode,
      );

      expect(state.currentMode, equals(TerminalMode.blocks));
    });
  });

  group('TuiModeState in TerminalDisplayModeState', () {
    // @telos-scenario L1:...:terminal_display_mode_provider:tui-state-with-command
    test('TUI state captures triggering command', () {
      final state = TerminalDisplayModeState(
        currentMode: TerminalMode.tui,
        previousMode: TerminalMode.blocks,
        tuiState: TuiModeState.active(
          activatedAt: DateTime.now(),
          triggeringCommand: 'htop',
          tuiBlockId: 'block-123',
        ),
      );

      expect(state.tuiState.triggeringCommand, equals('htop'));
      expect(state.tuiState.tuiBlockId, equals('block-123'));
    });

    // @telos-scenario L1:...:terminal_display_mode_provider:update-tui-block-id
    test('TUI state can be updated with block ID', () {
      var state = TerminalDisplayModeState(
        currentMode: TerminalMode.tui,
        previousMode: TerminalMode.blocks,
        tuiState: TuiModeState.active(
          activatedAt: DateTime.now(),
          triggeringCommand: 'vim',
        ),
      );

      // Update with block ID
      state = state.copyWith(
        tuiState: state.tuiState.copyWith(tuiBlockId: 'new-block-id'),
      );

      expect(state.tuiState.tuiBlockId, equals('new-block-id'));
      expect(state.tuiState.triggeringCommand, equals('vim')); // preserved
    });
  });
}
