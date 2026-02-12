// @telos-test L2:contract:lib/features/terminal:tui_mode_integration

import 'dart:async';
import 'dart:typed_data';

import 'package:bento/features/terminal/data/services/output_router.dart';
import 'package:bento/features/terminal/data/services/tui_mode_detector.dart';
import 'package:bento/features/terminal/domain/entities/block_status.dart';
import 'package:bento/features/terminal/presentation/providers/block_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration tests for TUI (Terminal User Interface) mode.
///
/// These tests verify the full flow of TUI mode detection and block handling,
/// simulating real-world scenarios like launching vim, htop, or less.
void main() {
  group('TUI Mode Integration', () {
    late ProviderContainer container;
    late BlockListController blockController;
    late TuiModeDetector tuiDetector;
    late OutputRouter outputRouter;

    // Common escape sequences
    // smcup: Enter alternate screen buffer
    final smcup = '\x1b[?1049h';
    // rmcup: Exit alternate screen buffer
    final rmcup = '\x1b[?1049l';

    setUp(() {
      container = ProviderContainer();
      blockController =
          container.read(blockListControllerProvider('test-session').notifier);
      tuiDetector = TuiModeDetector(
        debounceDuration: const Duration(milliseconds: 10), // Fast for tests
      );
      outputRouter = OutputRouter(
        blockController: blockController,
        tuiModeDetector: tuiDetector,
        bufferDuration: const Duration(milliseconds: 1), // Fast for tests
      );

      // Wire up TUI mode callbacks (mimicking what OutputRouterProvider does)
      outputRouter.onTuiModeEnter = (triggeringCommand) {
        blockController.createTuiSessionBlock(triggeringCommand);
      };
      outputRouter.onTuiModeExit = () {
        blockController.completeTuiSessionBlock();
      };
    });

    tearDown(() {
      outputRouter.dispose();
      tuiDetector.dispose();
      container.dispose();
    });

    group('Task 11.1: vim lifecycle', () {
      // @telos-scenario L2:...:tui_mode:vim-full-lifecycle
      test(
          'launch vim, verify TUI mode activates, exit vim, verify return to blocks mode',
          () async {
        // Track TUI mode transitions
        final transitions = <String>[];

        // Wire up callbacks to track transitions AND create/complete blocks
        outputRouter.onTuiModeEnter = (cmd) {
          transitions.add('enter:$cmd');
          blockController.createTuiSessionBlock(cmd);
        };
        outputRouter.onTuiModeExit = () {
          transitions.add('exit');
          blockController.completeTuiSessionBlock();
        };

        // GIVEN: User is at a shell prompt with some command history
        outputRouter.processOutput('user@host:~\$ echo setup\n');
        outputRouter.processOutput('setup\n');
        outputRouter.processOutput('user@host:~\$ \n');

        expect(blockController.state.blocks, hasLength(1));
        expect(blockController.state.blocks.first.status, BlockStatus.success);
        expect(outputRouter.isInTuiMode, false);

        // WHEN: User launches vim - the command prompt+command is echoed
        // but then smcup comes immediately, so the "vim" command block
        // won't complete normally - instead a TUI session block is created
        outputRouter.setLastCommandHint('vim file.txt');
        outputRouter.processOutput('user@host:~\$ vim file.txt\n');

        // At this point, a running block for 'vim file.txt' may be created
        // But the TUI smcup will trigger TUI mode

        // Vim sends smcup to enter alternate screen
        outputRouter.processOutput(smcup);

        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 20));

        // THEN: TUI mode is activated
        expect(outputRouter.isInTuiMode, true);
        expect(transitions, contains('enter:vim file.txt'));

        // WHEN: User edits in vim (output during TUI mode)
        outputRouter.processOutput('\x1b[H\x1b[2J'); // Clear screen
        outputRouter.processOutput('~\n~\n~\n"file.txt" [New File]');

        // We should have: setup block + vim command block + TUI session block
        // The TUI session block is the one that matters for TUI
        final tuiBlocks =
            blockController.state.blocks.where((b) => b.isTuiSession);
        expect(tuiBlocks, isNotEmpty);

        // WHEN: User exits vim (sends rmcup)
        outputRouter.processOutput(rmcup);

        // Wait for rmcup detection (no debounce for exit, but allow event propagation)
        await Future.delayed(const Duration(milliseconds: 5));

        // THEN: TUI mode is deactivated
        expect(outputRouter.isInTuiMode, false);
        expect(transitions, contains('exit'));

        // WHEN: Shell shows prompt again
        outputRouter.processOutput('user@host:~\$ \n');

        // THEN: Block processing resumes
        outputRouter.processOutput('user@host:~\$ ls\n');
        outputRouter.processOutput('file.txt\n');
        outputRouter.processOutput('user@host:~\$ \n');

        // Should have blocks including the ls command
        final lsBlock =
            blockController.state.blocks.where((b) => b.command == 'ls');
        expect(lsBlock, isNotEmpty);
        expect(lsBlock.first.status, BlockStatus.success);
      });

      // @telos-scenario L2:...:tui_mode:vim-with-command-detection
      test('vim command is captured in TUI session block', () async {
        // User launches vim
        outputRouter.setLastCommandHint('vim /etc/hosts');
        outputRouter.processOutput('user@host:~\$ vim /etc/hosts\n');
        outputRouter.processOutput(smcup);

        await Future.delayed(const Duration(milliseconds: 20));

        // Find the TUI session block
        final tuiBlock = blockController.state.blocks
            .where((b) => b.isTuiSession)
            .firstOrNull;
        expect(tuiBlock, isNotNull);
        expect(tuiBlock!.command, 'vim /etc/hosts');
      });
    });

    group('Task 11.2: htop and resize', () {
      // @telos-scenario L2:...:tui_mode:htop-full-screen
      test('run htop, verify full-screen rendering, verify resize works',
          () async {
        // Track output forwarding (simulates terminal rendering)
        final forwardedOutput = <String>[];
        outputRouter.onProcessedOutput = (data) => forwardedOutput.add(data);

        // GIVEN: User at prompt
        outputRouter.processOutput('user@host:~\$ \n');

        // WHEN: User runs htop
        outputRouter.setLastCommandHint('htop');
        outputRouter.processOutput('user@host:~\$ htop\n');
        outputRouter.processOutput(smcup);

        await Future.delayed(const Duration(milliseconds: 20));

        // THEN: TUI mode active
        expect(outputRouter.isInTuiMode, true);

        // WHEN: htop renders full-screen content
        final htopOutput = '''
\x1b[H\x1b[2J
  CPU[||||||||||||||||||||  50.0%]   Tasks: 123, 456 thr; 2 running
  Mem[||||||||||||||||1.5G/8G    ]   Load average: 0.50 0.45 0.42
  Swp[                   0K/0K  ]   Uptime: 01:23:45

  PID USER      PR  NI VIRT  RES  SHR S  %CPU %MEM TIME+ COMMAND
 1234 root      20   0 150M  50M  30M S  25.0  0.6  1:23 process1
''';
        outputRouter.processOutput(htopOutput);

        // THEN: All output is forwarded to terminal (not blocked)
        expect(forwardedOutput.any((s) => s.contains('CPU')), true);
        expect(forwardedOutput.any((s) => s.contains('Tasks')), true);

        // AND: A TUI session block was created
        final tuiBlocks =
            blockController.state.blocks.where((b) => b.isTuiSession);
        expect(tuiBlocks, isNotEmpty);
        expect(tuiBlocks.first.command, 'htop');

        // WHEN: Terminal resize happens (simulated by more screen content)
        final resizedOutput = '''
\x1b[H\x1b[2J
  CPU[||||||||||||||||||||||||||||||||||||||  75.0%]   Tasks: 125
''';
        outputRouter.processOutput(resizedOutput);

        // THEN: Output continues to be forwarded
        expect(forwardedOutput.any((s) => s.contains('75.0%')), true);

        // WHEN: User exits htop
        outputRouter.processOutput(rmcup);

        // THEN: TUI mode ends
        expect(outputRouter.isInTuiMode, false);
      });
    });

    group('Task 11.3: TUI session block history', () {
      // @telos-scenario L2:...:tui_mode:session-block-in-history
      test('TUI session block appears in history after TUI exit', () async {
        // GIVEN: Some command history
        outputRouter.processOutput('user@host:~\$ pwd\n');
        outputRouter.processOutput('/home/user\n');
        outputRouter.processOutput('user@host:~\$ \n');

        expect(blockController.state.blocks, hasLength(1));

        // WHEN: User enters TUI mode
        // Note: setLastCommandHint tells the TUI detector what command triggered this
        outputRouter.setLastCommandHint('less README.md');
        // The prompt+command line creates a regular block
        outputRouter.processOutput('user@host:~\$ less README.md\n');
        // Then smcup triggers TUI mode and creates a TUI session block
        outputRouter.processOutput(smcup);

        await Future.delayed(const Duration(milliseconds: 20));

        // We should have: pwd block + less block + TUI session block
        // The TUI session block is created when smcup is detected
        final tuiBlocks =
            blockController.state.blocks.where((b) => b.isTuiSession);
        expect(tuiBlocks, isNotEmpty,
            reason: 'TUI session block should be created');

        final tuiBlock = tuiBlocks.first;
        expect(tuiBlock.command, 'less README.md');
        expect(tuiBlock.status, BlockStatus.running);

        // WHEN: User exits TUI mode
        outputRouter.processOutput(rmcup);

        // Wait for rmcup detection and event propagation
        await Future.delayed(const Duration(milliseconds: 5));

        // THEN: TUI session block should be completed (status changes from running)
        final completedTuiBlock =
            blockController.state.blocks.firstWhere((b) => b.isTuiSession);
        expect(completedTuiBlock.status, BlockStatus.success);

        // WHEN: More commands are run after
        outputRouter.processOutput('user@host:~\$ echo done\n');
        outputRouter.processOutput('done\n');
        outputRouter.processOutput('user@host:~\$ \n');

        // THEN: History contains at least: pwd, TUI session, echo done
        // (There may also be a 'less README.md' regular block depending on timing)
        final echoBlock =
            blockController.state.blocks.where((b) => b.command == 'echo done');
        expect(echoBlock, isNotEmpty);
        expect(echoBlock.first.status, BlockStatus.success);

        // Verify TUI session is still in history
        final finalTuiBlocks =
            blockController.state.blocks.where((b) => b.isTuiSession);
        expect(finalTuiBlocks, isNotEmpty);
      });

      // @telos-scenario L2:...:tui_mode:tui-block-has-duration
      test('TUI session block records duration', () async {
        // Start TUI mode
        outputRouter.setLastCommandHint('nano');
        outputRouter.processOutput('user@host:~\$ nano\n');
        outputRouter.processOutput(smcup);

        await Future.delayed(const Duration(milliseconds: 20));

        final tuiBlock =
            blockController.state.blocks.firstWhere((b) => b.isTuiSession);
        final startTime = tuiBlock.startedAt;
        expect(startTime, isNotNull);
        expect(tuiBlock.completedAt, isNull); // Still running

        // Wait a bit and exit
        await Future.delayed(const Duration(milliseconds: 50));
        outputRouter.processOutput(rmcup);

        // Complete the TUI session (simulating what OutputRouterProvider does)
        await blockController.completeTuiSessionBlock();

        // Verify duration
        final completedBlock =
            blockController.state.blocks.firstWhere((b) => b.isTuiSession);
        expect(completedBlock.completedAt, isNotNull);
        expect(completedBlock.executionDuration, isNotNull);
        expect(
            completedBlock.executionDuration!.inMilliseconds, greaterThan(0));
      });
    });

    group('Task 11.4: disconnect during TUI mode', () {
      // @telos-scenario L2:...:tui_mode:disconnect-marks-cancelled
      test('disconnect during TUI mode marks block as cancelled', () async {
        // GIVEN: User is in TUI mode
        outputRouter.setLastCommandHint('vim important.txt');
        outputRouter.processOutput('user@host:~\$ vim important.txt\n');
        outputRouter.processOutput(smcup);

        await Future.delayed(const Duration(milliseconds: 20));

        expect(outputRouter.isInTuiMode, true);

        final tuiBlock =
            blockController.state.blocks.firstWhere((b) => b.isTuiSession);
        expect(tuiBlock.status, BlockStatus.running);

        // WHEN: Connection is lost (simulating disconnect)
        // First, force deactivate TUI mode
        tuiDetector.forceDeactivate();

        // Then cancel the TUI session (what disconnect handler does)
        await blockController.cancelActiveTuiSession();

        // THEN: TUI session block is marked as cancelled
        final cancelledBlock =
            blockController.state.blocks.firstWhere((b) => b.isTuiSession);
        expect(cancelledBlock.status, BlockStatus.cancelled);
        expect(cancelledBlock.completedAt, isNotNull);
      });

      // @telos-scenario L2:...:tui_mode:app-termination-cleans-up
      test('app termination during TUI mode cleans up gracefully', () async {
        // Enter TUI mode
        outputRouter.setLastCommandHint('htop');
        outputRouter.processOutput('user@host:~\$ htop\n');
        outputRouter.processOutput(smcup);

        await Future.delayed(const Duration(milliseconds: 20));

        expect(outputRouter.isInTuiMode, true);

        // Simulate app termination by disposing resources
        outputRouter.dispose();
        tuiDetector.dispose();

        // Should not throw - graceful cleanup
        expect(() => container.dispose(), returnsNormally);
      });

      // @telos-scenario L2:...:tui_mode:reset-clears-tui-state
      test('reset clears TUI mode state for reconnection', () async {
        // Enter TUI mode
        outputRouter.setLastCommandHint('less file.txt');
        outputRouter.processOutput('user@host:~\$ less file.txt\n');
        outputRouter.processOutput(smcup);

        await Future.delayed(const Duration(milliseconds: 20));

        expect(outputRouter.isInTuiMode, true);

        // WHEN: Router is reset (simulating reconnection)
        outputRouter.reset();

        // THEN: TUI mode is cleared
        expect(outputRouter.isInTuiMode, false);
        expect(outputRouter.isPaused, false);
      });
    });

    group('Edge cases', () {
      // @telos-scenario L2:...:tui_mode:rapid-smcup-rmcup
      test('rapid smcup/rmcup pairs are debounced', () async {
        // Track transitions
        final transitions = <String>[];
        outputRouter.onTuiModeEnter = (cmd) => transitions.add('enter');
        outputRouter.onTuiModeExit = () => transitions.add('exit');

        // Send rapid smcup/rmcup (some terminals do this during initialization)
        outputRouter.processOutput(smcup);
        outputRouter.processOutput(rmcup);
        outputRouter.processOutput(smcup);
        outputRouter.processOutput(rmcup);

        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 50));

        // Should have been debounced - no false positives
        expect(transitions, isEmpty);
        expect(outputRouter.isInTuiMode, false);
      });

      // @telos-scenario L2:...:tui_mode:split-sequence-detection
      test('handles escape sequences split across chunks', () async {
        // Track transitions
        final transitions = <String>[];
        outputRouter.onTuiModeEnter = (cmd) => transitions.add('enter');

        // Split smcup sequence: \x1b[?1049h
        // First chunk: \x1b[?104
        // Second chunk: 9h
        outputRouter.processOutput('\x1b[?104');
        outputRouter.processOutput('9h');

        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 20));

        // Should still detect TUI mode
        expect(outputRouter.isInTuiMode, true);
        expect(transitions, contains('enter'));
      });

      // @telos-scenario L2:...:tui_mode:nested-applications
      test('handles nested TUI applications (less within vim)', () async {
        // Enter vim
        outputRouter.setLastCommandHint('vim');
        outputRouter.processOutput(smcup);

        await Future.delayed(const Duration(milliseconds: 20));
        expect(outputRouter.isInTuiMode, true);

        // Vim might spawn a subprocess that also uses alternate screen
        // The terminal typically doesn't send another smcup
        // Just verify we stay in TUI mode
        outputRouter.processOutput('\x1b[H\x1b[2Jsubprocess output');
        expect(outputRouter.isInTuiMode, true);

        // Exit vim
        outputRouter.processOutput(rmcup);
        expect(outputRouter.isInTuiMode, false);
      });

      // @telos-scenario L2:...:tui_mode:output-passthrough
      test('all output is forwarded during TUI mode', () async {
        final forwardedOutput = <String>[];
        outputRouter.onProcessedOutput = (data) => forwardedOutput.add(data);

        // Enter TUI mode
        outputRouter.processOutput(smcup);

        await Future.delayed(const Duration(milliseconds: 20));

        // Various TUI output
        outputRouter.processOutput('line1\n');
        outputRouter.processOutput('\x1b[32mcolored\x1b[0m\n');
        outputRouter.processOutput('\x1b[H'); // cursor home

        // All should be forwarded
        expect(forwardedOutput, contains('line1\n'));
        expect(forwardedOutput.any((s) => s.contains('\x1b[32m')), true);
        expect(forwardedOutput.any((s) => s.contains('\x1b[H')), true);
      });
    });

    group('Integration with BlockListController', () {
      // @telos-scenario L2:...:tui_mode:tui-blocks-different-from-command-blocks
      test('TUI session blocks have distinct properties from command blocks',
          () async {
        // Create a regular command block
        outputRouter.processOutput('user@host:~\$ echo test\n');
        outputRouter.processOutput('test\n');
        outputRouter.processOutput('user@host:~\$ \n');

        // Create a TUI session block
        outputRouter.setLastCommandHint('vim');
        outputRouter.processOutput('user@host:~\$ vim\n');
        outputRouter.processOutput(smcup);

        await Future.delayed(const Duration(milliseconds: 20));

        final commandBlock = blockController.state.blocks[0];
        final tuiBlock = blockController.state.blocks[1];

        // Command block properties
        expect(commandBlock.isTuiSession, false);
        expect(commandBlock.output, contains('test'));

        // TUI block properties
        expect(tuiBlock.isTuiSession, true);
        expect(tuiBlock.output, isEmpty); // TUI blocks don't capture output
      });
    });
  });
}
