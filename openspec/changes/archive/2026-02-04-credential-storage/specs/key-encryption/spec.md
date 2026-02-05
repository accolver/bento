# Spec: Key Encryption

## ADDED Requirements

### Requirement: Keys encrypted at rest with AES-256

The system SHALL encrypt all stored SSH private keys using AES-256 encryption
via platform secure storage.

#### Scenario: Store key securely

- **WHEN** storing an SSH private key
- **THEN** the key is encrypted using platform keychain (iOS) or keystore
  (Android)

#### Scenario: Retrieve encrypted key

- **WHEN** retrieving a stored key
- **THEN** the key is decrypted transparently by the platform

### Requirement: Platform keychain integration

The system SHALL use platform-native secure storage with hardware backing where
available.

#### Scenario: iOS storage

- **WHEN** storing credentials on iOS
- **THEN** iOS Keychain is used with Secure Enclave backing

#### Scenario: Android storage

- **WHEN** storing credentials on Android
- **THEN** Android Keystore is used with hardware-backed keys where available

### Requirement: Passphrase storage separate from key

The system SHALL store key passphrases separately from the key material.

#### Scenario: Store passphrase

- **WHEN** storing an encrypted key with its passphrase
- **THEN** the passphrase is stored in a separate secure storage entry

#### Scenario: Retrieve passphrase

- **WHEN** accessing an encrypted key
- **THEN** the passphrase is retrieved separately and used to decrypt the key

### Requirement: Fingerprint stored for key identification

The system SHALL compute and store the SSH key fingerprint for identification.

#### Scenario: Compute fingerprint on import

- **WHEN** importing a key
- **THEN** the SHA-256 fingerprint is computed and stored in metadata

#### Scenario: Compute fingerprint on generation

- **WHEN** generating a key
- **THEN** the SHA-256 fingerprint is computed and stored in metadata

#### Scenario: Display fingerprint

- **WHEN** viewing key details
- **THEN** the fingerprint is displayed in standard format (SHA256:base64)
