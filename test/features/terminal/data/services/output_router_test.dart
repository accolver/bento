// @telos-test L1:function:lib/features/terminal/data/services:output_router

import 'dart:async';

import 'package:bento/features/terminal/data/services/output_router.dart';
import 'package:bento/features/terminal/data/services/prompt_detector.dart';
import 'package:bento/features/terminal/data/services/tui_mode_detector.dart';
import 'package:bento/features/terminal/domain/entities/block.dart';
import 'package:bento/features/terminal/domain/entities/block_status.dart';
import 'package:bento/features/terminal/presentation/providers/block_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockBlockListController extends Mock implements BlockListController {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(BlockStatus.running);
  });

  late MockBlockListController mockController;
  late OutputRouter router;

  setUp(() {
    mockController = MockBlockListController();
    router = OutputRouter(
      blockController: mockController,
      bufferDuration: const Duration(milliseconds: 1), // Fast for tests
    );

    // Default stubs
    when(() => mockController.hasActiveBlock).thenReturn(false);
    when(() => mockController.createBlock(any())).thenReturn('block-1');
    when(() => mockController.appendOutput(any())).thenReturn(null);
    when(() => mockController.completeBlock(
          status: any(named: 'status'),
          exitCode: any(named: 'exitCode'),
          blockId: any(named: 'blockId'),
        )).thenAnswer((_) async {});
  });

  tearDown(() {
    router.dispose();
  });

  group('OutputRouter', () {
    group('processOutput', () {
      // @telos-scenario L1:...:output_router:detects-new-command
      test('creates block when prompt with command is detected', () async {
        // GIVEN: No active block
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // WHEN: Output with prompt and command is processed
        router.processOutput('user@host:~\$ ls -la\n');

        // THEN: A new block is created with the command
        verify(() => mockController.createBlock('ls -la')).called(1);
      });

      // @telos-scenario L1:...:output_router:ignores-prompt-only
      test('does not create block for prompt without command', () async {
        // GIVEN: No active block
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // WHEN: Output with just a prompt (no command) is processed
        router.processOutput('user@host:~\$ \n');

        // THEN: No block is created
        verifyNever(() => mockController.createBlock(any()));
      });

      // @telos-scenario L1:...:output_router:buffers-output
      test('buffers output and flushes to active block', () async {
        // GIVEN: There's an active block
        when(() => mockController.hasActiveBlock).thenReturn(true);

        // WHEN: Output is processed
        router.processOutput('line 1\nline 2\n');

        // Wait for flush
        await Future.delayed(const Duration(milliseconds: 10));

        // THEN: Output is appended to the block
        verify(() => mockController.appendOutput(any())).called(greaterThan(0));
      });

      // @telos-scenario L1:...:output_router:completes-on-new-prompt
      test('completes active block when new prompt appears', () async {
        // GIVEN: There's an active block
        when(() => mockController.hasActiveBlock).thenReturn(true);

        // WHEN: New prompt appears
        router.processOutput('user@host:~\$ \n');

        // THEN: Block is completed
        verify(() => mockController.completeBlock(
              status: any(named: 'status'),
              exitCode: any(named: 'exitCode'),
              blockId: any(named: 'blockId'),
            )).called(1);
      });

      // @telos-scenario L1:...:output_router:forwards-output
      test('forwards output via callback', () async {
        String? forwardedOutput;
        router.onProcessedOutput = (data) => forwardedOutput = data;

        // WHEN: Output is processed
        router.processOutput('test output');

        // THEN: Callback receives the raw output
        expect(forwardedOutput, 'test output');
      });
    });

    group('processInput', () {
      // @telos-scenario L1:...:output_router:cancels-on-ctrl-c
      test('completes block with cancelled status on Ctrl+C', () async {
        // GIVEN: There's an active block
        when(() => mockController.hasActiveBlock).thenReturn(true);

        // WHEN: Ctrl+C is pressed
        router.processInput('\x03');

        // THEN: Block is completed with cancelled status
        verify(() => mockController.completeBlock(
              status: BlockStatus.cancelled,
              exitCode: any(named: 'exitCode'),
              blockId: any(named: 'blockId'),
            )).called(1);
      });

      // @telos-scenario L1:...:output_router:ignores-ctrl-c-no-block
      test('ignores Ctrl+C when no active block', () async {
        // GIVEN: No active block
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // WHEN: Ctrl+C is pressed
        router.processInput('\x03');

        // THEN: No action taken
        verifyNever(() => mockController.completeBlock(
              status: any(named: 'status'),
              exitCode: any(named: 'exitCode'),
              blockId: any(named: 'blockId'),
            ));
      });
    });

    group('exit code detection', () {
      // @telos-scenario L1:...:output_router:detects-success-exit-code
      test('sets success status when exit code is 0', () async {
        // GIVEN: Active block exists
        when(() => mockController.hasActiveBlock).thenReturn(true);

        // WHEN: Output with exit code 0 followed by prompt
        router.processOutput('exit code: 0\nuser@host:~\$ \n');

        // THEN: Block completed with success
        verify(() => mockController.completeBlock(
              status: BlockStatus.success,
              exitCode: 0,
              blockId: any(named: 'blockId'),
            )).called(1);
      });

      // @telos-scenario L1:...:output_router:detects-failed-exit-code
      test('sets failed status when exit code is non-zero', () async {
        // GIVEN: Active block exists
        when(() => mockController.hasActiveBlock).thenReturn(true);

        // WHEN: Output with non-zero exit code followed by prompt
        router.processOutput('exit code: 1\nuser@host:~\$ \n');

        // THEN: Block completed with failed status
        verify(() => mockController.completeBlock(
              status: BlockStatus.failed,
              exitCode: 1,
              blockId: any(named: 'blockId'),
            )).called(1);
      });
    });

    group('cancellation detection', () {
      // @telos-scenario L1:...:output_router:detects-sigint
      test('sets cancelled status when SIGINT detected', () async {
        // GIVEN: Active block exists
        when(() => mockController.hasActiveBlock).thenReturn(true);

        // WHEN: Output with SIGINT followed by prompt
        router.processOutput('^C\nuser@host:~\$ \n');

        // THEN: Block completed with cancelled status
        verify(() => mockController.completeBlock(
              status: BlockStatus.cancelled,
              exitCode: any(named: 'exitCode'),
              blockId: any(named: 'blockId'),
            )).called(1);
      });
    });

    group('reset', () {
      // @telos-scenario L1:...:output_router:resets-state
      test('clears buffer and state on reset', () async {
        // GIVEN: Router has processed some output
        when(() => mockController.hasActiveBlock).thenReturn(true);
        router.processOutput('some output');

        // WHEN: Reset is called
        router.reset();

        // THEN: State is cleared (process more output to verify)
        // Processing same prompt line should work (not deduplicated)
        when(() => mockController.hasActiveBlock).thenReturn(false);
        router.processOutput('user@host:~\$ ls\n');
        verify(() => mockController.createBlock('ls')).called(1);
      });
    });

    group('custom patterns', () {
      // @telos-scenario L1:...:output_router:uses-custom-patterns
      test('withCustomPatterns creates new router with patterns', () {
        final customRouter = router.withCustomPatterns([r'myshell> ']);
        expect(customRouter, isA<OutputRouter>());
        expect(customRouter, isNot(same(router)));
      });
    });

    group('sequential commands', () {
      // @telos-scenario L1:...:output_router:creates-block-for-each-command
      test('creates new block for EACH command (not just first)', () {
        // This tests the critical bug: new commands not creating new blocks
        var blockCount = 0;
        when(() => mockController.createBlock(any())).thenAnswer((_) {
          blockCount++;
          return 'block-$blockCount';
        });

        // Simulate: command 1 runs, completes, then command 2 runs
        // First command
        when(() => mockController.hasActiveBlock).thenReturn(false);
        router.processOutput('user@host:~\$ ls\n');
        expect(blockCount, 1);

        // Command output and completion
        when(() => mockController.hasActiveBlock).thenReturn(true);
        router.processOutput('file1.txt\nfile2.txt\n');
        router.processOutput(
            'user@host:~\$ \n'); // Prompt only = command complete

        // Second command - THIS IS THE BUG: should create a new block
        when(() => mockController.hasActiveBlock).thenReturn(false);
        router.processOutput('user@host:~\$ pwd\n');
        expect(blockCount, 2,
            reason: 'Second command should create a new block');
      });

      // @telos-scenario L1:...:output_router:same-command-twice
      test('handles same command run multiple times (e.g., ls then ls again)',
          () {
        // This is a critical test - running the same command twice should create 2 blocks
        var blockCount = 0;
        when(() => mockController.createBlock(any())).thenAnswer((_) {
          blockCount++;
          return 'block-$blockCount';
        });

        // First ls command
        when(() => mockController.hasActiveBlock).thenReturn(false);
        router.processOutput('user@host:~\$ ls\n');
        expect(blockCount, 1);

        // First ls completes
        when(() => mockController.hasActiveBlock).thenReturn(true);
        router.processOutput('file1.txt\n');
        router.processOutput('user@host:~\$ \n');

        // Second ls command - same command!
        when(() => mockController.hasActiveBlock).thenReturn(false);
        router.processOutput('user@host:~\$ ls\n');
        expect(blockCount, 2,
            reason: 'Same command run twice should create 2 blocks');
      });

      // @telos-scenario L1:...:output_router:no-duplicate-from-echo
      test('does NOT create duplicate blocks from terminal echo', () {
        // When you type a command, the terminal echoes it back
        // This should NOT create a duplicate block
        var blockCount = 0;
        when(() => mockController.createBlock(any())).thenAnswer((_) {
          blockCount++;
          return 'block-$blockCount';
        });

        // User types command, terminal echoes it on same line as prompt
        when(() => mockController.hasActiveBlock).thenReturn(false);
        router.processOutput('user@host:~\$ ls -la\n');
        expect(blockCount, 1);

        // Terminal might echo the command again (some terminals do this)
        // This should NOT create another block
        router.processOutput('ls -la\n');
        expect(blockCount, 1, reason: 'Echo should not create duplicate block');
      });

      // @telos-scenario L1:...:output_router:multiple-sequential-commands
      test('handles multiple sequential commands correctly', () {
        final commands = <String>[];
        when(() => mockController.createBlock(any())).thenAnswer((invocation) {
          final cmd = invocation.positionalArguments[0] as String;
          commands.add(cmd);
          return 'block-${commands.length}';
        });

        // Simulate a realistic session
        // Command 1: ls
        when(() => mockController.hasActiveBlock).thenReturn(false);
        router.processOutput('user@host:~\$ ls\n');

        when(() => mockController.hasActiveBlock).thenReturn(true);
        router.processOutput('file1.txt\nfile2.txt\n');
        router.processOutput('user@host:~\$ \n');

        // Command 2: pwd
        when(() => mockController.hasActiveBlock).thenReturn(false);
        router.processOutput('user@host:~\$ pwd\n');

        when(() => mockController.hasActiveBlock).thenReturn(true);
        router.processOutput('/home/user\n');
        router.processOutput('user@host:~\$ \n');

        // Command 3: echo hello
        when(() => mockController.hasActiveBlock).thenReturn(false);
        router.processOutput('user@host:~\$ echo hello\n');

        when(() => mockController.hasActiveBlock).thenReturn(true);
        router.processOutput('hello\n');
        router.processOutput('user@host:~\$ \n');

        // Verify all 3 commands created blocks
        expect(commands, ['ls', 'pwd', 'echo hello']);
      });
    });

    group('Starship prompt handling', () {
      // @telos-scenario L1:...:output_router:starship-prompt-with-command
      test('creates block for Starship prompt with ❯ symbol', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        router.processOutput('~/dev/project ❯ git status\n');

        verify(() => mockController.createBlock('git status')).called(1);
      });

      // @telos-scenario L1:...:output_router:starship-prompt-only
      test('does not create block for Starship prompt without command', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        router.processOutput('~/dev/project ❯ \n');

        verifyNever(() => mockController.createBlock(any()));
      });

      // @telos-scenario L1:...:output_router:starship-complex-prompt
      test('extracts command from complex Starship prompt', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // Starship prompt with path, git branch, and AWS profile
        router.processOutput(
            ' ~/dev/annuity  main  alan(prod) ❯ terraform plan\n');

        verify(() => mockController.createBlock('terraform plan')).called(1);
      });

      // @telos-scenario L1:...:output_router:starship-with-ansi
      test('handles Starship prompt with ANSI color codes', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // Starship prompt with ANSI escape codes for colors
        router
            .processOutput('\x1b[36m~/dev\x1b[0m \x1b[32m❯\x1b[0m npm test\n');

        verify(() => mockController.createBlock('npm test')).called(1);
      });
    });

    group('prompt format variations', () {
      // @telos-scenario L1:...:output_router:bash-prompt
      test('extracts command from bash prompt', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        router.processOutput('user@hostname:~/projects\$ make build\n');

        verify(() => mockController.createBlock('make build')).called(1);
      });

      // @telos-scenario L1:...:output_router:zsh-prompt
      test('extracts command from zsh prompt with %', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        router.processOutput('user@host ~/code % cargo run\n');

        verify(() => mockController.createBlock('cargo run')).called(1);
      });

      // @telos-scenario L1:...:output_router:root-prompt
      test('extracts command from root prompt with #', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        router.processOutput('root@server:/# systemctl restart nginx\n');

        verify(() => mockController.createBlock('systemctl restart nginx'))
            .called(1);
      });

      // @telos-scenario L1:...:output_router:simple-dollar-prompt
      test('extracts command from simple dollar prompt', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        router.processOutput('\$ docker ps\n');

        verify(() => mockController.createBlock('docker ps')).called(1);
      });
    });

    group('false positive prevention', () {
      // @telos-scenario L1:...:output_router:no-block-for-symlink
      test('does NOT create block for symlink arrows in ls output', () {
        when(() => mockController.hasActiveBlock).thenReturn(true);

        // This is ls -la output showing a symlink
        router.processOutput(
            'lrwxr-xr-x  1 user user  50 Jan  1 12:00 link -> target\n');

        verifyNever(() => mockController.createBlock(any()));
      });

      // @telos-scenario L1:...:output_router:no-block-for-file-path
      test('does NOT create block for file paths', () {
        when(() => mockController.hasActiveBlock).thenReturn(true);

        router.processOutput('/Users/alan/.local/state/starship/\n');

        verifyNever(() => mockController.createBlock(any()));
      });

      // @telos-scenario L1:...:output_router:no-block-for-dollar-in-text
      test('does NOT create block for dollar sign in regular text', () {
        when(() => mockController.hasActiveBlock).thenReturn(true);

        router.processOutput('The cost is \$50 per month\n');

        verifyNever(() => mockController.createBlock(any()));
      });
    });

    group('state reset after completion', () {
      // @telos-scenario L1:...:output_router:reset-allows-new-commands
      test('resets state correctly allowing new commands after completion', () {
        var blockCount = 0;
        when(() => mockController.createBlock(any())).thenAnswer((_) {
          blockCount++;
          return 'block-$blockCount';
        });

        // First command
        when(() => mockController.hasActiveBlock).thenReturn(false);
        router.processOutput('user@host:~\$ first\n');
        expect(blockCount, 1);

        // Complete first command
        when(() => mockController.hasActiveBlock).thenReturn(true);
        router.processOutput('output\n');
        router.processOutput('user@host:~\$ \n');

        // After completion, state should be reset to allow new commands
        when(() => mockController.hasActiveBlock).thenReturn(false);
        router.processOutput('user@host:~\$ second\n');
        expect(blockCount, 2, reason: 'State should reset after completion');
      });
    });

    group('ANSI code handling', () {
      // @telos-scenario L1:...:output_router:strips-ansi-for-detection
      test('strips ANSI escape codes before prompt detection', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // Prompt with various ANSI codes (colors, bold, etc.)
        router.processOutput(
            '\x1b[1;32muser@host\x1b[0m:\x1b[1;34m~\x1b[0m\$ ls\n');

        verify(() => mockController.createBlock('ls')).called(1);
      });

      // @telos-scenario L1:...:output_router:preserves-ansi-in-output
      test('preserves ANSI codes in block output', () async {
        when(() => mockController.hasActiveBlock).thenReturn(true);

        final ansiOutput = '\x1b[31mred text\x1b[0m\n';
        router.processOutput(ansiOutput);

        // Wait for flush
        await Future.delayed(const Duration(milliseconds: 10));

        // Verify the output was passed through (ANSI codes preserved)
        verify(() => mockController.appendOutput(any())).called(greaterThan(0));
      });
    });

    group('line ending normalization', () {
      // @telos-scenario L1:...:output_router:handles-crlf-line-endings
      test('handles CRLF (\\r\\n) line endings from SSH', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // SSH/Windows-style line endings
        router.processOutput('user@host:~\$ ls\r\n');

        verify(() => mockController.createBlock('ls')).called(1);
      });

      // @telos-scenario L1:...:output_router:handles-cr-only-line-endings
      test('handles CR-only (\\r) line endings', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // Old Mac-style line endings (rare but possible)
        router.processOutput('user@host:~\$ pwd\ruser@host:~\$ \r');

        verify(() => mockController.createBlock('pwd')).called(1);
      });

      // @telos-scenario L1:...:output_router:mixed-line-endings
      test('handles mixed line endings in single output', () {
        final commands = <String>[];
        when(() => mockController.createBlock(any())).thenAnswer((invocation) {
          final cmd = invocation.positionalArguments[0] as String;
          commands.add(cmd);
          return 'block-${commands.length}';
        });

        when(() => mockController.hasActiveBlock).thenReturn(false);

        // Mix of CRLF, LF, and CR
        router.processOutput('user@host:~\$ cmd1\r\n');
        when(() => mockController.hasActiveBlock).thenReturn(true);
        router.processOutput('output\n');
        router.processOutput('user@host:~\$ \n');

        when(() => mockController.hasActiveBlock).thenReturn(false);
        router.processOutput('user@host:~\$ cmd2\n');

        expect(commands, ['cmd1', 'cmd2']);
      });

      // @telos-scenario L1:...:output_router:starship-with-crlf
      test('handles Starship prompt with CRLF', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        router.processOutput('~/dev ❯ git status\r\n');

        verify(() => mockController.createBlock('git status')).called(1);
      });
    });

    group('input-based command detection', () {
      // @telos-scenario L1:...:output_router:input-command-on-enter
      test('creates block when user presses Enter after typing command', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // First, a prompt appears (sets _atPrompt = true)
        router.processOutput('❯ \n');

        // User types a command character by character
        router.processInput('l');
        router.processInput('s');

        // User presses Enter
        router.processInput('\r');

        // Block should be created with the typed command
        verify(() => mockController.createBlock('ls')).called(1);
      });

      // @telos-scenario L1:...:output_router:input-no-block-for-empty
      test('does NOT create block for empty command (just Enter)', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // Prompt appears
        router.processOutput('user@host:~\$ \n');

        // User just presses Enter without typing anything
        router.processInput('\r');

        verifyNever(() => mockController.createBlock(any()));
      });

      // @telos-scenario L1:...:output_router:input-handles-backspace
      test('handles backspace in input', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // Prompt appears
        router.processOutput('❯ \n');

        // User types "lss" then backspaces and types correct char
        router.processInput('l');
        router.processInput('s');
        router.processInput('s');
        router.processInput('\x7f'); // Backspace (DEL, 127)
        router.processInput('\r');

        verify(() => mockController.createBlock('ls')).called(1);
      });

      // @telos-scenario L1:...:output_router:input-handles-backspace-bs
      test('handles BS character (0x08) for backspace', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // Prompt appears
        router.processOutput('❯ \n');

        // User types "lss" then backspaces using BS (0x08) and types correct char
        router.processInput('l');
        router.processInput('s');
        router.processInput('s');
        router.processInput('\x08'); // Backspace (BS, 8)
        router.processInput('\r');

        verify(() => mockController.createBlock('ls')).called(1);
      });

      // @telos-scenario L1:...:output_router:input-multiple-backspaces
      test('handles multiple consecutive backspaces', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // Prompt appears
        router.processOutput('❯ \n');

        // User types "hello" then backspaces all and types "ls"
        for (final char in 'hello'.split('')) {
          router.processInput(char);
        }
        // Backspace 5 times
        for (var i = 0; i < 5; i++) {
          router.processInput('\x7f');
        }
        router.processInput('l');
        router.processInput('s');
        router.processInput('\r');

        verify(() => mockController.createBlock('ls')).called(1);
      });

      // @telos-scenario L1:...:output_router:input-backspace-on-empty
      test('handles backspace on empty input buffer (no crash)', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // Prompt appears
        router.processOutput('❯ \n');

        // User presses backspace before typing anything
        router.processInput('\x7f');
        router.processInput('\x7f');
        router.processInput('\x7f');

        // Then types command
        router.processInput('l');
        router.processInput('s');
        router.processInput('\r');

        verify(() => mockController.createBlock('ls')).called(1);
      });

      // @telos-scenario L1:...:output_router:input-backspace-partial-word
      test('handles backspace to correct middle of command', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // Prompt appears
        router.processOutput('❯ \n');

        // User types "git statux" then corrects to "git status"
        for (final char in 'git statux'.split('')) {
          router.processInput(char);
        }
        router.processInput('\x7f'); // Remove 'x'
        router.processInput('s'); // Add 's'
        router.processInput('\r');

        verify(() => mockController.createBlock('git status')).called(1);
      });

      // @telos-scenario L1:...:output_router:input-ctrl-c-clears-buffer
      test('Ctrl+C clears input buffer', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // Prompt appears
        router.processOutput('❯ \n');

        // User starts typing
        router.processInput('s');
        router.processInput('o');
        router.processInput('m');
        router.processInput('e');

        // User presses Ctrl+C
        router.processInput('\x03');

        // User types new command and presses Enter
        router.processInput('l');
        router.processInput('s');
        router.processInput('\r');

        // Only "ls" should be the command, not "somels"
        verify(() => mockController.createBlock('ls')).called(1);
      });

      // @telos-scenario L1:...:output_router:input-multiword-command
      test('handles multi-word commands', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // Prompt appears
        router.processOutput('❯ \n');

        // User types "git status"
        for (final char in 'git status'.split('')) {
          router.processInput(char);
        }
        router.processInput('\r');

        verify(() => mockController.createBlock('git status')).called(1);
      });

      // @telos-scenario L1:...:output_router:input-requires-prompt-first
      test('does NOT buffer input before prompt is detected', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // User types before any prompt is shown (shouldn't happen normally)
        router.processInput('l');
        router.processInput('s');
        router.processInput('\r');

        // No block should be created because we weren't at a prompt
        verifyNever(() => mockController.createBlock(any()));
      });

      // @telos-scenario L1:...:output_router:input-ctrl-u-clears-line
      test('Ctrl+U clears input line', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // Prompt appears
        router.processOutput('❯ \n');

        // User types something
        router.processInput('w');
        router.processInput('r');
        router.processInput('o');
        router.processInput('n');
        router.processInput('g');

        // User presses Ctrl+U to clear line
        router.processInput('\x15');

        // User types correct command
        router.processInput('l');
        router.processInput('s');
        router.processInput('\r');

        verify(() => mockController.createBlock('ls')).called(1);
      });
    });

    group('TUI mode detection', () {
      late OutputRouter tuiRouter;
      late List<String?> tuiEnterCommands;
      late int tuiExitCount;

      setUp(() {
        tuiEnterCommands = [];
        tuiExitCount = 0;

        // Create router with TUI mode detection
        tuiRouter = OutputRouter(
          blockController: mockController,
          tuiModeDetector: TuiModeDetector(
              debounceDuration: const Duration(milliseconds: 5)),
          bufferDuration: const Duration(milliseconds: 1),
        );

        tuiRouter.onTuiModeEnter = (command) {
          tuiEnterCommands.add(command);
        };
        tuiRouter.onTuiModeExit = () {
          tuiExitCount++;
        };
      });

      tearDown(() {
        tuiRouter.dispose();
      });

      // @telos-scenario L1:...:output_router:tui-detects-smcup
      test('detects TUI mode when smcup is in output', () async {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // User runs vim
        tuiRouter.processOutput('user@host:~\$ vim file.txt\n');

        // vim outputs smcup (alternate screen)
        tuiRouter.processOutput('\x1b[?1049h');

        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 10));

        expect(tuiRouter.isInTuiMode, isTrue);
        expect(tuiRouter.isPaused, isTrue);
        expect(tuiEnterCommands, hasLength(1));
      });

      // @telos-scenario L1:...:output_router:tui-pauses-block-detection
      test('pauses block detection during TUI mode', () async {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // Enter TUI mode
        tuiRouter.processOutput('\x1b[?1049h');
        await Future.delayed(const Duration(milliseconds: 10));

        // Output that would normally create a block
        tuiRouter.processOutput('user@host:~\$ ls\n');

        // Should not create a block while paused
        verifyNever(() => mockController.createBlock(any()));
      });

      // @telos-scenario L1:...:output_router:tui-forwards-output
      test('continues forwarding output to terminal during TUI mode', () async {
        var outputReceived = '';
        tuiRouter.onProcessedOutput = (data) {
          outputReceived += data;
        };

        // Enter TUI mode
        tuiRouter.processOutput('\x1b[?1049h');
        await Future.delayed(const Duration(milliseconds: 10));

        // TUI application output
        tuiRouter.processOutput('vim content here');

        // Output should still be forwarded
        expect(outputReceived, contains('vim content here'));
      });

      // @telos-scenario L1:...:output_router:tui-detects-rmcup
      test('exits TUI mode when rmcup is detected', () async {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // Enter TUI mode
        tuiRouter.processOutput('\x1b[?1049h');
        await Future.delayed(const Duration(milliseconds: 10));

        expect(tuiRouter.isInTuiMode, isTrue);

        // Exit TUI mode (user exits vim)
        tuiRouter.processOutput('\x1b[?1049l');

        // Wait for async event handling
        await Future.microtask(() {});

        expect(tuiRouter.isInTuiMode, isFalse);
        expect(tuiRouter.isPaused, isFalse);
        expect(tuiExitCount, equals(1));
      });

      // @telos-scenario L1:...:output_router:tui-resumes-block-detection
      test('resumes block detection after TUI mode exits', () async {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // Enter and exit TUI mode
        tuiRouter.processOutput('\x1b[?1049h');
        await Future.delayed(const Duration(milliseconds: 10));
        tuiRouter.processOutput('\x1b[?1049l');

        // Wait for async event handling
        await Future.microtask(() {});

        // Now run a normal command
        tuiRouter.processOutput('user@host:~\$ ls\n');

        // Block should be created now that TUI mode is off
        verify(() => mockController.createBlock('ls')).called(1);
      });

      // @telos-scenario L1:...:output_router:tui-reset-clears-state
      test('reset clears TUI mode state', () async {
        // Enter TUI mode
        tuiRouter.processOutput('\x1b[?1049h');
        await Future.delayed(const Duration(milliseconds: 10));

        expect(tuiRouter.isInTuiMode, isTrue);

        // Reset
        tuiRouter.reset();

        expect(tuiRouter.isPaused, isFalse);
      });

      // @telos-scenario L1:...:output_router:tui-captures-triggering-command
      test('captures triggering command when entering TUI mode', () async {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        // Set last command hint
        tuiRouter.setLastCommandHint('htop');

        // Enter TUI mode
        tuiRouter.processOutput('\x1b[?1049h');
        await Future.delayed(const Duration(milliseconds: 10));

        expect(tuiEnterCommands, ['htop']);
      });

      // @telos-scenario L1:...:output_router:manual-pause-resume
      test('manual pause and resume work', () {
        when(() => mockController.hasActiveBlock).thenReturn(false);

        expect(tuiRouter.isPaused, isFalse);

        tuiRouter.pause();
        expect(tuiRouter.isPaused, isTrue);

        // Command should be ignored while paused
        tuiRouter.processOutput('user@host:~\$ ignored\n');
        verifyNever(() => mockController.createBlock(any()));

        tuiRouter.resume();
        expect(tuiRouter.isPaused, isFalse);

        // Command should work after resume
        tuiRouter.processOutput('user@host:~\$ working\n');
        verify(() => mockController.createBlock('working')).called(1);
      });
    });
  });
}
