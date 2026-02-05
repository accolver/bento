// @telos L1:function:lib/database/tables:credential_metadata

import 'package:drift/drift.dart';

/// Table for storing SSH key metadata.
///
/// The actual key material is stored in flutter_secure_storage.
/// This table only stores non-sensitive metadata for listing and management.
@DataClassName('CredentialMetadataEntry')
class CredentialMetadata extends Table {
  /// Unique identifier for the credential
  IntColumn get id => integer().autoIncrement()();

  /// User-friendly name for this credential
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Type of credential: 'rsa', 'ed25519', 'password'
  TextColumn get type => text().withLength(min: 1, max: 20)();

  /// SSH key fingerprint (SHA256:base64) for identification
  /// Null for password-type credentials
  TextColumn get fingerprint => text().nullable()();

  /// Reference key for secure storage (where the actual credential is stored)
  /// Format: "bento_credential_{id}"
  TextColumn get storageKey => text()();

  /// Whether this credential requires biometric authentication to access
  BoolColumn get requiresBiometric =>
      boolean().withDefault(const Constant(false))();

  /// When this credential was created
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When this credential was last used
  DateTimeColumn get lastUsedAt => dateTime().nullable()();

  /// Optional notes about this credential
  TextColumn get notes => text().nullable()();
}
