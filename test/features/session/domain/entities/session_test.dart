// @telos-test L1:function:lib/features/session/domain/entities:session

import 'package:bento/features/session/domain/entities/session.dart';
import 'package:bento/features/session/domain/entities/session_status.dart';
import 'package:bento/features/terminal/domain/entities/ssh_auth_method.dart';
import 'package:bento/features/terminal/domain/entities/ssh_connection_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Session', () {
    late SSHConnectionConfig testConfig;
    late DateTime testTime;

    setUp(() {
      testConfig = const SSHConnectionConfig(
        host: 'test.example.com',
        authMethod: SSHAuthMethod.password(
          username: 'testuser',
          password: 'testpass',
        ),
      );
      testTime = DateTime(2025, 2, 5, 10, 0, 0);
    });

    // @telos-scenario L1:function:lib/features/session/domain/entities:session:create-with-defaults
    group('create session with default values', () {
      test('status defaults to connecting', () {
        final session = Session(
          id: 'session-1',
          name: 'Test Session',
          connectionConfig: testConfig,
          createdAt: testTime,
          lastAccessedAt: testTime,
        );

        expect(session.status, equals(SessionStatus.connecting));
      });

      test('unreadCount defaults to 0', () {
        final session = Session(
          id: 'session-1',
          name: 'Test Session',
          connectionConfig: testConfig,
          createdAt: testTime,
          lastAccessedAt: testTime,
        );

        expect(session.unreadCount, equals(0));
      });

      test('hasRunningCommand defaults to false', () {
        final session = Session(
          id: 'session-1',
          name: 'Test Session',
          connectionConfig: testConfig,
          createdAt: testTime,
          lastAccessedAt: testTime,
        );

        expect(session.hasRunningCommand, isFalse);
      });

      test('createdAt and lastAccessedAt can be set independently', () {
        final createdAt = DateTime(2025, 2, 5, 10, 0, 0);
        final lastAccessed = DateTime(2025, 2, 5, 11, 30, 0);

        final session = Session(
          id: 'session-1',
          name: 'Test Session',
          connectionConfig: testConfig,
          createdAt: createdAt,
          lastAccessedAt: lastAccessed,
        );

        expect(session.createdAt, equals(createdAt));
        expect(session.lastAccessedAt, equals(lastAccessed));
      });
    });

    // @telos-scenario L1:function:lib/features/session/domain/entities:session:status-transitions
    group('session status transitions', () {
      test('copyWith creates new session with updated status', () {
        final original = Session(
          id: 'session-1',
          name: 'Test Session',
          connectionConfig: testConfig,
          status: SessionStatus.connecting,
          createdAt: testTime,
          lastAccessedAt: testTime,
        );

        final connected = original.copyWith(status: SessionStatus.connected);

        expect(connected.status, equals(SessionStatus.connected));
      });

      test('original session remains unchanged after copyWith (immutable)', () {
        final original = Session(
          id: 'session-1',
          name: 'Test Session',
          connectionConfig: testConfig,
          status: SessionStatus.connecting,
          createdAt: testTime,
          lastAccessedAt: testTime,
        );

        original.copyWith(status: SessionStatus.connected);

        expect(original.status, equals(SessionStatus.connecting));
      });

      test('can transition through all status values', () {
        var session = Session(
          id: 'session-1',
          name: 'Test Session',
          connectionConfig: testConfig,
          status: SessionStatus.connecting,
          createdAt: testTime,
          lastAccessedAt: testTime,
        );

        // connecting -> connected
        session = session.copyWith(status: SessionStatus.connected);
        expect(session.status, equals(SessionStatus.connected));

        // connected -> disconnected
        session = session.copyWith(status: SessionStatus.disconnected);
        expect(session.status, equals(SessionStatus.disconnected));

        // disconnected -> reconnecting
        session = session.copyWith(status: SessionStatus.reconnecting);
        expect(session.status, equals(SessionStatus.reconnecting));

        // reconnecting -> failed
        session = session.copyWith(status: SessionStatus.failed);
        expect(session.status, equals(SessionStatus.failed));
      });
    });

    // @telos-scenario L1:function:lib/features/session/domain/entities:session:unread-count
    group('session with unread count', () {
      test('unreadCount can be incremented via copyWith', () {
        final session = Session(
          id: 'session-1',
          name: 'Test Session',
          connectionConfig: testConfig,
          createdAt: testTime,
          lastAccessedAt: testTime,
          unreadCount: 0,
        );

        final updated = session.copyWith(unreadCount: session.unreadCount + 1);
        expect(updated.unreadCount, equals(1));
      });

      test('unreadCount can be reset to 0', () {
        final session = Session(
          id: 'session-1',
          name: 'Test Session',
          connectionConfig: testConfig,
          createdAt: testTime,
          lastAccessedAt: testTime,
          unreadCount: 5,
        );

        final reset = session.copyWith(unreadCount: 0);
        expect(reset.unreadCount, equals(0));
      });

      test('unreadCount can be set to arbitrary value', () {
        final session = Session(
          id: 'session-1',
          name: 'Test Session',
          connectionConfig: testConfig,
          createdAt: testTime,
          lastAccessedAt: testTime,
        );

        final updated = session.copyWith(unreadCount: 42);
        expect(updated.unreadCount, equals(42));
      });
    });

    // @telos-scenario L1:function:lib/features/session/domain/entities:session:equality
    group('session equality', () {
      test('two sessions with same fields are equal', () {
        final session1 = Session(
          id: 'session-1',
          name: 'Test Session',
          connectionConfig: testConfig,
          status: SessionStatus.connected,
          createdAt: testTime,
          lastAccessedAt: testTime,
          unreadCount: 0,
          hasRunningCommand: false,
        );

        final session2 = Session(
          id: 'session-1',
          name: 'Test Session',
          connectionConfig: testConfig,
          status: SessionStatus.connected,
          createdAt: testTime,
          lastAccessedAt: testTime,
          unreadCount: 0,
          hasRunningCommand: false,
        );

        expect(session1, equals(session2));
      });

      test('sessions with different ids are not equal', () {
        final session1 = Session(
          id: 'session-1',
          name: 'Test Session',
          connectionConfig: testConfig,
          createdAt: testTime,
          lastAccessedAt: testTime,
        );

        final session2 = Session(
          id: 'session-2',
          name: 'Test Session',
          connectionConfig: testConfig,
          createdAt: testTime,
          lastAccessedAt: testTime,
        );

        expect(session1, isNot(equals(session2)));
      });

      test('sessions with different status are not equal', () {
        final session1 = Session(
          id: 'session-1',
          name: 'Test Session',
          connectionConfig: testConfig,
          status: SessionStatus.connecting,
          createdAt: testTime,
          lastAccessedAt: testTime,
        );

        final session2 = Session(
          id: 'session-1',
          name: 'Test Session',
          connectionConfig: testConfig,
          status: SessionStatus.connected,
          createdAt: testTime,
          lastAccessedAt: testTime,
        );

        expect(session1, isNot(equals(session2)));
      });

      test('hashCode is consistent with equality', () {
        final session1 = Session(
          id: 'session-1',
          name: 'Test Session',
          connectionConfig: testConfig,
          createdAt: testTime,
          lastAccessedAt: testTime,
        );

        final session2 = Session(
          id: 'session-1',
          name: 'Test Session',
          connectionConfig: testConfig,
          createdAt: testTime,
          lastAccessedAt: testTime,
        );

        expect(session1.hashCode, equals(session2.hashCode));
      });
    });

    // @telos-scenario L1:function:lib/features/session/domain/entities:session:validation
    group('session validation', () {
      test('isValid returns true for valid session', () {
        final session = Session(
          id: 'session-1',
          name: 'Test Session',
          connectionConfig: testConfig,
          createdAt: testTime,
          lastAccessedAt: testTime,
        );

        expect(session.isValid, isTrue);
      });

      test('isValid returns false for empty name', () {
        final session = Session(
          id: 'session-1',
          name: '',
          connectionConfig: testConfig,
          createdAt: testTime,
          lastAccessedAt: testTime,
        );

        expect(session.isValid, isFalse);
      });

      test('isValid returns false for invalid connection config', () {
        final invalidConfig = const SSHConnectionConfig(
          host: '', // Invalid - empty host
          authMethod: SSHAuthMethod.password(
            username: 'testuser',
            password: 'testpass',
          ),
        );

        final session = Session(
          id: 'session-1',
          name: 'Test Session',
          connectionConfig: invalidConfig,
          createdAt: testTime,
          lastAccessedAt: testTime,
        );

        expect(session.isValid, isFalse);
      });
    });

    // @telos-scenario L1:function:lib/features/session/domain/entities:session:running-command
    group('hasRunningCommand', () {
      test('can be set to true', () {
        final session = Session(
          id: 'session-1',
          name: 'Test Session',
          connectionConfig: testConfig,
          createdAt: testTime,
          lastAccessedAt: testTime,
        );

        final running = session.copyWith(hasRunningCommand: true);
        expect(running.hasRunningCommand, isTrue);
      });

      test('can be toggled back to false', () {
        final session = Session(
          id: 'session-1',
          name: 'Test Session',
          connectionConfig: testConfig,
          createdAt: testTime,
          lastAccessedAt: testTime,
          hasRunningCommand: true,
        );

        final done = session.copyWith(hasRunningCommand: false);
        expect(done.hasRunningCommand, isFalse);
      });
    });

    // @telos-scenario L1:function:lib/features/session/domain/entities:session:display-name
    group('displayName', () {
      test('returns name if not empty', () {
        final session = Session(
          id: 'session-1',
          name: 'My Server',
          connectionConfig: testConfig,
          createdAt: testTime,
          lastAccessedAt: testTime,
        );

        expect(session.displayName, equals('My Server'));
      });

      test('returns host from config if name is empty', () {
        final session = Session(
          id: 'session-1',
          name: '',
          connectionConfig: testConfig,
          createdAt: testTime,
          lastAccessedAt: testTime,
        );

        expect(session.displayName, equals('test.example.com'));
      });
    });
  });

  group('SessionStatus', () {
    test('has all required values', () {
      expect(
          SessionStatus.values,
          containsAll([
            SessionStatus.connecting,
            SessionStatus.connected,
            SessionStatus.disconnected,
            SessionStatus.reconnecting,
            SessionStatus.failed,
          ]));
    });

    // @telos-scenario L1:function:lib/features/session/domain/entities:session:status-properties
    group('status properties', () {
      test('isConnected returns true only for connected status', () {
        expect(SessionStatus.connecting.isConnected, isFalse);
        expect(SessionStatus.connected.isConnected, isTrue);
        expect(SessionStatus.disconnected.isConnected, isFalse);
        expect(SessionStatus.reconnecting.isConnected, isFalse);
        expect(SessionStatus.failed.isConnected, isFalse);
      });

      test('isActive returns true for connecting states', () {
        expect(SessionStatus.connecting.isActive, isTrue);
        expect(SessionStatus.connected.isActive, isTrue);
        expect(SessionStatus.disconnected.isActive, isFalse);
        expect(SessionStatus.reconnecting.isActive, isTrue);
        expect(SessionStatus.failed.isActive, isFalse);
      });

      test('canReconnect returns true for disconnected and failed', () {
        expect(SessionStatus.connecting.canReconnect, isFalse);
        expect(SessionStatus.connected.canReconnect, isFalse);
        expect(SessionStatus.disconnected.canReconnect, isTrue);
        expect(SessionStatus.reconnecting.canReconnect, isFalse);
        expect(SessionStatus.failed.canReconnect, isTrue);
      });
    });
  });
}
