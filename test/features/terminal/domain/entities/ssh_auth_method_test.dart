// @telos-test L1:function:lib/features/terminal/domain/entities:ssh_auth_method

import 'package:flutter_test/flutter_test.dart';
import 'package:bento/features/terminal/domain/entities/ssh_auth_method.dart';

void main() {
  group('SSHPasswordAuth', () {
    // @telos-scenario L1:...:ssh_auth_method:password-auth-creation
    test('should create with username and password', () {
      // Given / When
      const auth = SSHAuthMethod.password(
        username: 'testuser',
        password: 'testpass',
      );

      // Then
      expect(auth, isA<SSHPasswordAuth>());
      final passwordAuth = auth as SSHPasswordAuth;
      expect(passwordAuth.username, equals('testuser'));
      expect(passwordAuth.password, equals('testpass'));
    });

    // @telos-scenario L1:...:ssh_auth_method:password-auth-equality
    test('should be equal when properties match', () {
      // Given
      const auth1 = SSHAuthMethod.password(
        username: 'user',
        password: 'pass',
      );
      const auth2 = SSHAuthMethod.password(
        username: 'user',
        password: 'pass',
      );

      // Then
      expect(auth1, equals(auth2));
    });

    // @telos-scenario L1:...:ssh_auth_method:password-auth-pattern-matching
    test('should work with pattern matching', () {
      // Given
      const SSHAuthMethod auth = SSHAuthMethod.password(
        username: 'user',
        password: 'pass',
      );

      // When
      final result = switch (auth) {
        SSHPasswordAuth(:final username) => username,
        SSHKeyAuth() => 'key',
      };

      // Then
      expect(result, equals('user'));
    });
  });

  group('SSHKeyAuth', () {
    // @telos-scenario L1:...:ssh_auth_method:key-auth-without-passphrase
    test('should create without passphrase', () {
      // Given / When
      const auth = SSHAuthMethod.key(
        username: 'testuser',
        privateKey:
            '-----BEGIN OPENSSH PRIVATE KEY-----\ntest\n-----END OPENSSH PRIVATE KEY-----',
      );

      // Then
      expect(auth, isA<SSHKeyAuth>());
      final keyAuth = auth as SSHKeyAuth;
      expect(keyAuth.username, equals('testuser'));
      expect(keyAuth.privateKey, contains('OPENSSH PRIVATE KEY'));
      expect(keyAuth.passphrase, isNull);
    });

    // @telos-scenario L1:...:ssh_auth_method:key-auth-with-passphrase
    test('should create with passphrase', () {
      // Given / When
      const auth = SSHAuthMethod.key(
        username: 'testuser',
        privateKey:
            '-----BEGIN OPENSSH PRIVATE KEY-----\ntest\n-----END OPENSSH PRIVATE KEY-----',
        passphrase: 'mypassphrase',
      );

      // Then
      expect(auth, isA<SSHKeyAuth>());
      final keyAuth = auth as SSHKeyAuth;
      expect(keyAuth.passphrase, equals('mypassphrase'));
    });

    // @telos-scenario L1:...:ssh_auth_method:key-auth-pattern-matching
    test('should work with pattern matching', () {
      // Given
      const SSHAuthMethod auth = SSHAuthMethod.key(
        username: 'user',
        privateKey: 'key',
        passphrase: 'phrase',
      );

      // When
      final result = switch (auth) {
        SSHPasswordAuth() => 'password',
        SSHKeyAuth(:final passphrase) => passphrase ?? 'none',
      };

      // Then
      expect(result, equals('phrase'));
    });
  });
}
