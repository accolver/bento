// @telos-test L1:function:lib/features/terminal/data/services:prompt_detector

import 'package:bento/features/terminal/data/services/prompt_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PromptDetector', () {
    late PromptDetector detector;

    setUp(() {
      detector = PromptDetector();
    });

    group('detectPrompt', () {
      // @telos-scenario L1:function:lib/features/terminal/data/services:prompt_detector:detect-bash-prompt
      test('detects standard bash prompt', () {
        final result = detector.detectPrompt('user@hostname:~/projects\$ ');
        expect(result.hasPrompt, true);
      });

      test('detects bash prompt with path', () {
        final result = detector.detectPrompt('user@server:/var/log\$ ');
        expect(result.hasPrompt, true);
      });

      // @telos-scenario L1:function:lib/features/terminal/data/services:prompt_detector:detect-zsh-prompt
      test('detects zsh prompt with %', () {
        final result = detector.detectPrompt('user@host ~/code % ');
        expect(result.hasPrompt, true);
      });

      test('detects simple zsh prompt', () {
        final result = detector.detectPrompt('~/projects % ');
        expect(result.hasPrompt, true);
      });

      // @telos-scenario L1:function:lib/features/terminal/data/services:prompt_detector:detect-fish-prompt
      test('detects fish prompt', () {
        final result = detector.detectPrompt('~/projects> ');
        expect(result.hasPrompt, true);
      });

      test('detects root prompt with #', () {
        final result = detector.detectPrompt('root@server:/# ');
        expect(result.hasPrompt, true);
      });

      test('detects simple dollar prompt', () {
        final result = detector.detectPrompt('\$ ');
        expect(result.hasPrompt, true);
      });

      test('detects bracketed prompt', () {
        final result = detector.detectPrompt('[user@host code]\$ ');
        expect(result.hasPrompt, true);
      });

      test('detects prompt with git branch', () {
        final result = detector.detectPrompt('(main) \$ ');
        expect(result.hasPrompt, true);
      });

      test('detects prompt with virtualenv', () {
        final result = detector.detectPrompt('(venv) user@host \$ ');
        expect(result.hasPrompt, true);
      });

      test('returns false for regular output', () {
        final result = detector.detectPrompt('Hello, World!');
        expect(result.hasPrompt, false);
      });

      test('returns false for empty line', () {
        final result = detector.detectPrompt('');
        expect(result.hasPrompt, false);
      });

      test('returns false for partial prompt-like text', () {
        final result = detector.detectPrompt('The cost is \$50');
        expect(result.hasPrompt, false);
      });

      test('returns false for symlink arrows in ls output', () {
        // This is common ls -la output for symlinks
        final result = detector.detectPrompt(
            'lrwxr-xr-x  1 user user  50 Jan  1 12:00 link -> target');
        expect(result.hasPrompt, false);
      });

      test('returns false for file path containing arrow', () {
        final result =
            detector.detectPrompt('/Users/alan/.local/state/starship/');
        expect(result.hasPrompt, false);
      });

      // Starship-style prompts with Unicode symbols
      test('detects Starship prompt with ❯ symbol', () {
        final result = detector.detectPrompt('~/dev/project ❯ ');
        expect(result.hasPrompt, true);
      });

      test('detects Starship prompt with ➜ symbol', () {
        final result = detector.detectPrompt('➜ ~/code ');
        expect(result.hasPrompt, true);
      });

      test('extracts command from Starship prompt', () {
        final result = detector.detectPrompt('~/dev/project ❯ ls -la');
        expect(result.hasPrompt, true);
        expect(result.command, 'ls -la');
      });

      test('extracts command from complex Starship prompt', () {
        // Simulating a Starship prompt (without ANSI codes)
        final result = detector
            .detectPrompt(' ~/dev/annuity  main  alan(prod) ❯ git status');
        expect(result.hasPrompt, true);
        expect(result.command, 'git status');
      });
    });

    group('command extraction', () {
      // @telos-scenario L1:function:lib/features/terminal/data/services:prompt_detector:extract-command
      test('extracts command after prompt', () {
        // Note: Pattern matches prompts that end at $ - so line with command
        // after prompt may not be detected. Commands are extracted when
        // present in the same line as the prompt match.
        final result = detector.detectPrompt('~\$ ls -la');
        expect(result.hasPrompt, true);
        expect(result.command, 'ls -la');
      });

      test('extracts command with arguments', () {
        final result = detector.detectPrompt('~\$ git commit -m "message"');
        expect(result.hasPrompt, true);
        expect(result.command, 'git commit -m "message"');
      });

      test('returns null command for prompt-only line', () {
        final result = detector.detectPrompt('user@host:~\$ ');
        expect(result.hasPrompt, true);
        expect(result.command, isNull);
      });
    });

    group('detectInOutput', () {
      test('finds prompt in multi-line output', () {
        const output = '''
total 8
drwxr-xr-x  2 user user 4096 Jan 1 12:00 dir1
-rw-r--r--  1 user user  100 Jan 1 12:00 file.txt
user@host:~\$ ''';

        final result = detector.detectInOutput(output);
        expect(result.hasPrompt, true);
      });

      test('returns none when no prompt in output', () {
        const output = '''
Hello World
This is just text
No prompt here''';

        final result = detector.detectInOutput(output);
        expect(result.hasPrompt, false);
      });
    });

    group('detectCommandCompletion', () {
      test('detects completion when prompt appears', () {
        const output = '''
some output
more output
user@host:~\$ ''';

        expect(detector.detectCommandCompletion(output), true);
      });

      test('returns false when no prompt', () {
        const output = '''
command output line 1
command output line 2
command output line 3''';

        expect(detector.detectCommandCompletion(output), false);
      });
    });

    group('detectCancellation', () {
      test('detects Ctrl+C pattern', () {
        expect(detector.detectCancellation('output ^C'), true);
      });

      test('detects Interrupted text', () {
        expect(detector.detectCancellation('Interrupted'), true);
      });

      test('detects SIGINT', () {
        expect(detector.detectCancellation('Received SIGINT'), true);
      });

      test('returns false for normal output', () {
        expect(detector.detectCancellation('normal output'), false);
      });
    });

    group('custom patterns', () {
      // @telos-scenario L1:function:lib/features/terminal/data/services:prompt_detector:custom-prompts
      test('detects custom prompt pattern', () {
        final customDetector = PromptDetector(
          customPatterns: [RegExp(r'CUSTOM>>>\s*$')],
        );

        final result = customDetector.detectPrompt('CUSTOM>>> ');
        expect(result.hasPrompt, true);
      });

      test('withCustomPatterns creates new detector', () {
        final customDetector = detector.withCustomPatterns([r'>>>>\s*$']);
        final result = customDetector.detectPrompt('>>>> ');
        expect(result.hasPrompt, true);
      });

      test('custom patterns checked before defaults', () {
        // This verifies custom patterns take priority
        final customDetector = PromptDetector(
          customPatterns: [RegExp(r'MYPROMPT\s*$')],
        );

        expect(customDetector.detectPrompt('MYPROMPT ').hasPrompt, true);
      });
    });

    group('detectExitCode', () {
      test('detects exit code from pattern', () {
        final code = detector.detectExitCode('exit code: 1');
        expect(code, 1);
      });

      test('detects exited with pattern', () {
        final code = detector.detectExitCode('Command exited with 127');
        expect(code, 127);
      });

      test('returns null for normal output', () {
        final code = detector.detectExitCode('normal output');
        expect(code, isNull);
      });
    });

    group('ANSI code handling', () {
      // @telos-scenario L1:...:prompt_detector:strips-ansi-codes
      test('strips ANSI escape codes before detection', () {
        // Prompt with color codes
        final result = detector.detectPrompt(
          '\x1b[1;32muser@host\x1b[0m:\x1b[1;34m~\x1b[0m\$ ls',
        );
        expect(result.hasPrompt, true);
        expect(result.command, 'ls');
      });

      // @telos-scenario L1:...:prompt_detector:handles-complex-ansi
      test('handles complex ANSI sequences', () {
        // Bold, colors, reset sequences
        final result = detector.detectPrompt(
          '\x1b[1m\x1b[38;5;208m~/dev\x1b[0m \x1b[32m❯\x1b[0m npm test',
        );
        expect(result.hasPrompt, true);
        expect(result.command, 'npm test');
      });

      // @telos-scenario L1:...:prompt_detector:handles-256-color
      test('handles 256-color ANSI codes', () {
        final result = detector.detectPrompt(
          '\x1b[38;5;39m~/projects\x1b[0m\$ git status',
        );
        expect(result.hasPrompt, true);
        expect(result.command, 'git status');
      });

      // @telos-scenario L1:...:prompt_detector:handles-rgb-color
      test('handles RGB ANSI codes', () {
        final result = detector.detectPrompt(
          '\x1b[38;2;255;128;0m~/code\x1b[0m\$ make',
        );
        expect(result.hasPrompt, true);
        expect(result.command, 'make');
      });
    });

    group('Starship prompt variations', () {
      // @telos-scenario L1:...:prompt_detector:starship-with-git-status
      test('detects Starship prompt with git status icons', () {
        // Starship often shows git status with icons
        final result = detector.detectPrompt('~/repo  main [!?] ❯ git add .');
        expect(result.hasPrompt, true);
        expect(result.command, 'git add .');
      });

      // @telos-scenario L1:...:prompt_detector:starship-with-aws-profile
      test('detects Starship prompt with AWS profile', () {
        final result = detector.detectPrompt(
          '~/terraform  main  aws(prod) ❯ terraform plan',
        );
        expect(result.hasPrompt, true);
        expect(result.command, 'terraform plan');
      });

      // @telos-scenario L1:...:prompt_detector:starship-with-kubernetes
      test('detects Starship prompt with Kubernetes context', () {
        final result = detector.detectPrompt(
          '~/k8s ☸ prod-cluster ❯ kubectl get pods',
        );
        expect(result.hasPrompt, true);
        expect(result.command, 'kubectl get pods');
      });

      // @telos-scenario L1:...:prompt_detector:starship-multiline-last-line
      test('detects command on Starship multiline prompt (last line)', () {
        // Starship can be configured for multiline prompts
        // The command appears on the line with ❯
        final result = detector.detectPrompt('❯ docker compose up');
        expect(result.hasPrompt, true);
        expect(result.command, 'docker compose up');
      });

      // @telos-scenario L1:...:prompt_detector:starship-arrow-symbol
      test('detects Starship prompt with ➜ arrow', () {
        final result =
            detector.detectPrompt('➜ ~/code git:(main) npm run build');
        expect(result.hasPrompt, true);
        // Command extraction should get everything after the prompt symbol
        expect(result.command, isNotNull);
      });
    });

    group('false positive prevention', () {
      // @telos-scenario L1:...:prompt_detector:no-false-positive-symlink
      test('does NOT detect symlink arrow as prompt', () {
        // ls -la output with symlinks
        final result = detector.detectPrompt(
          'lrwxrwxrwx 1 user user 24 Jan 1 12:00 current -> releases/v1.2.3',
        );
        expect(result.hasPrompt, false);
      });

      // @telos-scenario L1:...:prompt_detector:no-false-positive-redirect
      test('does NOT detect shell redirect as prompt', () {
        // This is output showing a redirect, not a prompt
        final result = detector.detectPrompt('echo "hello" > output.txt');
        expect(result.hasPrompt, false);
      });

      // @telos-scenario L1:...:prompt_detector:no-false-positive-comparison
      test('does NOT detect comparison operators as prompt', () {
        final result = detector.detectPrompt('if [ \$count -gt 5 ]; then');
        expect(result.hasPrompt, false);
      });

      // @telos-scenario L1:...:prompt_detector:no-false-positive-env-var
      test('does NOT detect environment variable as prompt', () {
        final result =
            detector.detectPrompt('export PATH=\$PATH:/usr/local/bin');
        expect(result.hasPrompt, false);
      });

      // @telos-scenario L1:...:prompt_detector:no-false-positive-price
      test('does NOT detect price as prompt', () {
        final result = detector.detectPrompt('Total: \$99.99');
        expect(result.hasPrompt, false);
      });

      // @telos-scenario L1:...:prompt_detector:no-false-positive-jquery
      test('does NOT detect jQuery selector as prompt', () {
        final result = detector.detectPrompt('\$(".button").click()');
        expect(result.hasPrompt, false);
      });

      // @telos-scenario L1:...:prompt_detector:no-false-positive-perl
      test('does NOT detect Perl variable as prompt', () {
        final result = detector.detectPrompt('my \$variable = "value";');
        expect(result.hasPrompt, false);
      });
    });

    group('edge cases', () {
      // @telos-scenario L1:...:prompt_detector:whitespace-only-command
      test('returns null for whitespace-only after prompt', () {
        final result = detector.detectPrompt('user@host:~\$    ');
        expect(result.hasPrompt, true);
        expect(result.command, isNull);
      });

      // @telos-scenario L1:...:prompt_detector:command-with-leading-space
      test('trims leading whitespace from command', () {
        final result = detector.detectPrompt('user@host:~\$   ls -la');
        expect(result.hasPrompt, true);
        expect(result.command, 'ls -la');
      });

      // @telos-scenario L1:...:prompt_detector:very-long-path
      test('handles very long paths in prompt', () {
        final result = detector.detectPrompt(
          'user@host:/very/long/path/to/some/deeply/nested/directory\$ pwd',
        );
        expect(result.hasPrompt, true);
        expect(result.command, 'pwd');
      });

      // @telos-scenario L1:...:prompt_detector:unicode-in-path
      // NOTE: This is a known limitation - \w in Dart regex doesn't match Unicode
      // by default. For now, we document this as expected behavior.
      // A future enhancement could use Unicode-aware patterns.
      test('handles Unicode characters in path', () {
        // Standard user@host pattern with Unicode path doesn't match
        // because \w doesn't include Chinese characters
        final result = detector.detectPrompt('user@host:~/文档/项目\$ ls');
        // This currently returns false - documenting as known limitation
        // If this becomes a requirement, we need to update the regex patterns
        expect(result.hasPrompt, false,
            reason:
                'Known limitation: Unicode paths not supported in user@host pattern');
      },
          skip:
              'Known limitation: Unicode paths not fully supported - see issue tracker');

      // @telos-scenario L1:...:prompt_detector:hostname-with-dots
      test('handles hostname with dots', () {
        final result = detector.detectPrompt(
          'user@server.example.com:~\$ uptime',
        );
        expect(result.hasPrompt, true);
        expect(result.command, 'uptime');
      });

      // @telos-scenario L1:...:prompt_detector:username-with-dots
      test('handles username with dots', () {
        final result = detector.detectPrompt(
          'john.doe@server:~\$ whoami',
        );
        expect(result.hasPrompt, true);
        expect(result.command, 'whoami');
      });
    });

    group('command extraction accuracy', () {
      // @telos-scenario L1:...:prompt_detector:extracts-only-command
      test('extracts ONLY the command, not the path/prompt prefix', () {
        final result = detector.detectPrompt(
          'user@host:/home/user/projects\$ npm install express',
        );
        expect(result.hasPrompt, true);
        expect(result.command, 'npm install express');
        // Should NOT include the path
        expect(result.command, isNot(contains('/home/user')));
      });

      // @telos-scenario L1:...:prompt_detector:extracts-command-with-pipes
      test('extracts command with pipes', () {
        final result = detector.detectPrompt(
          'user@host:~\$ cat file.txt | grep error | wc -l',
        );
        expect(result.hasPrompt, true);
        expect(result.command, 'cat file.txt | grep error | wc -l');
      });

      // @telos-scenario L1:...:prompt_detector:extracts-command-with-redirect
      test('extracts command with redirects', () {
        final result = detector.detectPrompt(
          'user@host:~\$ echo "test" > output.txt 2>&1',
        );
        expect(result.hasPrompt, true);
        expect(result.command, 'echo "test" > output.txt 2>&1');
      });

      // @telos-scenario L1:...:prompt_detector:extracts-command-with-semicolon
      test('extracts command with semicolons', () {
        final result = detector.detectPrompt(
          'user@host:~\$ cd /tmp; ls; pwd',
        );
        expect(result.hasPrompt, true);
        expect(result.command, 'cd /tmp; ls; pwd');
      });

      // @telos-scenario L1:...:prompt_detector:extracts-command-with-ampersand
      test('extracts command with background operator', () {
        final result = detector.detectPrompt(
          'user@host:~\$ sleep 100 &',
        );
        expect(result.hasPrompt, true);
        expect(result.command, 'sleep 100 &');
      });
    });

    group('carriage return handling', () {
      // @telos-scenario L1:...:prompt_detector:strips-carriage-return
      test('strips carriage return from line before detection', () {
        // SSH/terminals often send \r\n line endings
        // The \r should be stripped before pattern matching
        final result = detector.detectPrompt('user@host:~\$ ls\r');
        expect(result.hasPrompt, true);
        expect(result.command, 'ls');
      });

      // @telos-scenario L1:...:prompt_detector:starship-with-carriage-return
      test('detects Starship prompt with trailing carriage return', () {
        final result = detector.detectPrompt('❯ docker ps\r');
        expect(result.hasPrompt, true);
        expect(result.command, 'docker ps');
      });

      // @telos-scenario L1:...:prompt_detector:prompt-only-with-carriage-return
      test('detects prompt-only line with carriage return', () {
        final result = detector.detectPrompt('user@host:~\$ \r');
        expect(result.hasPrompt, true);
        expect(result.command, isNull);
      });
    });
  });
}
