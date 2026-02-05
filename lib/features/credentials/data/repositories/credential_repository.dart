// @telos L1:function:lib/features/credentials/data/repositories:credential_repository

import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../database/database.dart';
import '../../domain/entities/credential.dart';
import '../services/credential_vault.dart';

/// Repository for managing credential metadata and secure storage.
///
/// Coordinates between SQLite (metadata) and secure storage (key material).
class CredentialRepository {
  CredentialRepository({
    required BentoDatabase database,
    required CredentialVault vault,
  })  : _database = database,
        _vault = vault;

  final BentoDatabase _database;
  final CredentialVault _vault;

  /// Gets all stored credentials (metadata only).
  Future<Either<Failure, List<Credential>>> getAll() async {
    try {
      final query = _database.select(_database.credentialMetadata)
        ..orderBy([
          (t) => OrderingTerm.desc(t.lastUsedAt),
          (t) => OrderingTerm.desc(t.createdAt),
        ]);

      final rows = await query.get();
      final credentials = rows.map(_rowToEntity).toList();
      return Right(credentials);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to load credentials: $e'));
    }
  }

  /// Gets a single credential by ID.
  Future<Either<Failure, Credential?>> getById(int id) async {
    try {
      final query = _database.select(_database.credentialMetadata)
        ..where((t) => t.id.equals(id));

      final row = await query.getSingleOrNull();
      if (row == null) return const Right(null);

      return Right(_rowToEntity(row));
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to load credential: $e'));
    }
  }

  /// Saves a new credential (metadata and material).
  ///
  /// [name] is the user-friendly name.
  /// [type] is the credential type (rsa, ed25519, password).
  /// [material] is the actual credential (PEM key or password).
  /// [fingerprint] is the SSH key fingerprint (null for passwords).
  /// [passphrase] is the key passphrase if encrypted.
  /// [requiresBiometric] whether to require biometric auth.
  Future<Either<Failure, Credential>> save({
    required String name,
    required CredentialType type,
    required String material,
    String? fingerprint,
    String? passphrase,
    bool requiresBiometric = false,
    String? notes,
  }) async {
    try {
      // Generate a temporary storage key (will update after insert)
      final tempKey =
          'bento_credential_temp_${DateTime.now().millisecondsSinceEpoch}';

      final companion = CredentialMetadataCompanion(
        name: Value(name),
        type: Value(type.name),
        fingerprint: Value(fingerprint),
        storageKey: Value(tempKey),
        requiresBiometric: Value(requiresBiometric),
        notes: Value(notes),
      );

      // Insert metadata
      final id =
          await _database.into(_database.credentialMetadata).insert(companion);

      // Store credential material with actual ID
      await _vault.store(id, material);

      // Store passphrase if provided
      if (passphrase != null) {
        await _vault.storePassphrase(id, passphrase);
      }

      // Update storage key to use actual ID
      final finalStorageKey = 'bento_credential_$id';
      await (_database.update(_database.credentialMetadata)
            ..where((t) => t.id.equals(id)))
          .write(CredentialMetadataCompanion(
        storageKey: Value(finalStorageKey),
      ));

      // Return the created credential
      final result = await getById(id);
      return result.fold(
        Left.new,
        (credential) => credential != null
            ? Right(credential)
            : const Left(DatabaseFailure(
                message: 'Failed to retrieve saved credential')),
      );
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to save credential: $e'));
    }
  }

  /// Deletes a credential (metadata and material).
  Future<Either<Failure, void>> delete(int id) async {
    try {
      // Delete from secure storage
      await _vault.delete(id);

      // Delete metadata
      await (_database.delete(_database.credentialMetadata)
            ..where((t) => t.id.equals(id)))
          .go();

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to delete credential: $e'));
    }
  }

  /// Updates the last used timestamp.
  Future<Either<Failure, void>> markUsed(int id) async {
    try {
      await (_database.update(_database.credentialMetadata)
            ..where((t) => t.id.equals(id)))
          .write(CredentialMetadataCompanion(
        lastUsedAt: Value(DateTime.now()),
      ));
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to update credential: $e'));
    }
  }

  /// Updates biometric requirement for a credential.
  Future<Either<Failure, void>> setBiometric(int id,
      {required bool require}) async {
    try {
      await (_database.update(_database.credentialMetadata)
            ..where((t) => t.id.equals(id)))
          .write(CredentialMetadataCompanion(
        requiresBiometric: Value(require),
      ));
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to update credential: $e'));
    }
  }

  /// Gets the credential material from secure storage.
  Future<Either<Failure, String?>> getMaterial(int id) async {
    try {
      final material = await _vault.retrieve(id);
      return Right(material);
    } catch (e) {
      return Left(
          DatabaseFailure(message: 'Failed to retrieve credential: $e'));
    }
  }

  /// Gets the passphrase from secure storage.
  Future<Either<Failure, String?>> getPassphrase(int id) async {
    try {
      final passphrase = await _vault.retrievePassphrase(id);
      return Right(passphrase);
    } catch (e) {
      return Left(
          DatabaseFailure(message: 'Failed to retrieve passphrase: $e'));
    }
  }

  Credential _rowToEntity(CredentialMetadataEntry row) {
    return Credential(
      id: row.id,
      name: row.name,
      type: CredentialType.values.firstWhere(
        (t) => t.name == row.type,
        orElse: () => CredentialType.password,
      ),
      fingerprint: row.fingerprint,
      storageKey: row.storageKey,
      requiresBiometric: row.requiresBiometric,
      createdAt: row.createdAt,
      lastUsedAt: row.lastUsedAt,
      notes: row.notes,
    );
  }
}
