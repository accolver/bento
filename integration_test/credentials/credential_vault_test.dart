// @telos-test L1:function:lib/features/credentials:credential_vault_integration
//
// Integration test for CredentialVault secure storage.
// This test requires Flutter bindings and should be run with:
//   flutter test integration_test/credentials/credential_vault_test.dart

import 'package:bento/features/credentials/data/services/credential_vault.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('CredentialVault Integration', () {
    late CredentialVault vault;

    setUp(() {
      vault = CredentialVault();
    });

    tearDown(() async {
      // Clean up test data
      await vault.delete(9999);
      await vault.delete(9998);
      vault.dispose();
    });

    // @telos-scenario L1:function:lib/features/credentials:credential_vault_integration:store-retrieve
    testWidgets('can store and retrieve credential', (tester) async {
      const testId = 9999;
      const testMaterial =
          '-----BEGIN OPENSSH PRIVATE KEY-----\ntest\n-----END OPENSSH PRIVATE KEY-----';

      // Store credential
      await vault.store(testId, testMaterial);

      // Retrieve credential
      final retrieved = await vault.retrieve(testId);

      expect(retrieved, equals(testMaterial));
    });

    // @telos-scenario L1:function:lib/features/credentials:credential_vault_integration:delete
    testWidgets('can delete credential', (tester) async {
      const testId = 9998;
      const testMaterial = 'test-credential';

      // Store then delete
      await vault.store(testId, testMaterial);
      await vault.delete(testId);

      // Should no longer exist
      final retrieved = await vault.retrieve(testId);
      expect(retrieved, isNull);
    });

    // @telos-scenario L1:function:lib/features/credentials:credential_vault_integration:passphrase-storage
    testWidgets('can store and retrieve passphrase separately', (tester) async {
      const testId = 9999;
      const testPassphrase = 'super-secret-passphrase';

      // Store passphrase
      await vault.storePassphrase(testId, testPassphrase);

      // Retrieve passphrase
      final retrieved = await vault.retrievePassphrase(testId);

      expect(retrieved, equals(testPassphrase));
    });

    // @telos-scenario L1:function:lib/features/credentials:credential_vault_integration:cache-behavior
    testWidgets('caches retrieved credentials', (tester) async {
      const testId = 9999;
      const testMaterial = 'cached-credential';

      // Store credential
      await vault.store(testId, testMaterial);

      // First retrieval populates cache
      final first = await vault.retrieve(testId);
      expect(first, equals(testMaterial));

      // Second retrieval should hit cache (faster)
      final second = await vault.retrieve(testId);
      expect(second, equals(testMaterial));
    });

    // @telos-scenario L1:function:lib/features/credentials:credential_vault_integration:cache-clear
    testWidgets('clearCache removes cached credentials', (tester) async {
      const testId = 9999;
      const testMaterial = 'to-be-cleared';

      // Store and retrieve to populate cache
      await vault.store(testId, testMaterial);
      await vault.retrieve(testId);

      // Clear cache
      vault.clearCache();

      // Should still be able to retrieve from storage
      final retrieved = await vault.retrieve(testId);
      expect(retrieved, equals(testMaterial));
    });

    // @telos-scenario L1:function:lib/features/credentials:credential_vault_integration:not-found
    testWidgets('returns null for non-existent credential', (tester) async {
      final retrieved = await vault.retrieve(99999);
      expect(retrieved, isNull);
    });

    // @telos-scenario L1:function:lib/features/credentials:credential_vault_integration:exists-check
    testWidgets('can check if credential exists', (tester) async {
      const testId = 9999;

      // Should not exist initially
      final beforeStore = await vault.exists(testId);
      expect(beforeStore, isFalse);

      // Store credential
      await vault.store(testId, 'test');

      // Should exist now
      final afterStore = await vault.exists(testId);
      expect(afterStore, isTrue);
    });
  });
}
