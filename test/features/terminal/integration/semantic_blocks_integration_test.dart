// @telos-test L2:contract:lib/features/terminal:semantic_blocks_integration

import 'dart:async';

import 'package:bento/features/terminal/data/services/output_router.dart';
import 'package:bento/features/terminal/domain/entities/block_status.dart';
import 'package:bento/features/terminal/presentation/providers/block_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration tests for the Semantic Blocks feature.
///
/// These tests simulate the full flow from SSH output to block creation,
/// verifying that the OutputRouter and BlockListController work together
/// correctly.
void main() {
  group('Semantic Blocks Integration', () {
    late ProviderContainer container;
    late BlockListController blockController;
    late OutputRouter outputRouter;

    setUp(() {
      container = ProviderContainer();
      blockController = container.read(blockListControllerProvider.notifier);
      outputRouter = OutputRouter(
        blockController: blockController,
        bufferDuration: const Duration(milliseconds: 1), // Fast for tests
      );
    });

    tearDown(() {
      outputRouter.dispose();
      container.dispose();
    });

    // @telos-scenario L2:...:semantic_blocks:full-command-lifecycle
    test('full command lifecycle: prompt → command → output → completion',
        () async {
      // GIVEN: Empty state, no blocks
      expect(blockController.state.blocks, isEmpty);

      // WHEN: User types a command at the prompt (terminal echoes it)
      outputRouter.processOutput('user@host:~\$ ls -la\n');

      // THEN: A new block is created with "Running" status
      expect(blockController.state.blocks, hasLength(1));
      final block = blockController.state.blocks.first;
      expect(block.command, 'ls -la');
      expect(block.status, BlockStatus.running);
      expect(block.isCollapsed, false); // New blocks start expanded
      expect(block.startedAt, isNotNull);

      // WHEN: Command output arrives
      outputRouter.processOutput('total 8\n');
      outputRouter
          .processOutput('drwxr-xr-x  2 user user 4096 Jan 1 12:00 dir1\n');
      outputRouter
          .processOutput('-rw-r--r--  1 user user  100 Jan 1 12:00 file.txt\n');

      // Wait for buffer flush
      await Future.delayed(const Duration(milliseconds: 10));

      // THEN: Output is appended to the block
      expect(blockController.state.blocks.first.output, contains('total 8'));
      expect(blockController.state.blocks.first.output, contains('file.txt'));

      // WHEN: Command completes (new prompt appears)
      outputRouter.processOutput('user@host:~\$ \n');

      // THEN: Block is completed with success status
      expect(blockController.state.blocks.first.status, BlockStatus.success);
      expect(blockController.state.blocks.first.completedAt, isNotNull);
      expect(blockController.hasActiveBlock, false);
    });

    // @telos-scenario L2:...:semantic_blocks:multiple-commands-session
    test('multiple commands in a session create separate blocks', () async {
      // Command 1: ls
      outputRouter.processOutput('user@host:~\$ ls\n');
      expect(blockController.state.blocks, hasLength(1));
      expect(blockController.state.blocks[0].command, 'ls');

      outputRouter.processOutput('file1.txt\nfile2.txt\n');
      outputRouter.processOutput('user@host:~\$ \n'); // Complete

      // Command 2: pwd
      outputRouter.processOutput('user@host:~\$ pwd\n');
      expect(blockController.state.blocks, hasLength(2));
      expect(blockController.state.blocks[1].command, 'pwd');

      outputRouter.processOutput('/home/user\n');
      outputRouter.processOutput('user@host:~\$ \n'); // Complete

      // Command 3: echo hello
      outputRouter.processOutput('user@host:~\$ echo hello\n');
      expect(blockController.state.blocks, hasLength(3));
      expect(blockController.state.blocks[2].command, 'echo hello');

      outputRouter.processOutput('hello\n');
      outputRouter.processOutput('user@host:~\$ \n'); // Complete

      // Verify all blocks are completed
      expect(
          blockController.state.blocks
              .every((b) => b.status != BlockStatus.running),
          true);
    });

    // @telos-scenario L2:...:semantic_blocks:new-block-expanded-old-collapsed
    test('new blocks are expanded, older blocks are auto-collapsed', () async {
      // Command 1 - starts expanded
      outputRouter.processOutput('user@host:~\$ first\n');
      expect(blockController.state.blocks[0].isCollapsed, false); // Expanded

      outputRouter.processOutput('output1\n');
      outputRouter.processOutput('user@host:~\$ \n');

      // Command 2 - old collapsed, new expanded
      outputRouter.processOutput('user@host:~\$ second\n');
      expect(
          blockController.state.blocks[0].isCollapsed, true); // Auto-collapsed
      expect(blockController.state.blocks[1].isCollapsed,
          false); // New block expanded

      outputRouter.processOutput('output2\n');
      outputRouter.processOutput('user@host:~\$ \n');

      // Command 3 - old blocks collapsed, new expanded
      outputRouter.processOutput('user@host:~\$ third\n');
      expect(blockController.state.blocks[0].isCollapsed, true);
      expect(blockController.state.blocks[1].isCollapsed, true);
      expect(blockController.state.blocks[2].isCollapsed,
          false); // Newest expanded
    });

    // @telos-scenario L2:...:semantic_blocks:same-command-multiple-times
    test('same command run multiple times creates multiple blocks', () async {
      // Run ls three times
      for (var i = 0; i < 3; i++) {
        outputRouter.processOutput('user@host:~\$ ls\n');
        outputRouter.processOutput('file.txt\n');
        outputRouter.processOutput('user@host:~\$ \n');
      }

      // Should have 3 separate blocks, all with command "ls"
      expect(blockController.state.blocks, hasLength(3));
      expect(
          blockController.state.blocks.every((b) => b.command == 'ls'), true);

      // Each should have a unique ID
      final ids = blockController.state.blocks.map((b) => b.id).toSet();
      expect(ids.length, 3);

      // Each should have a different timestamp
      final timestamps =
          blockController.state.blocks.map((b) => b.startedAt).toSet();
      expect(timestamps.length, 3);
    });

    // @telos-scenario L2:...:semantic_blocks:failed-command
    test('failed command shows failed status with exit code', () async {
      outputRouter.processOutput('user@host:~\$ invalid_command\n');
      outputRouter.processOutput('bash: invalid_command: command not found\n');
      outputRouter.processOutput('exit code: 127\n');
      outputRouter.processOutput('user@host:~\$ \n');

      expect(blockController.state.blocks.first.status, BlockStatus.failed);
      expect(blockController.state.blocks.first.exitCode, 127);
    });

    // @telos-scenario L2:...:semantic_blocks:cancelled-command
    test('cancelled command (Ctrl+C) shows cancelled status', () async {
      outputRouter.processOutput('user@host:~\$ sleep 100\n');
      expect(blockController.state.blocks.first.status, BlockStatus.running);

      // User presses Ctrl+C
      outputRouter.processInput('\x03');

      expect(blockController.state.blocks.first.status, BlockStatus.cancelled);
    });

    // @telos-scenario L2:...:semantic_blocks:starship-prompt
    test('works with Starship-style prompts', () async {
      // Starship prompt with path and git info
      outputRouter.processOutput('~/dev/project  main ❯ git status\n');
      expect(blockController.state.blocks, hasLength(1));
      expect(blockController.state.blocks.first.command, 'git status');

      outputRouter.processOutput('On branch main\nnothing to commit\n');
      outputRouter.processOutput('~/dev/project  main ❯ \n');

      expect(blockController.state.blocks.first.status, BlockStatus.success);
    });

    // @telos-scenario L2:...:semantic_blocks:clear-blocks
    test('clearBlocks removes all blocks', () async {
      // Create some blocks
      outputRouter.processOutput('user@host:~\$ cmd1\n');
      outputRouter.processOutput('user@host:~\$ \n');
      outputRouter.processOutput('user@host:~\$ cmd2\n');
      outputRouter.processOutput('user@host:~\$ \n');

      expect(blockController.state.blocks, hasLength(2));

      // Clear all blocks
      await blockController.clearBlocks();

      expect(blockController.state.blocks, isEmpty);
    });

    // @telos-scenario L2:...:semantic_blocks:output-forwarding
    test('output is forwarded to terminal via callback', () async {
      final forwardedOutput = <String>[];
      outputRouter.onProcessedOutput = (data) => forwardedOutput.add(data);

      outputRouter.processOutput('user@host:~\$ ls\n');
      outputRouter.processOutput('file.txt\n');
      outputRouter.processOutput('user@host:~\$ \n');

      // All output should be forwarded
      expect(forwardedOutput, contains('user@host:~\$ ls\n'));
      expect(forwardedOutput, contains('file.txt\n'));
      expect(forwardedOutput, contains('user@host:~\$ \n'));
    });

    // @telos-scenario L2:...:semantic_blocks:ansi-codes-preserved
    test('ANSI codes are preserved in block output', () async {
      outputRouter.processOutput('user@host:~\$ ls --color\n');

      // Colored output
      final coloredOutput = '\x1b[34mdir1\x1b[0m  \x1b[32mfile.txt\x1b[0m\n';
      outputRouter.processOutput(coloredOutput);

      await Future.delayed(const Duration(milliseconds: 10));

      // ANSI codes should be preserved in the block output
      expect(blockController.state.blocks.first.output, contains('\x1b[34m'));
      expect(blockController.state.blocks.first.output, contains('\x1b[32m'));
    });

    // @telos-scenario L2:...:semantic_blocks:reset-allows-new-session
    test('reset allows starting a fresh session', () async {
      // Create a block
      outputRouter.processOutput('user@host:~\$ old_command\n');
      expect(blockController.state.blocks, hasLength(1));

      // Reset the router (simulating disconnect/reconnect)
      outputRouter.reset();

      // New command should work
      outputRouter.processOutput('user@host:~\$ new_command\n');
      expect(blockController.state.blocks, hasLength(2));
      expect(blockController.state.blocks.last.command, 'new_command');
    });

    // @telos-scenario L2:...:semantic_blocks:rapid-commands
    test('handles rapid sequential commands', () async {
      // Simulate very fast command execution
      for (var i = 0; i < 10; i++) {
        outputRouter.processOutput('user@host:~\$ echo $i\n');
        outputRouter.processOutput('$i\n');
        outputRouter.processOutput('user@host:~\$ \n');
      }

      // All 10 commands should create blocks
      expect(blockController.state.blocks, hasLength(10));
    });

    // @telos-scenario L2:...:semantic_blocks:long-running-command
    test('handles long-running command with streaming output', () async {
      outputRouter.processOutput('user@host:~\$ tail -f /var/log/syslog\n');

      // Simulate streaming output over time
      for (var i = 0; i < 5; i++) {
        outputRouter.processOutput('Log line $i\n');
        await Future.delayed(const Duration(milliseconds: 5));
      }

      // Block should still be running
      expect(blockController.state.blocks.first.status, BlockStatus.running);

      // User cancels
      outputRouter.processInput('\x03');

      expect(blockController.state.blocks.first.status, BlockStatus.cancelled);
    });

    group('backspace handling', () {
      // @telos-scenario L2:...:semantic_blocks:backspace-correction
      test('backspace allows user to correct typos before submitting',
          () async {
        // User sees prompt
        outputRouter.processOutput('user@host:~\$ \n');

        // User types "lss" (typo)
        outputRouter.processInput('l');
        outputRouter.processInput('s');
        outputRouter.processInput('s');

        // User backspaces to fix typo
        outputRouter.processInput('\x7f'); // DEL (127)

        // User presses Enter
        outputRouter.processInput('\r');

        // Block should have corrected command
        expect(blockController.state.blocks, hasLength(1));
        expect(blockController.state.blocks.first.command, 'ls');
      });

      // @telos-scenario L2:...:semantic_blocks:bs-character
      test('BS character (0x08) also works for backspace', () async {
        // User sees prompt
        outputRouter.processOutput('user@host:~\$ \n');

        // User types "catt" (typo)
        for (final char in 'catt'.split('')) {
          outputRouter.processInput(char);
        }

        // User backspaces using BS (0x08)
        outputRouter.processInput('\x08');

        // User types correct character
        outputRouter.processInput(' ');
        outputRouter.processInput('f');
        outputRouter.processInput('\r');

        // Block should have corrected command
        expect(blockController.state.blocks, hasLength(1));
        expect(blockController.state.blocks.first.command, 'cat f');
      });

      // @telos-scenario L2:...:semantic_blocks:backspace-entire-command
      test('user can backspace entire command and retype', () async {
        // User sees prompt
        outputRouter.processOutput('user@host:~\$ \n');

        // User types "wrong"
        for (final char in 'wrong'.split('')) {
          outputRouter.processInput(char);
        }

        // User backspaces everything
        for (var i = 0; i < 5; i++) {
          outputRouter.processInput('\x7f');
        }

        // User types correct command
        for (final char in 'correct'.split('')) {
          outputRouter.processInput(char);
        }
        outputRouter.processInput('\r');

        // Block should have new command
        expect(blockController.state.blocks, hasLength(1));
        expect(blockController.state.blocks.first.command, 'correct');
      });

      // @telos-scenario L2:...:semantic_blocks:backspace-safe-empty
      test('backspace on empty buffer does not crash', () async {
        // User sees prompt
        outputRouter.processOutput('user@host:~\$ \n');

        // User presses backspace multiple times before typing
        outputRouter.processInput('\x7f');
        outputRouter.processInput('\x7f');
        outputRouter.processInput('\x08');

        // User then types command
        outputRouter.processInput('l');
        outputRouter.processInput('s');
        outputRouter.processInput('\r');

        // Should work normally
        expect(blockController.state.blocks, hasLength(1));
        expect(blockController.state.blocks.first.command, 'ls');
      });
    });
  });
}
