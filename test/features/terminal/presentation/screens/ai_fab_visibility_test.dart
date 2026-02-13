// @telos-test L1:function:lib/features/terminal/presentation/screens:terminal_screen

import 'package:bento/features/terminal/domain/entities/terminal_mode.dart';
import 'package:bento/features/terminal/domain/entities/view_mode.dart';
import 'package:bento/features/terminal/presentation/screens/terminal_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for AI FAB visibility across all view/display mode
/// combinations.
///
/// Bug history:
///   - The FAB was incorrectly hidden when viewMode == ViewMode.fullTerminal,
///     meaning users couldn't access AI generation from the terminal view.
///     The FAB should be visible in ALL three user-selectable views (split,
///     fullTerminal, fullBlocks) and only hidden in TUI mode (automatic mode
///     for vim, htop, etc.).
void main() {
  group('shouldShowAiFab', () {
    // =========================================================================
    // Regression: FAB must be visible in ALL user-selectable view modes
    // =========================================================================

    // @telos-scenario L1:...:terminal_screen:ai-fab-visible-in-split
    test('shows FAB in split view with blocks mode', () {
      expect(
        shouldShowAiFab(TerminalMode.blocks, ViewMode.split),
        isTrue,
      );
    });

    // @telos-scenario L1:...:terminal_screen:ai-fab-visible-in-full-terminal
    test('shows FAB in fullTerminal view with blocks mode', () {
      // REGRESSION: This was previously returning false, hiding the FAB
      // when the user selected the terminal view.
      expect(
        shouldShowAiFab(TerminalMode.blocks, ViewMode.fullTerminal),
        isTrue,
      );
    });

    // @telos-scenario L1:...:terminal_screen:ai-fab-visible-in-full-blocks
    test('shows FAB in fullBlocks view with blocks mode', () {
      expect(
        shouldShowAiFab(TerminalMode.blocks, ViewMode.fullBlocks),
        isTrue,
      );
    });

    // @telos-scenario L1:...:terminal_screen:ai-fab-visible-classic-split
    test('shows FAB in split view with classic mode', () {
      expect(
        shouldShowAiFab(TerminalMode.classic, ViewMode.split),
        isTrue,
      );
    });

    // @telos-scenario L1:...:terminal_screen:ai-fab-visible-classic-full-terminal
    test('shows FAB in fullTerminal view with classic mode', () {
      expect(
        shouldShowAiFab(TerminalMode.classic, ViewMode.fullTerminal),
        isTrue,
      );
    });

    // @telos-scenario L1:...:terminal_screen:ai-fab-visible-classic-full-blocks
    test('shows FAB in fullBlocks view with classic mode', () {
      expect(
        shouldShowAiFab(TerminalMode.classic, ViewMode.fullBlocks),
        isTrue,
      );
    });

    // =========================================================================
    // FAB must be hidden in TUI mode (automatic, not user-selectable)
    // =========================================================================

    // @telos-scenario L1:...:terminal_screen:ai-fab-hidden-tui-split
    test('hides FAB in TUI mode regardless of view mode (split)', () {
      expect(
        shouldShowAiFab(TerminalMode.tui, ViewMode.split),
        isFalse,
      );
    });

    // @telos-scenario L1:...:terminal_screen:ai-fab-hidden-tui-full-terminal
    test('hides FAB in TUI mode regardless of view mode (fullTerminal)', () {
      expect(
        shouldShowAiFab(TerminalMode.tui, ViewMode.fullTerminal),
        isFalse,
      );
    });

    // @telos-scenario L1:...:terminal_screen:ai-fab-hidden-tui-full-blocks
    test('hides FAB in TUI mode regardless of view mode (fullBlocks)', () {
      expect(
        shouldShowAiFab(TerminalMode.tui, ViewMode.fullBlocks),
        isFalse,
      );
    });

    // =========================================================================
    // Exhaustive: verify every combination
    // =========================================================================

    test('FAB visible in all non-TUI mode combinations', () {
      for (final viewMode in ViewMode.values) {
        for (final displayMode in TerminalMode.values) {
          final expected = displayMode != TerminalMode.tui;
          expect(
            shouldShowAiFab(displayMode, viewMode),
            equals(expected),
            reason:
                'Expected shouldShowAiFab($displayMode, $viewMode) == $expected',
          );
        }
      }
    });
  });
}
