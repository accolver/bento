// @telos-test L1:function:lib/features/session/presentation/providers:session_controller

import 'package:bento/features/session/domain/entities/session.dart';
import 'package:bento/features/session/domain/entities/session_status.dart';
import 'package:bento/features/session/presentation/providers/session_list_controller.dart';
import 'package:bento/features/terminal/domain/entities/ssh_auth_method.dart';
import 'package:bento/features/terminal/domain/entities/ssh_connection_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  late SSHConnectionConfig testConfig;
  late SSHConnectionConfig testConfig2;

  setUp(() {
    container = ProviderContainer();
    testConfig = const SSHConnectionConfig(
      host: 'server1.example.com',
      authMethod: SSHAuthMethod.password(
        username: 'user1',
        password: 'pass1',
      ),
    );
    testConfig2 = const SSHConnectionConfig(
      host: 'server2.example.com',
      authMethod: SSHAuthMethod.password(
        username: 'user2',
        password: 'pass2',
      ),
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('SessionListController', () {
    // @telos-scenario L1:function:lib/features/session/presentation/providers:session_controller:initial-state
    group('initial state', () {
      test('starts with empty session list', () {
        final state = container.read(sessionListControllerProvider);

        expect(state.sessions, isEmpty);
      });

      test('starts with null activeSessionId', () {
        final state = container.read(sessionListControllerProvider);

        expect(state.activeSessionId, isNull);
      });
    });

    // @telos-scenario L1:function:lib/features/session/presentation/providers:session_controller:create-first-session
    group('create first session', () {
      test('adds session to list', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        controller.createSession(config: testConfig, name: 'Server 1');

        final state = container.read(sessionListControllerProvider);
        expect(state.sessions, hasLength(1));
      });

      test('new session becomes active', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        final sessionId =
            controller.createSession(config: testConfig, name: 'Server 1');

        final state = container.read(sessionListControllerProvider);
        expect(state.activeSessionId, equals(sessionId));
      });

      test('new session has connecting status', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        controller.createSession(config: testConfig, name: 'Server 1');

        final state = container.read(sessionListControllerProvider);
        expect(state.sessions.first.status, equals(SessionStatus.connecting));
      });

      test('new session has correct name', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        controller.createSession(config: testConfig, name: 'My Server');

        final state = container.read(sessionListControllerProvider);
        expect(state.sessions.first.name, equals('My Server'));
      });

      test('uses host as name when name not provided', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        controller.createSession(config: testConfig);

        final state = container.read(sessionListControllerProvider);
        expect(state.sessions.first.name, equals('server1.example.com'));
      });
    });

    // @telos-scenario L1:function:lib/features/session/presentation/providers:session_controller:create-additional-session
    group('create additional session', () {
      test('adds session to end of list', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        controller.createSession(config: testConfig, name: 'Server 1');
        controller.createSession(config: testConfig2, name: 'Server 2');

        final state = container.read(sessionListControllerProvider);
        expect(state.sessions, hasLength(2));
        expect(state.sessions[1].name, equals('Server 2'));
      });

      test('new session becomes active', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        controller.createSession(config: testConfig, name: 'Server 1');
        final session2Id =
            controller.createSession(config: testConfig2, name: 'Server 2');

        final state = container.read(sessionListControllerProvider);
        expect(state.activeSessionId, equals(session2Id));
      });

      test('previous session remains in list', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        final session1Id =
            controller.createSession(config: testConfig, name: 'Server 1');
        controller.createSession(config: testConfig2, name: 'Server 2');

        final state = container.read(sessionListControllerProvider);
        expect(state.sessions.any((s) => s.id == session1Id), isTrue);
      });
    });

    // @telos-scenario L1:function:lib/features/session/presentation/providers:session_controller:close-active-session
    group('close active session', () {
      test('removes session from list', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        final sessionId =
            controller.createSession(config: testConfig, name: 'Server 1');
        controller.createSession(config: testConfig2, name: 'Server 2');
        controller.closeSession(sessionId);

        final state = container.read(sessionListControllerProvider);
        expect(state.sessions.any((s) => s.id == sessionId), isFalse);
        expect(state.sessions, hasLength(1));
      });

      test('next session becomes active when closing first', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        final session1Id =
            controller.createSession(config: testConfig, name: 'Server 1');
        final session2Id =
            controller.createSession(config: testConfig2, name: 'Server 2');
        controller.setActiveSession(session1Id);
        controller.closeSession(session1Id);

        final state = container.read(sessionListControllerProvider);
        expect(state.activeSessionId, equals(session2Id));
      });

      test('previous session becomes active when closing last', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        final session1Id =
            controller.createSession(config: testConfig, name: 'Server 1');
        final session2Id =
            controller.createSession(config: testConfig2, name: 'Server 2');
        // session2 is active (last created)
        controller.closeSession(session2Id);

        final state = container.read(sessionListControllerProvider);
        expect(state.activeSessionId, equals(session1Id));
      });
    });

    // @telos-scenario L1:function:lib/features/session/presentation/providers:session_controller:close-last-session
    group('close last session', () {
      test('session list becomes empty', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        final sessionId =
            controller.createSession(config: testConfig, name: 'Server 1');
        controller.closeSession(sessionId);

        final state = container.read(sessionListControllerProvider);
        expect(state.sessions, isEmpty);
      });

      test('activeSessionId becomes null', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        final sessionId =
            controller.createSession(config: testConfig, name: 'Server 1');
        controller.closeSession(sessionId);

        final state = container.read(sessionListControllerProvider);
        expect(state.activeSessionId, isNull);
      });
    });

    // @telos-scenario L1:function:lib/features/session/presentation/providers:session_controller:switch-active-session
    group('switch active session', () {
      test('changes activeSessionId', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        final session1Id =
            controller.createSession(config: testConfig, name: 'Server 1');
        controller.createSession(config: testConfig2, name: 'Server 2');
        controller.setActiveSession(session1Id);

        final state = container.read(sessionListControllerProvider);
        expect(state.activeSessionId, equals(session1Id));
      });

      test('resets unread count of new active session', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        final session1Id =
            controller.createSession(config: testConfig, name: 'Server 1');
        controller.createSession(config: testConfig2, name: 'Server 2');

        // Add some unread to session1 while session2 is active
        controller.incrementUnread(session1Id);
        controller.incrementUnread(session1Id);

        // Verify session1 has unread
        var state = container.read(sessionListControllerProvider);
        expect(state.sessions.firstWhere((s) => s.id == session1Id).unreadCount,
            equals(2));

        // Switch to session1
        controller.setActiveSession(session1Id);

        state = container.read(sessionListControllerProvider);
        expect(state.sessions.firstWhere((s) => s.id == session1Id).unreadCount,
            equals(0));
      });

      test('setting to non-existent session is no-op', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        final sessionId =
            controller.createSession(config: testConfig, name: 'Server 1');
        controller.setActiveSession('non-existent-id');

        final state = container.read(sessionListControllerProvider);
        expect(state.activeSessionId, equals(sessionId));
      });
    });

    // @telos-scenario L1:function:lib/features/session/presentation/providers:session_controller:update-session-status
    group('update session status', () {
      test('updates status of specified session', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        final sessionId =
            controller.createSession(config: testConfig, name: 'Server 1');
        controller.updateSessionStatus(sessionId, SessionStatus.connected);

        final state = container.read(sessionListControllerProvider);
        expect(state.sessions.first.status, equals(SessionStatus.connected));
      });

      test('other sessions remain unchanged', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        final session1Id =
            controller.createSession(config: testConfig, name: 'Server 1');
        controller.createSession(config: testConfig2, name: 'Server 2');
        controller.updateSessionStatus(session1Id, SessionStatus.connected);

        final state = container.read(sessionListControllerProvider);
        final session2 = state.sessions.firstWhere((s) => s.id != session1Id);
        expect(session2.status, equals(SessionStatus.connecting));
      });

      test('updating non-existent session is no-op', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        controller.createSession(config: testConfig, name: 'Server 1');
        controller.updateSessionStatus(
            'non-existent-id', SessionStatus.connected);

        final state = container.read(sessionListControllerProvider);
        expect(state.sessions.first.status, equals(SessionStatus.connecting));
      });
    });

    // @telos-scenario L1:function:lib/features/session/presentation/providers:session_controller:track-unread
    group('track unread output', () {
      test('incrementUnread increases count by 1', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        final sessionId =
            controller.createSession(config: testConfig, name: 'Server 1');
        controller.incrementUnread(sessionId);

        final state = container.read(sessionListControllerProvider);
        expect(state.sessions.first.unreadCount, equals(1));
      });

      test('multiple increments accumulate', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        final sessionId =
            controller.createSession(config: testConfig, name: 'Server 1');
        controller.incrementUnread(sessionId);
        controller.incrementUnread(sessionId);
        controller.incrementUnread(sessionId);

        final state = container.read(sessionListControllerProvider);
        expect(state.sessions.first.unreadCount, equals(3));
      });

      test('resetUnread sets count to 0', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        final sessionId =
            controller.createSession(config: testConfig, name: 'Server 1');
        controller.incrementUnread(sessionId);
        controller.incrementUnread(sessionId);
        controller.resetUnread(sessionId);

        final state = container.read(sessionListControllerProvider);
        expect(state.sessions.first.unreadCount, equals(0));
      });
    });

    // @telos-scenario L1:function:lib/features/session/presentation/providers:session_controller:running-command
    group('running command state', () {
      test('setRunningCommand to true', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        final sessionId =
            controller.createSession(config: testConfig, name: 'Server 1');
        controller.setRunningCommand(sessionId, true);

        final state = container.read(sessionListControllerProvider);
        expect(state.sessions.first.hasRunningCommand, isTrue);
      });

      test('setRunningCommand to false', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        final sessionId =
            controller.createSession(config: testConfig, name: 'Server 1');
        controller.setRunningCommand(sessionId, true);
        controller.setRunningCommand(sessionId, false);

        final state = container.read(sessionListControllerProvider);
        expect(state.sessions.first.hasRunningCommand, isFalse);
      });
    });

    // @telos-scenario L1:function:lib/features/session/presentation/providers:session_controller:reorder-sessions
    group('reorder sessions', () {
      test('move first to last', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        final session1Id =
            controller.createSession(config: testConfig, name: 'A');
        controller.createSession(config: testConfig, name: 'B');
        controller.createSession(config: testConfig, name: 'C');

        controller.reorderSessions(0, 2);

        final state = container.read(sessionListControllerProvider);
        expect(state.sessions.map((s) => s.name).toList(),
            equals(['B', 'C', 'A']));
      });

      test('move last to first', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        controller.createSession(config: testConfig, name: 'A');
        controller.createSession(config: testConfig, name: 'B');
        controller.createSession(config: testConfig, name: 'C');

        controller.reorderSessions(2, 0);

        final state = container.read(sessionListControllerProvider);
        expect(state.sessions.map((s) => s.name).toList(),
            equals(['C', 'A', 'B']));
      });

      test('preserves active session', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        controller.createSession(config: testConfig, name: 'A');
        final session2Id =
            controller.createSession(config: testConfig, name: 'B');
        controller.createSession(config: testConfig, name: 'C');
        controller.setActiveSession(session2Id);

        controller.reorderSessions(0, 2);

        final state = container.read(sessionListControllerProvider);
        expect(state.activeSessionId, equals(session2Id));
      });
    });

    // @telos-scenario L1:function:lib/features/session/presentation/providers:session_controller:get-session
    group('getSession', () {
      test('returns session by ID', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        final sessionId =
            controller.createSession(config: testConfig, name: 'Server 1');

        final session = controller.getSession(sessionId);

        expect(session, isNotNull);
        expect(session!.id, equals(sessionId));
        expect(session.name, equals('Server 1'));
      });

      test('returns null for non-existent ID', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        controller.createSession(config: testConfig, name: 'Server 1');

        final session = controller.getSession('non-existent');

        expect(session, isNull);
      });
    });

    // @telos-scenario L1:function:lib/features/session/presentation/providers:session_controller:active-session-getter
    group('activeSession getter', () {
      test('returns active session', () {
        final controller =
            container.read(sessionListControllerProvider.notifier);

        controller.createSession(config: testConfig, name: 'Server 1');

        final state = container.read(sessionListControllerProvider);
        expect(state.activeSession, isNotNull);
        expect(state.activeSession!.name, equals('Server 1'));
      });

      test('returns null when no sessions', () {
        final state = container.read(sessionListControllerProvider);
        expect(state.activeSession, isNull);
      });
    });
  });
}
