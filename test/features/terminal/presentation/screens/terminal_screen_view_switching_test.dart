// @telos-test L1:function:lib/features/terminal/presentation/screens:terminal_screen_view_switching

import 'package:bento/features/terminal/domain/entities/terminal_mode.dart';
import 'package:bento/features/terminal/domain/entities/tui_mode_state.dart';
import 'package:bento/features/terminal/presentation/providers/terminal_display_mode_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for terminal screen view switching based on display mode.
///
/// These tests verify that the TerminalScreen correctly switches between
/// blocks mode, TUI mode, and classic mode based on the TerminalDisplayModeProvider
/// state. We test the provider logic rather than full widget rendering since
/// the terminal requires native platform setup.
void main() {
  group('Terminal Screen View Switching Logic', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          // Override with initial blocks mode
          terminalDisplayModeProvider.overrideWith(
            () => _TestTerminalDisplayMode(enableSemanticBlocks: true),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    // @telos-scenario L1:...:terminal_screen_view_switching:initial-blocks-mode
    test('starts in blocks mode when semantic blocks enabled', () {
      final mode = container.read(currentTerminalModeProvider);

      expect(mode, equals(TerminalMode.blocks));
    });

    // @telos-scenario L1:...:terminal_screen_view_switching:switch-to-tui-mode
    test('switches to TUI mode when TUI app activates', () {
      final notifier = container.read(terminalDisplayModeProvider.notifier);

      // Simulate TUI app starting (vim, htop, etc.)
      notifier.enterTuiMode(triggeringCommand: 'vim');

      final mode = container.read(currentTerminalModeProvider);
      expect(mode, equals(TerminalMode.tui));
    });

    // @telos-scenario L1:...:terminal_screen_view_switching:return-to-blocks-from-tui
    test('returns to blocks mode when TUI app exits', () {
      final notifier = container.read(terminalDisplayModeProvider.notifier);

      // Enter TUI mode
      notifier.enterTuiMode(triggeringCommand: 'htop');
      expect(container.read(currentTerminalModeProvider),
          equals(TerminalMode.tui));

      // Exit TUI mode
      notifier.exitTuiMode();

      final mode = container.read(currentTerminalModeProvider);
      expect(mode, equals(TerminalMode.blocks));
    });

    // @telos-scenario L1:...:terminal_screen_view_switching:instant-switch-no-delay
    test('mode switch is instant (no async delay)', () {
      final notifier = container.read(terminalDisplayModeProvider.notifier);

      // Initial mode
      expect(container.read(currentTerminalModeProvider),
          equals(TerminalMode.blocks));

      // Switch to TUI - should be immediate
      notifier.enterTuiMode(triggeringCommand: 'vim');
      expect(container.read(currentTerminalModeProvider),
          equals(TerminalMode.tui));

      // Switch back - should be immediate
      notifier.exitTuiMode();
      expect(container.read(currentTerminalModeProvider),
          equals(TerminalMode.blocks));
    });

    // @telos-scenario L1:...:terminal_screen_view_switching:preserve-mode-through-tui
    test('preserves original mode (blocks vs classic) through TUI session', () {
      final notifier = container.read(terminalDisplayModeProvider.notifier);

      // Start in blocks mode
      expect(container.read(currentTerminalModeProvider),
          equals(TerminalMode.blocks));

      // Enter TUI mode
      notifier.enterTuiMode(triggeringCommand: 'less');
      expect(container.read(currentTerminalModeProvider),
          equals(TerminalMode.tui));

      // Check previous mode is preserved
      final state = container.read(terminalDisplayModeProvider);
      expect(state.previousMode, equals(TerminalMode.blocks));

      // Exit TUI - should return to blocks (not classic)
      notifier.exitTuiMode();
      expect(container.read(currentTerminalModeProvider),
          equals(TerminalMode.blocks));
    });

    // @telos-scenario L1:...:terminal_screen_view_switching:tui-state-tracking
    test('TUI state tracks triggering command and activation time', () {
      final notifier = container.read(terminalDisplayModeProvider.notifier);
      final beforeActivation = DateTime.now();

      notifier.enterTuiMode(triggeringCommand: 'nano file.txt');

      final state = container.read(terminalDisplayModeProvider);
      expect(state.tuiState.isActive, isTrue);
      expect(state.tuiState.triggeringCommand, equals('nano file.txt'));
      expect(state.tuiState.activatedAt, isNotNull);
      expect(
        state.tuiState.activatedAt!.isAfter(
          beforeActivation.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });

    // @telos-scenario L1:...:terminal_screen_view_switching:no-double-enter-tui
    test('entering TUI mode when already in TUI is no-op', () {
      final notifier = container.read(terminalDisplayModeProvider.notifier);

      // Enter TUI mode
      notifier.enterTuiMode(triggeringCommand: 'vim');
      final firstState = container.read(terminalDisplayModeProvider);

      // Try to enter again with different command
      notifier.enterTuiMode(triggeringCommand: 'htop');
      final secondState = container.read(terminalDisplayModeProvider);

      // State should be unchanged (first command preserved)
      expect(secondState.tuiState.triggeringCommand, equals('vim'));
      expect(
        secondState.tuiState.activatedAt,
        equals(firstState.tuiState.activatedAt),
      );
    });

    // @telos-scenario L1:...:terminal_screen_view_switching:exit-non-tui-noop
    test('exiting TUI mode when not in TUI is no-op', () {
      final notifier = container.read(terminalDisplayModeProvider.notifier);

      // Should be in blocks mode initially
      expect(container.read(currentTerminalModeProvider),
          equals(TerminalMode.blocks));

      // Try to exit TUI (when not in TUI)
      notifier.exitTuiMode();

      // Should still be in blocks mode
      expect(container.read(currentTerminalModeProvider),
          equals(TerminalMode.blocks));
    });

    // @telos-scenario L1:...:terminal_screen_view_switching:force-exit-on-disconnect
    test('force exit TUI mode on disconnect', () {
      final notifier = container.read(terminalDisplayModeProvider.notifier);

      // Enter TUI mode
      notifier.enterTuiMode(triggeringCommand: 'vim');
      expect(container.read(currentTerminalModeProvider),
          equals(TerminalMode.tui));

      // Force exit (simulating disconnect)
      notifier.forceExitTuiMode();

      // Should return to previous mode
      expect(container.read(currentTerminalModeProvider),
          equals(TerminalMode.blocks));
      expect(container.read(terminalDisplayModeProvider).tuiState.isActive,
          isFalse);
    });
  });

  group('Terminal Screen View Switching - Classic Mode Origin', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          // Override with initial classic mode (semantic blocks disabled)
          terminalDisplayModeProvider.overrideWith(
            () => _TestTerminalDisplayMode(enableSemanticBlocks: false),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    // @telos-scenario L1:...:terminal_screen_view_switching:start-in-classic
    test('starts in classic mode when semantic blocks disabled', () {
      final mode = container.read(currentTerminalModeProvider);

      expect(mode, equals(TerminalMode.classic));
    });

    // @telos-scenario L1:...:terminal_screen_view_switching:classic-to-tui-and-back
    test('returns to classic mode after TUI session when started in classic',
        () {
      final notifier = container.read(terminalDisplayModeProvider.notifier);

      // Start in classic mode
      expect(container.read(currentTerminalModeProvider),
          equals(TerminalMode.classic));

      // Enter TUI mode
      notifier.enterTuiMode(triggeringCommand: 'man ls');

      // Should be in TUI
      expect(container.read(currentTerminalModeProvider),
          equals(TerminalMode.tui));
      expect(container.read(terminalDisplayModeProvider).previousMode,
          equals(TerminalMode.classic));

      // Exit TUI
      notifier.exitTuiMode();

      // Should return to classic (not blocks)
      expect(container.read(currentTerminalModeProvider),
          equals(TerminalMode.classic));
    });
  });

  group('Terminal Screen App Bar Visibility', () {
    // @telos-scenario L1:...:terminal_screen_view_switching:appbar-buttons-hidden-in-tui
    test('app bar toggle button should be hidden in TUI mode', () {
      // This tests the logic that determines app bar visibility
      // The actual widget hiding is tested via the isInTuiMode check

      final container = ProviderContainer(
        overrides: [
          terminalDisplayModeProvider.overrideWith(
            () => _TestTerminalDisplayMode(enableSemanticBlocks: true),
          ),
        ],
      );

      final notifier = container.read(terminalDisplayModeProvider.notifier);

      // In blocks mode - buttons should be visible
      expect(container.read(isInTuiModeProvider), isFalse);

      // In TUI mode - buttons should be hidden
      notifier.enterTuiMode(triggeringCommand: 'vim');
      expect(container.read(isInTuiModeProvider), isTrue);

      // Back to blocks - buttons visible again
      notifier.exitTuiMode();
      expect(container.read(isInTuiModeProvider), isFalse);

      container.dispose();
    });
  });
}

/// Test implementation of TerminalDisplayMode that allows setting initial config.
class _TestTerminalDisplayMode extends TerminalDisplayMode {
  _TestTerminalDisplayMode({required this.enableSemanticBlocks});

  final bool enableSemanticBlocks;

  @override
  TerminalDisplayModeState build() {
    return TerminalDisplayModeState.initial(
      enableSemanticBlocks: enableSemanticBlocks,
    );
  }
}
