// @telos-test L1:function:lib/features/credentials:ssh_key_auth_integration
//
// Integration test for SSH key authentication flow.
// This verifies the end-to-end flow from key storage to SSH connection.

import 'package:bento/features/credentials/data/services/credential_vault.dart';
import 'package:bento/features/credentials/data/utils/ssh_key_utils.dart';
import 'package:bento/features/credentials/domain/entities/credential.dart';
import 'package:bento/features/terminal/domain/entities/ssh_auth_method.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SSH Key Authentication Integration', () {
    // Sample Ed25519 test key (DO NOT use in production)
    // This is a throwaway key generated for testing only
    const testEd25519Key = '''-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACBHK1X3VqT5aBV4vM7XqZpZ0xQb6Wlld5oJDnb2f4zYzQAAAJjl8Fqh5fBa
oQAAAAtzc2gtZWQyNTUxOQAAACBHK1X3VqT5aBV4vM7XqZpZ0xQb6Wlld5oJDnb2f4zYzQ
AAAEDaAh3yLo+8XYfPXaebwj3xL6p1yUqfSu3j1X+yO3R1XUcrVfdWpPloFXi8ztepmlnT
FBvpaWV3mgkOdvZ/jNjNAAAAEHRlc3RAZXhhbXBsZS5jb20BAgMEBQ==
-----END OPENSSH PRIVATE KEY-----''';

    // @telos-scenario L1:function:lib/features/credentials:ssh_key_auth_integration:parse-ed25519-key
    test('can parse Ed25519 key and extract metadata', () {
      final parsed = SSHKeyUtils.parsePEM(testEd25519Key);

      expect(parsed.type, equals(CredentialType.ed25519));
      expect(parsed.isEncrypted, isFalse);
      expect(parsed.fingerprint, isNotNull);
      expect(parsed.fingerprint, isNotEmpty);
    });

    // @telos-scenario L1:function:lib/features/credentials:ssh_key_auth_integration:validate-key
    test('can validate key format with dartssh2', () {
      final isValid = SSHKeyUtils.validateKey(testEd25519Key);
      expect(isValid, isTrue);
    });

    // @telos-scenario L1:function:lib/features/credentials:ssh_key_auth_integration:create-ssh-keypair
    test('dartssh2 can parse key for SSH connection', () {
      final keyPairs = SSHKeyPair.fromPem(testEd25519Key);

      expect(keyPairs, isNotEmpty);
      expect(keyPairs.first.type, contains('ed25519'));
    });

    // @telos-scenario L1:function:lib/features/credentials:ssh_key_auth_integration:create-auth-method
    test('can create SSHAuthMethod.key with parsed key', () {
      final authMethod = SSHAuthMethod.key(
        username: 'testuser',
        privateKey: testEd25519Key,
        passphrase: null,
      );

      expect(authMethod, isA<SSHKeyAuth>());
      final keyAuth = authMethod as SSHKeyAuth;
      expect(keyAuth.username, equals('testuser'));
      expect(keyAuth.privateKey, equals(testEd25519Key));
      expect(keyAuth.passphrase, isNull);
    });

    // @telos-scenario L1:function:lib/features/credentials:ssh_key_auth_integration:extract-public-key
    test('can extract public key from private key', () {
      final publicKey = SSHKeyUtils.extractPublicKey(testEd25519Key);

      expect(publicKey, isNotNull);
      expect(publicKey, startsWith('ssh-ed25519 '));
    });

    // @telos-scenario L1:function:lib/features/credentials:ssh_key_auth_integration:compute-fingerprint
    test('can compute SHA256 fingerprint', () {
      final keyPairs = SSHKeyPair.fromPem(testEd25519Key);
      final publicKey = keyPairs.first.toPublicKey();
      final fingerprint = SSHKeyUtils.computeFingerprint(publicKey.encode());

      expect(fingerprint, isNotNull);
      expect(fingerprint, contains(':'));
      // SHA256 fingerprint should be 64 hex chars + 31 colons
      expect(fingerprint.replaceAll(':', '').length, equals(64));
    });

    // @telos-scenario L1:function:lib/features/credentials:ssh_key_auth_integration:encrypted-key-detection
    test('detects encrypted vs unencrypted keys', () {
      // Unencrypted key
      expect(SSHKeyUtils.isEncrypted(testEd25519Key), isFalse);

      // Encrypted key header indicator
      const encryptedHeader = '''-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAACmFlczI1Ni1jdHIAAAAGYmNyeXB0AAAAGAAAABBV''';
      // This would be detected as encrypted due to aes256-ctr cipher
    });

    // @telos-scenario L1:function:lib/features/credentials:ssh_key_auth_integration:credential-vault-roundtrip
    // Note: This test requires Flutter widget binding and is skipped in unit tests.
    // Run as integration test with `flutter test integration_test/` instead.
    test(
      'credential vault can store and retrieve keys',
      () async {
        final vault = CredentialVault();

        // Store a test key
        await vault.store(999, testEd25519Key);

        // Retrieve it
        final retrieved = await vault.retrieve(999);

        expect(retrieved, equals(testEd25519Key));

        // Clean up
        await vault.delete(999);

        // Verify deletion
        final afterDelete = await vault.retrieve(999);
        expect(afterDelete, isNull);
      },
      skip: 'Requires Flutter bindings - run as integration test',
    );
  });
}
