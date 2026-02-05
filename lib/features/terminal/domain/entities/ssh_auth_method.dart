// @telos L1:function:lib/features/terminal/domain/entities:ssh_auth_method

import 'package:freezed_annotation/freezed_annotation.dart';

part 'ssh_auth_method.freezed.dart';

/// Authentication method for SSH connections.
///
/// Sealed class hierarchy supporting password and key-based authentication.
/// Use pattern matching to handle different auth types.
@freezed
sealed class SSHAuthMethod with _$SSHAuthMethod {
  const SSHAuthMethod._();

  /// Password-based authentication.
  ///
  /// The most basic form of SSH authentication using username/password.
  const factory SSHAuthMethod.password({
    required String username,
    required String password,
  }) = SSHPasswordAuth;

  /// Key-based authentication.
  ///
  /// Supports RSA, Ed25519, and ECDSA private keys.
  /// Optionally includes a passphrase for encrypted keys.
  const factory SSHAuthMethod.key({
    required String username,
    required String privateKey,
    String? passphrase,
  }) = SSHKeyAuth;
}
