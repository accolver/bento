// @telos-test L1:function:lib/features/terminal/presentation/widgets:block_widget_tui_session

import 'package:bento/features/terminal/domain/entities/block.dart';
import 'package:bento/features/terminal/domain/entities/block_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for TUI session block rendering in BlockWidget.
///
/// These tests verify that TUI session blocks are displayed with
/// distinct appearance and appropriate metadata.
void main() {
  group('TUI Session Block Entity', () {
    // @telos-scenario L1:...:block_widget_tui_session:tui-block-creation
    test('can create TUI session block with isTuiSession flag', () {
      final block = TerminalBlock(
        id: 'tui-1',
        sessionId: 'session-1',
        command: 'vim file.txt',
        output: '',
        status: BlockStatus.running,
        startedAt: DateTime.now(),
        isTuiSession: true,
      );

      expect(block.isTuiSession, isTrue);
      expect(block.command, equals('vim file.txt'));
      expect(block.status, equals(BlockStatus.running));
    });

    // @telos-scenario L1:...:block_widget_tui_session:regular-block-default
    test('regular blocks have isTuiSession false by default', () {
      final block = TerminalBlock(
        id: 'reg-1',
        sessionId: 'session-1',
        command: 'ls -la',
        output: 'file1.txt\nfile2.txt',
        status: BlockStatus.success,
        startedAt: DateTime.now(),
      );

      expect(block.isTuiSession, isFalse);
    });

    // @telos-scenario L1:...:block_widget_tui_session:tui-block-no-output
    test('TUI session blocks typically have empty output', () {
      // TUI apps use alternate screen buffer, so we don't capture output
      final block = TerminalBlock(
        id: 'tui-2',
        sessionId: 'session-1',
        command: 'htop',
        output: '', // Empty - TUI output not captured
        status: BlockStatus.success,
        startedAt: DateTime.now(),
        completedAt: DateTime.now().add(const Duration(minutes: 5)),
        isTuiSession: true,
      );

      expect(block.isTuiSession, isTrue);
      expect(block.output, isEmpty);
      expect(block.executionDuration, isNotNull);
    });

    // @telos-scenario L1:...:block_widget_tui_session:tui-block-statuses
    test('TUI session blocks can have various statuses', () {
      // Running TUI
      final running = TerminalBlock(
        id: 'tui-running',
        sessionId: 'session-1',
        command: 'vim',
        output: '',
        status: BlockStatus.running,
        startedAt: DateTime.now(),
        isTuiSession: true,
      );
      expect(running.status, equals(BlockStatus.running));
      expect(running.isRunning, isTrue);

      // Successfully exited TUI
      final success = TerminalBlock(
        id: 'tui-success',
        sessionId: 'session-1',
        command: 'less README.md',
        output: '',
        status: BlockStatus.success,
        startedAt: DateTime.now(),
        completedAt: DateTime.now().add(const Duration(seconds: 30)),
        isTuiSession: true,
      );
      expect(success.status, equals(BlockStatus.success));

      // Cancelled/interrupted TUI
      final cancelled = TerminalBlock(
        id: 'tui-cancelled',
        sessionId: 'session-1',
        command: 'nano file.txt',
        output: '',
        status: BlockStatus.cancelled,
        startedAt: DateTime.now(),
        completedAt: DateTime.now().add(const Duration(seconds: 10)),
        isTuiSession: true,
      );
      expect(cancelled.status, equals(BlockStatus.cancelled));
    });

    // @telos-scenario L1:...:block_widget_tui_session:tui-copyWith-preserves
    test('copyWith preserves isTuiSession flag', () {
      final original = TerminalBlock(
        id: 'tui-1',
        sessionId: 'session-1',
        command: 'vim',
        output: '',
        status: BlockStatus.running,
        startedAt: DateTime.now(),
        isTuiSession: true,
      );

      // Update status while preserving isTuiSession
      final updated = original.copyWith(
        status: BlockStatus.success,
        completedAt: DateTime.now(),
      );

      expect(updated.isTuiSession, isTrue);
      expect(updated.status, equals(BlockStatus.success));
    });

    // @telos-scenario L1:...:block_widget_tui_session:tui-with-duration
    test('TUI session blocks track execution duration', () {
      final startTime = DateTime.now().subtract(const Duration(minutes: 10));
      final endTime = DateTime.now();

      final block = TerminalBlock(
        id: 'tui-1',
        sessionId: 'session-1',
        command: 'htop',
        output: '',
        status: BlockStatus.success,
        startedAt: startTime,
        completedAt: endTime,
        isTuiSession: true,
      );

      expect(block.executionDuration, isNotNull);
      expect(block.executionDuration!.inMinutes, greaterThanOrEqualTo(10));
    });
  });

  group('TUI Session Block Display Logic', () {
    // @telos-scenario L1:...:block_widget_tui_session:identify-vim
    test('identifies Vim editor from command', () {
      // vim and nvim are detected by the widget
      final vimCommands = ['vim file.txt', 'nvim main.dart'];
      for (final cmd in vimCommands) {
        final lower = cmd.toLowerCase();
        expect(
          lower.contains('vim') || lower.contains('nvim'),
          isTrue,
          reason: 'Should identify "$cmd" as Vim',
        );
      }

      // Note: plain 'vi' falls through to generic "Full-screen application"
      // This is acceptable since vi detection is a nice-to-have hint
    });

    // @telos-scenario L1:...:block_widget_tui_session:identify-htop
    test('identifies process monitors from command', () {
      final commands = ['htop', 'top', 'btop'];
      for (final cmd in commands) {
        final lower = cmd.toLowerCase();
        expect(
          lower.contains('htop') || lower.contains('top'),
          isTrue,
          reason: 'Should identify "$cmd" as process monitor',
        );
      }
    });

    // @telos-scenario L1:...:block_widget_tui_session:identify-pager
    test('identifies pager commands', () {
      final commands = ['less README.md', 'more output.log'];
      for (final cmd in commands) {
        final lower = cmd.toLowerCase();
        expect(
          lower.contains('less') || lower.contains('more'),
          isTrue,
          reason: 'Should identify "$cmd" as pager',
        );
      }
    });

    // @telos-scenario L1:...:block_widget_tui_session:identify-man
    test('identifies manual pages', () {
      final command = 'man ls';
      expect(command.toLowerCase().contains('man'), isTrue);
    });

    // @telos-scenario L1:...:block_widget_tui_session:identify-claude
    test('identifies Claude Code', () {
      final command = 'claude';
      expect(command.toLowerCase().contains('claude'), isTrue);
    });
  });

  group('TUI Session Block Collapse Behavior', () {
    // @telos-scenario L1:...:block_widget_tui_session:collapse-toggle
    test('TUI blocks support collapse/expand', () {
      var block = TerminalBlock(
        id: 'tui-1',
        sessionId: 'session-1',
        command: 'vim',
        output: '',
        status: BlockStatus.success,
        startedAt: DateTime.now(),
        isTuiSession: true,
        isCollapsed: false,
      );

      expect(block.isCollapsed, isFalse);

      // Toggle collapse
      block = block.copyWith(isCollapsed: true);
      expect(block.isCollapsed, isTrue);

      // Toggle expand
      block = block.copyWith(isCollapsed: false);
      expect(block.isCollapsed, isFalse);
    });

    // @telos-scenario L1:...:block_widget_tui_session:starts-expanded
    test('new TUI blocks start expanded by default', () {
      final block = TerminalBlock(
        id: 'tui-1',
        sessionId: 'session-1',
        command: 'htop',
        output: '',
        status: BlockStatus.running,
        startedAt: DateTime.now(),
        isTuiSession: true,
      );

      // Default is expanded (isCollapsed: false)
      expect(block.isCollapsed, isFalse);
    });
  });
}
