// @telos L1:function:lib/features/credentials/data/utils:ssh_key_utils

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dartssh2/dartssh2.dart';

import '../../domain/entities/credential.dart';

/// Result of parsing a PEM-encoded SSH key.
class ParsedSSHKey {
  const ParsedSSHKey({
    required this.type,
    required this.isEncrypted,
    required this.publicKeyBase64,
    this.fingerprint,
  });

  /// The type of key (RSA, Ed25519, etc.).
  final CredentialType type;

  /// Whether the private key is encrypted with a passphrase.
  final bool isEncrypted;

  /// Base64-encoded public key (for fingerprint generation).
  final String? publicKeyBase64;

  /// SHA-256 fingerprint in hex format.
  final String? fingerprint;
}

/// Utilities for parsing, validating, and computing fingerprints of SSH keys.
class SSHKeyUtils {
  SSHKeyUtils._();

  /// PEM header markers.
  static const _rsaPrivateHeader = '-----BEGIN RSA PRIVATE KEY-----';
  static const _rsaPublicHeader = '-----BEGIN RSA PUBLIC KEY-----';
  static const _openSSHPrivateHeader = '-----BEGIN OPENSSH PRIVATE KEY-----';
  static const _encryptedHeader = '-----BEGIN ENCRYPTED PRIVATE KEY-----';
  static const _genericPrivateHeader = '-----BEGIN PRIVATE KEY-----';

  /// Encryption indicators in PEM content.
  static const _encryptedIndicators = [
    'ENCRYPTED',
    'Proc-Type: 4,ENCRYPTED',
    'DEK-Info:',
  ];

  /// Parses a PEM-encoded SSH key and extracts metadata.
  ///
  /// Returns a [ParsedSSHKey] with type, encryption status, and fingerprint.
  /// Throws [FormatException] if the key is invalid.
  static ParsedSSHKey parsePEM(String pemContent) {
    final content = pemContent.trim();

    if (content.isEmpty) {
      throw const FormatException('Empty key content');
    }

    // Detect key type from headers
    final type = _detectKeyType(content);

    // Check if encrypted
    final isEncrypted = _isEncrypted(content);

    // Try to parse and get public key for fingerprint
    String? publicKeyBase64;
    String? fingerprint;

    // Only compute fingerprint if not encrypted (can't parse without passphrase)
    if (!isEncrypted) {
      try {
        final keyPairs = SSHKeyPair.fromPem(content);
        if (keyPairs.isNotEmpty) {
          final keyPair = keyPairs.first;
          // Get the public key blob for fingerprint
          publicKeyBase64 = base64Encode(keyPair.toPublicKey().encode());
          fingerprint = computeFingerprint(keyPair.toPublicKey().encode());
        }
      } on FormatException {
        // Key parsing failed - may still be valid but unrecognized format
        rethrow;
      } catch (_) {
        // Other errors - key might be valid but we can't parse it
      }
    }

    return ParsedSSHKey(
      type: type,
      isEncrypted: isEncrypted,
      publicKeyBase64: publicKeyBase64,
      fingerprint: fingerprint,
    );
  }

  /// Validates that a PEM string is a valid SSH private key.
  ///
  /// [passphrase] is required if the key is encrypted.
  /// Returns true if the key can be parsed successfully.
  static bool validateKey(String pemContent, {String? passphrase}) {
    try {
      final keyPairs = SSHKeyPair.fromPem(pemContent, passphrase);
      return keyPairs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Detects the type of SSH key from PEM content.
  static CredentialType _detectKeyType(String content) {
    // OpenSSH format (used by Ed25519 and newer RSA keys)
    if (content.contains(_openSSHPrivateHeader)) {
      // Try to determine specific type by parsing
      try {
        final keyPairs = SSHKeyPair.fromPem(content);
        if (keyPairs.isNotEmpty) {
          final keyType = keyPairs.first.type;
          if (keyType.contains('ed25519')) {
            return CredentialType.ed25519;
          }
          if (keyType.contains('ecdsa')) {
            return CredentialType.ecdsa;
          }
          if (keyType.contains('rsa')) {
            return CredentialType.rsa;
          }
        }
      } catch (_) {
        // Can't parse - might be encrypted, default to generic
      }
      // Default for OpenSSH format if we can't determine
      return CredentialType.ed25519;
    }

    // Legacy RSA format
    if (content.contains(_rsaPrivateHeader) ||
        content.contains(_rsaPublicHeader)) {
      return CredentialType.rsa;
    }

    // Encrypted PKCS#8 format
    if (content.contains(_encryptedHeader)) {
      return CredentialType.rsa; // Typically RSA, could be others
    }

    // Generic PKCS#8 format
    if (content.contains(_genericPrivateHeader)) {
      return CredentialType.rsa; // Most commonly RSA
    }

    // Unknown format
    throw const FormatException('Unrecognized SSH key format');
  }

  /// Checks if a PEM-encoded private key is encrypted with a passphrase.
  static bool isEncrypted(String pemContent) {
    return _isEncrypted(pemContent);
  }

  static bool _isEncrypted(String content) {
    // Check for ENCRYPTED header
    if (content.contains(_encryptedHeader)) {
      return true;
    }

    // Check for encryption indicators in PEM headers
    for (final indicator in _encryptedIndicators) {
      if (content.contains(indicator)) {
        return true;
      }
    }

    // OpenSSH format encryption check
    // In OpenSSH format, encrypted keys have a different cipher in the key blob
    if (content.contains(_openSSHPrivateHeader)) {
      try {
        // Extract the base64 body
        final lines = content.split('\n');
        final bodyLines = <String>[];
        var inBody = false;

        for (final line in lines) {
          if (line.contains('-----BEGIN')) {
            inBody = true;
            continue;
          }
          if (line.contains('-----END')) {
            break;
          }
          if (inBody && line.isNotEmpty) {
            bodyLines.add(line.trim());
          }
        }

        final body = bodyLines.join();
        final decoded = base64Decode(body);

        // OpenSSH format: "openssh-key-v1\0" + ciphername
        // If ciphername is not "none", it's encrypted
        if (decoded.length > 15) {
          // Skip the auth magic and find ciphername
          // Format: "openssh-key-v1\0" + uint32(ciphername_len) + ciphername
          const magicLen = 15; // "openssh-key-v1\0"
          if (decoded.length > magicLen + 4) {
            final cipherNameLen = _readUint32(decoded, magicLen);
            if (decoded.length > magicLen + 4 + cipherNameLen) {
              final cipherName = utf8.decode(
                decoded.sublist(magicLen + 4, magicLen + 4 + cipherNameLen),
              );
              return cipherName != 'none';
            }
          }
        }
      } catch (_) {
        // Can't determine - assume not encrypted
      }
    }

    return false;
  }

  /// Reads a big-endian uint32 from bytes.
  static int _readUint32(Uint8List data, int offset) {
    return (data[offset] << 24) |
        (data[offset + 1] << 16) |
        (data[offset + 2] << 8) |
        data[offset + 3];
  }

  /// Computes the SHA-256 fingerprint of an SSH public key.
  ///
  /// [publicKeyBytes] is the raw public key blob (not base64).
  /// Returns the fingerprint in colon-separated hex format.
  static String computeFingerprint(Uint8List publicKeyBytes) {
    final digest = sha256.convert(publicKeyBytes);
    return digest.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(':')
        .toUpperCase();
  }

  /// Computes fingerprint from a base64-encoded public key.
  static String computeFingerprintFromBase64(String base64PublicKey) {
    final bytes = base64Decode(base64PublicKey);
    return computeFingerprint(Uint8List.fromList(bytes));
  }

  /// Formats a fingerprint for display (SHA256:...).
  static String formatFingerprint(String fingerprint) {
    return 'SHA256:$fingerprint';
  }

  /// Extracts the public key from a PEM private key.
  ///
  /// Returns the public key in OpenSSH format (ssh-rsa/ssh-ed25519 ...).
  /// [passphrase] is required if the private key is encrypted.
  static String? extractPublicKey(String pemContent, {String? passphrase}) {
    try {
      final keyPairs = SSHKeyPair.fromPem(pemContent, passphrase);
      if (keyPairs.isEmpty) return null;

      final keyPair = keyPairs.first;
      final publicKey = keyPair.toPublicKey();
      final encoded = base64Encode(publicKey.encode());

      // Get key type from the keypair type string
      return '${keyPair.type} $encoded';
    } catch (_) {
      return null;
    }
  }

  /// Gets the key type string from a parsed key.
  static String getKeyTypeString(CredentialType type) {
    return switch (type) {
      CredentialType.rsa => 'RSA',
      CredentialType.ed25519 => 'Ed25519',
      CredentialType.ecdsa => 'ECDSA',
      CredentialType.password => 'Password',
    };
  }

  /// Gets the key type from the algorithm name.
  static CredentialType typeFromAlgorithm(String algorithm) {
    final lower = algorithm.toLowerCase();
    if (lower.contains('ed25519')) return CredentialType.ed25519;
    if (lower.contains('ecdsa')) return CredentialType.ecdsa;
    if (lower.contains('rsa')) return CredentialType.rsa;
    return CredentialType.rsa; // Default
  }
}
