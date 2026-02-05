// @telos-test L1:function:lib/features/terminal/domain/entities:ssh_connection_config

import 'package:flutter_test/flutter_test.dart';
import 'package:bento/features/terminal/domain/entities/ssh_auth_method.dart';
import 'package:bento/features/terminal/domain/entities/ssh_connection_config.dart';

void main() {
  group('SSHConnectionConfig', () {
    // @telos-scenario L1:...:ssh_connection_config:default-values
    test('should have correct default values', () {
      // Given
      const auth = SSHAuthMethod.password(
        username: 'user',
        password: 'pass',
      );

      // When
      final config = SSHConnectionConfig(
        host: 'example.com',
        authMethod: auth,
      );

      // Then
      expect(config.host, equals('example.com'));
      expect(config.port, equals(22));
      expect(config.terminalType, equals('xterm-256color'));
      expect(config.timeout, equals(const Duration(seconds: 30)));
      expect(config.environment, isEmpty);
    });

    // @telos-scenario L1:...:ssh_connection_config:custom-values
    test('should accept custom values', () {
      // Given
      const auth = SSHAuthMethod.password(
        username: 'user',
        password: 'pass',
      );

      // When
      final config = SSHConnectionConfig(
        host: '192.168.1.1',
        authMethod: auth,
        port: 2222,
        terminalType: 'vt100',
        timeout: const Duration(seconds: 60),
        environment: const {'CUSTOM_VAR': 'value'},
      );

      // Then
      expect(config.port, equals(2222));
      expect(config.terminalType, equals('vt100'));
      expect(config.timeout, equals(const Duration(seconds: 60)));
      expect(config.environment['CUSTOM_VAR'], equals('value'));
    });

    // @telos-scenario L1:...:ssh_connection_config:validation-empty-host
    test('should fail validation with empty host', () {
      // Given
      const auth = SSHAuthMethod.password(
        username: 'user',
        password: 'pass',
      );
      final config = SSHConnectionConfig(
        host: '',
        authMethod: auth,
      );

      // When
      final errors = config.validate();

      // Then
      expect(errors, contains('Host cannot be empty'));
      expect(config.isValid, isFalse);
    });

    // @telos-scenario L1:...:ssh_connection_config:validation-invalid-port
    test('should fail validation with invalid port', () {
      // Given
      const auth = SSHAuthMethod.password(
        username: 'user',
        password: 'pass',
      );
      final config = SSHConnectionConfig(
        host: 'example.com',
        authMethod: auth,
        port: 0,
      );

      // When
      final errors = config.validate();

      // Then
      expect(errors, contains('Port must be between 1 and 65535'));
    });

    // @telos-scenario L1:...:ssh_connection_config:valid-config
    test('should pass validation with valid config', () {
      // Given
      const auth = SSHAuthMethod.password(
        username: 'user',
        password: 'pass',
      );
      final config = SSHConnectionConfig(
        host: 'example.com',
        authMethod: auth,
      );

      // When / Then
      expect(config.isValid, isTrue);
      expect(config.validate(), isEmpty);
    });
  });
}
