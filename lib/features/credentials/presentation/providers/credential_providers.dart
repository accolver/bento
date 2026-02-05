// @telos L1:function:lib/features/credentials/presentation/providers:credential_providers

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../database/database.dart';
import '../../data/repositories/credential_repository.dart';
import '../../data/services/biometric_service.dart';
import '../../data/services/credential_vault.dart';
import '../../domain/entities/credential.dart';

part 'credential_providers.g.dart';

/// Provider for BiometricService.
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// Provider for CredentialVault service.
final credentialVaultProvider = Provider<CredentialVault>((ref) {
  return CredentialVault(
    secureStorage: const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  );
});

/// Provider for CredentialRepository.
final credentialRepositoryProvider = Provider<CredentialRepository>((ref) {
  final database = ref.watch(databaseProvider);
  final vault = ref.watch(credentialVaultProvider);
  return CredentialRepository(database: database, vault: vault);
});

/// Provider for all stored credentials.
@riverpod
Future<List<Credential>> credentials(Ref ref) async {
  final repository = ref.watch(credentialRepositoryProvider);
  final result = await repository.getAll();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (credentials) => credentials,
  );
}

/// Controller for credential operations.
@riverpod
class CredentialController extends _$CredentialController {
  @override
  FutureOr<void> build() {
    // Initial state - nothing to do
  }

  /// Saves a new credential.
  Future<Credential?> saveCredential({
    required String name,
    required CredentialType type,
    required String material,
    String? fingerprint,
    String? passphrase,
    bool requiresBiometric = false,
    String? notes,
  }) async {
    final repository = ref.read(credentialRepositoryProvider);
    final result = await repository.save(
      name: name,
      type: type,
      material: material,
      fingerprint: fingerprint,
      passphrase: passphrase,
      requiresBiometric: requiresBiometric,
      notes: notes,
    );

    return result.fold(
      (failure) => null,
      (credential) {
        ref.invalidate(credentialsProvider);
        return credential;
      },
    );
  }

  /// Deletes a credential.
  Future<bool> deleteCredential(int id) async {
    final repository = ref.read(credentialRepositoryProvider);
    final result = await repository.delete(id);

    return result.fold(
      (failure) => false,
      (_) {
        ref.invalidate(credentialsProvider);
        return true;
      },
    );
  }

  /// Updates biometric requirement for a credential.
  Future<bool> setBiometric(int id, {required bool require}) async {
    final repository = ref.read(credentialRepositoryProvider);
    final result = await repository.setBiometric(id, require: require);

    return result.fold(
      (failure) => false,
      (_) {
        ref.invalidate(credentialsProvider);
        return true;
      },
    );
  }

  /// Gets the credential material.
  Future<String?> getMaterial(int id) async {
    final repository = ref.read(credentialRepositoryProvider);
    final result = await repository.getMaterial(id);
    return result.fold(
      (failure) => null,
      (material) => material,
    );
  }

  /// Gets the passphrase for a credential.
  Future<String?> getPassphrase(int id) async {
    final repository = ref.read(credentialRepositoryProvider);
    final result = await repository.getPassphrase(id);
    return result.fold(
      (failure) => null,
      (passphrase) => passphrase,
    );
  }

  /// Marks a credential as used.
  Future<void> markUsed(int id) async {
    final repository = ref.read(credentialRepositoryProvider);
    await repository.markUsed(id);
    ref.invalidate(credentialsProvider);
  }

  /// Gets credential material with biometric authentication if required.
  ///
  /// Returns the decrypted credential material, or null if auth failed.
  Future<String?> getSecureMaterial(Credential credential) async {
    // If biometric required, authenticate first
    if (credential.requiresBiometric) {
      final biometricService = ref.read(biometricServiceProvider);
      final authResult = await biometricService.authenticate(
        reason: 'Authenticate to access "${credential.name}"',
      );

      final authenticated = authResult.fold(
        (failure) => false,
        (success) => success,
      );

      if (!authenticated) {
        return null;
      }
    }

    // Get the material
    return getMaterial(credential.id);
  }
}
