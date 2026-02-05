// @telos L1:function:lib/features/credentials/domain/entities:credential

import 'package:freezed_annotation/freezed_annotation.dart';

part 'credential.freezed.dart';
part 'credential.g.dart';

/// Type of SSH credential.
enum CredentialType {
  /// RSA private key
  rsa,

  /// Ed25519 private key
  ed25519,

  /// ECDSA private key
  ecdsa,

  /// Password credential
  password,
}

/// Represents metadata about a stored credential.
///
/// The actual credential material (key/password) is stored separately
/// in secure storage. This entity contains only non-sensitive metadata.
@freezed
class Credential with _$Credential {
  const factory Credential({
    /// Unique identifier
    required int id,

    /// User-friendly name for this credential
    required String name,

    /// Type of credential (rsa, ed25519, password)
    required CredentialType type,

    /// SSH key fingerprint (SHA256:base64) for identification
    /// Null for password-type credentials
    String? fingerprint,

    /// Reference key for secure storage
    required String storageKey,

    /// Whether this credential requires biometric authentication
    @Default(false) bool requiresBiometric,

    /// When this credential was created
    required DateTime createdAt,

    /// When this credential was last used
    DateTime? lastUsedAt,

    /// Optional notes about this credential
    String? notes,
  }) = _Credential;

  factory Credential.fromJson(Map<String, dynamic> json) =>
      _$CredentialFromJson(json);
}

/// Extension methods for Credential
extension CredentialX on Credential {
  /// Returns true if this is an SSH key (not password)
  bool get isKey =>
      type == CredentialType.rsa ||
      type == CredentialType.ed25519 ||
      type == CredentialType.ecdsa;

  /// Returns a display string for the credential type
  String get typeDisplay => switch (type) {
        CredentialType.rsa => 'RSA-4096',
        CredentialType.ed25519 => 'Ed25519',
        CredentialType.ecdsa => 'ECDSA',
        CredentialType.password => 'Password',
      };
}
