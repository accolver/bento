// @telos-test L1:function:lib/features/terminal/domain/entities:terminal_mode

import 'package:bento/features/terminal/domain/entities/terminal_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TerminalMode', () {
    // @telos-scenario L1:...:terminal_mode:enum-values
    test('has three distinct values', () {
      expect(TerminalMode.values, hasLength(3));
      expect(TerminalMode.values, contains(TerminalMode.blocks));
      expect(TerminalMode.values, contains(TerminalMode.tui));
      expect(TerminalMode.values, contains(TerminalMode.classic));
    });
  });

  group('TerminalModeExtension', () {
    // @telos-scenario L1:...:terminal_mode:is-full-screen
    test('isFullScreen returns true for tui and classic modes', () {
      expect(TerminalMode.tui.isFullScreen, isTrue);
      expect(TerminalMode.classic.isFullScreen, isTrue);
      expect(TerminalMode.blocks.isFullScreen, isFalse);
    });

    // @telos-scenario L1:...:terminal_mode:uses-blocks
    test('usesBlocks returns true only for blocks mode', () {
      expect(TerminalMode.blocks.usesBlocks, isTrue);
      expect(TerminalMode.tui.usesBlocks, isFalse);
      expect(TerminalMode.classic.usesBlocks, isFalse);
    });

    // @telos-scenario L1:...:terminal_mode:is-tui
    test('isTui returns true only for tui mode', () {
      expect(TerminalMode.tui.isTui, isTrue);
      expect(TerminalMode.blocks.isTui, isFalse);
      expect(TerminalMode.classic.isTui, isFalse);
    });

    // @telos-scenario L1:...:terminal_mode:labels
    test('label returns human-readable string for each mode', () {
      expect(TerminalMode.blocks.label, equals('Semantic Blocks'));
      expect(TerminalMode.tui.label, equals('TUI Mode'));
      expect(TerminalMode.classic.label, equals('Classic Terminal'));
    });

    // @telos-scenario L1:...:terminal_mode:descriptions
    test('description returns meaningful description for each mode', () {
      expect(TerminalMode.blocks.description, contains('blocks'));
      expect(TerminalMode.tui.description, contains('Full-screen'));
      expect(TerminalMode.classic.description, contains('continuous'));
    });
  });
}
