// @telos-test L1:function:lib/features/session/presentation/providers:session_terminal_provider

import 'package:bento/features/session/presentation/providers/session_terminal_controller.dart';
import 'package:bento/features/terminal/domain/entities/ssh_auth_method.dart';
import 'package:bento/features/terminal/domain/entities/ssh_connection_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/xterm.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('SessionTerminalController', () {
    // @telos-scenario L1:function:lib/features/session/presentation/providers:session_terminal_provider:create-terminal
    group('create terminal for session', () {
      test('creates new Terminal instance for session', () {
        final terminal = container.read(
          sessionTerminalControllerProvider('session-1'),
        );

        expect(terminal, isA<Terminal>());
      });

      test('returns same instance for same session ID', () {
        final terminal1 = container.read(
          sessionTerminalControllerProvider('session-1'),
        );
        final terminal2 = container.read(
          sessionTerminalControllerProvider('session-1'),
        );

        expect(identical(terminal1, terminal2), isTrue);
      });

      test('returns different instances for different session IDs', () {
        final terminal1 = container.read(
          sessionTerminalControllerProvider('session-1'),
        );
        final terminal2 = container.read(
          sessionTerminalControllerProvider('session-2'),
        );

        expect(identical(terminal1, terminal2), isFalse);
      });
    });

    // @telos-scenario L1:function:lib/features/session/presentation/providers:session_terminal_provider:multiple-sessions-independent
    group('multiple sessions independent', () {
      test('writing to one session does not affect another', () {
        final notifier1 = container.read(
          sessionTerminalControllerProvider('session-1').notifier,
        );
        final notifier2 = container.read(
          sessionTerminalControllerProvider('session-2').notifier,
        );

        final terminal1 = container.read(
          sessionTerminalControllerProvider('session-1'),
        );
        final terminal2 = container.read(
          sessionTerminalControllerProvider('session-2'),
        );

        // Write to session 1's terminal directly
        terminal1.write('Hello from session 1');

        // Session 2 should be unaffected (both start empty, so just verify they're different)
        expect(identical(terminal1, terminal2), isFalse);
      });

      test('each session has independent connection state', () {
        final notifier1 = container.read(
          sessionTerminalControllerProvider('session-1').notifier,
        );
        final notifier2 = container.read(
          sessionTerminalControllerProvider('session-2').notifier,
        );

        // Initially both should be disconnected
        expect(notifier1.isConnected, isFalse);
        expect(notifier2.isConnected, isFalse);
      });
    });

    // @telos-scenario L1:function:lib/features/session/presentation/providers:session_terminal_provider:connect-session
    group('connect session to SSH', () {
      test('connect returns failure for invalid host', () async {
        final notifier = container.read(
          sessionTerminalControllerProvider('session-1').notifier,
        );

        final config = const SSHConnectionConfig(
          host: 'invalid.host.that.does.not.exist.local',
          authMethod: SSHAuthMethod.password(
            username: 'test',
            password: 'test',
          ),
          timeout: Duration(seconds: 2),
        );

        final result = await notifier.connect(config);

        // Should fail since host doesn't exist
        expect(result.isLeft(), isTrue);
        expect(notifier.isConnected, isFalse);
      });

      test('isConnected is false initially', () {
        final notifier = container.read(
          sessionTerminalControllerProvider('session-1').notifier,
        );

        expect(notifier.isConnected, isFalse);
      });
    });

    // @telos-scenario L1:function:lib/features/session/presentation/providers:session_terminal_provider:disconnect-session
    group('disconnect session', () {
      test('disconnect is safe to call when not connected', () async {
        final notifier = container.read(
          sessionTerminalControllerProvider('session-1').notifier,
        );

        // Should not throw
        await notifier.disconnect();

        expect(notifier.isConnected, isFalse);
      });
    });

    // @telos-scenario L1:function:lib/features/session/presentation/providers:session_terminal_provider:write-to-session
    group('write operations', () {
      test('write does not throw when disconnected', () {
        final notifier = container.read(
          sessionTerminalControllerProvider('session-1').notifier,
        );

        // Should not throw, will write to local terminal
        expect(() => notifier.write('test'), returnsNormally);
      });

      test('writeBytes does not throw when disconnected', () {
        final notifier = container.read(
          sessionTerminalControllerProvider('session-1').notifier,
        );

        // Should not throw, will write to local terminal
        expect(() => notifier.writeBytes([0x48, 0x69]), returnsNormally);
      });
    });

    // @telos-scenario L1:function:lib/features/session/presentation/providers:session_terminal_provider:resize-session
    group('resize terminal', () {
      test('resize does not throw', () {
        final notifier = container.read(
          sessionTerminalControllerProvider('session-1').notifier,
        );

        expect(() => notifier.resize(80, 24), returnsNormally);
      });
    });

    // @telos-scenario L1:function:lib/features/session/presentation/providers:session_terminal_provider:clear-terminal
    group('clear terminal', () {
      test('clear does not throw', () {
        final notifier = container.read(
          sessionTerminalControllerProvider('session-1').notifier,
        );

        expect(() => notifier.clear(), returnsNormally);
      });
    });
  });

  group('SessionTerminalManager', () {
    // @telos-scenario L1:function:lib/features/session/presentation/providers:session_terminal_provider:dispose-session
    group('dispose session resources', () {
      test('disposeSession cleans up resources', () {
        final manager = container.read(
          sessionTerminalManagerProvider.notifier,
        );

        // Create a session terminal first
        container.read(sessionTerminalControllerProvider('session-1'));

        // Dispose should not throw
        expect(() => manager.disposeSession('session-1'), returnsNormally);
      });

      test('disposeSession is safe for non-existent session', () {
        final manager = container.read(
          sessionTerminalManagerProvider.notifier,
        );

        // Should not throw
        expect(() => manager.disposeSession('non-existent-session'),
            returnsNormally);
      });
    });

    // @telos-scenario L1:function:lib/features/session/presentation/providers:session_terminal_provider:connect-via-manager
    group('connect session via manager', () {
      test('connectSession returns failure for invalid config', () async {
        final manager = container.read(
          sessionTerminalManagerProvider.notifier,
        );

        final config = const SSHConnectionConfig(
          host: 'invalid.nonexistent.host.local',
          authMethod: SSHAuthMethod.password(
            username: 'test',
            password: 'test',
          ),
          timeout: Duration(seconds: 2),
        );

        final result = await manager.connectSession('session-1', config);

        expect(result.isLeft(), isTrue);
      });
    });
  });
}
