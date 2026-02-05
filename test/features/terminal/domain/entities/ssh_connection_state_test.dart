// @telos-test L1:function:lib/features/terminal/domain/entities:ssh_connection_state

import 'package:flutter_test/flutter_test.dart';
import 'package:bento/features/terminal/domain/entities/ssh_connection_state.dart';

void main() {
  group('SSHConnectionState', () {
    // @telos-scenario L1:...:ssh_connection_state:enum-values
    test('should have all expected values', () {
      // Then
      expect(SSHConnectionState.values, hasLength(4));
      expect(
          SSHConnectionState.values, contains(SSHConnectionState.disconnected));
      expect(
          SSHConnectionState.values, contains(SSHConnectionState.connecting));
      expect(SSHConnectionState.values, contains(SSHConnectionState.connected));
      expect(SSHConnectionState.values, contains(SSHConnectionState.error));
    });
  });

  group('SSHConnectionStatus', () {
    // @telos-scenario L1:...:ssh_connection_state:disconnected-status
    test('should create disconnected status', () {
      // When
      const status = SSHConnectionStatus.disconnected();

      // Then
      expect(status.state, equals(SSHConnectionState.disconnected));
      expect(status.errorMessage, isNull);
      expect(status.host, isNull);
      expect(status.port, isNull);
      expect(status.isConnected, isFalse);
      expect(status.isConnecting, isFalse);
      expect(status.hasError, isFalse);
    });

    // @telos-scenario L1:...:ssh_connection_state:connecting-status
    test('should create connecting status', () {
      // When
      const status = SSHConnectionStatus.connecting(
        host: 'example.com',
        port: 22,
      );

      // Then
      expect(status.state, equals(SSHConnectionState.connecting));
      expect(status.host, equals('example.com'));
      expect(status.port, equals(22));
      expect(status.isConnecting, isTrue);
      expect(status.isConnected, isFalse);
    });

    // @telos-scenario L1:...:ssh_connection_state:connected-status
    test('should create connected status', () {
      // When
      const status = SSHConnectionStatus.connected(
        host: 'example.com',
        port: 22,
      );

      // Then
      expect(status.state, equals(SSHConnectionState.connected));
      expect(status.host, equals('example.com'));
      expect(status.port, equals(22));
      expect(status.isConnected, isTrue);
      expect(status.isConnecting, isFalse);
    });

    // @telos-scenario L1:...:ssh_connection_state:error-status
    test('should create error status', () {
      // When
      const status = SSHConnectionStatus.error(
        errorMessage: 'Connection refused',
        host: 'example.com',
        port: 22,
      );

      // Then
      expect(status.state, equals(SSHConnectionState.error));
      expect(status.errorMessage, equals('Connection refused'));
      expect(status.hasError, isTrue);
      expect(status.isConnected, isFalse);
    });

    // @telos-scenario L1:...:ssh_connection_state:equality
    test('should support equality', () {
      // Given
      const status1 = SSHConnectionStatus.connected(host: 'a.com', port: 22);
      const status2 = SSHConnectionStatus.connected(host: 'a.com', port: 22);
      const status3 = SSHConnectionStatus.connected(host: 'b.com', port: 22);

      // Then
      expect(status1, equals(status2));
      expect(status1, isNot(equals(status3)));
    });

    // @telos-scenario L1:...:ssh_connection_state:to-string
    test('should have readable toString', () {
      // Then
      expect(
        const SSHConnectionStatus.disconnected().toString(),
        contains('disconnected'),
      );
      expect(
        const SSHConnectionStatus.connecting(host: 'a.com', port: 22)
            .toString(),
        contains('a.com:22'),
      );
      expect(
        const SSHConnectionStatus.error(errorMessage: 'test').toString(),
        contains('test'),
      );
    });
  });
}
