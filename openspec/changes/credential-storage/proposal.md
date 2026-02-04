# Proposal: Credential Storage

## Why

SSH private keys are sensitive credentials that must be stored securely. Using
flutter_secure_storage with platform keychain integration ensures keys are
encrypted at rest. Biometric authentication (Face ID, Touch ID, fingerprint)
provides secure access without password fatigue, making the app both secure and
convenient.

## What Changes

- Integrate flutter_secure_storage for encrypted storage
- Integrate local_auth for biometric authentication
- Implement CredentialVault service class
- Store SSH private keys with AES-256 encryption
- Implement biometric unlock for key access
- Add key import from file picker or clipboard
- Add key generation capability (RSA, Ed25519)
- Implement key passphrase storage
- Clear keys from memory on app background

## Capabilities

### New Capabilities

- `credential-vault`: Secure key storage service
- `biometric-auth`: Face ID/Touch ID/fingerprint
- `key-import`: Import keys from files
- `key-generation`: Generate new SSH keys
- `key-encryption`: AES-256 at rest

## Impact

- `lib/features/connections/data/services/credential_vault.dart`: Vault service
- `lib/features/connections/presentation/screens/key_import_screen.dart`: Import
  UI
- `lib/features/connections/presentation/screens/key_generate_screen.dart`:
  Generate UI

## Dependencies

- `scaffold-flutter-project`: Requires Flutter project structure

## Phase

**Phase 1 - MVP** (Weeks 5-6, parallel with ssh-connectivity)

## Priority

**P0 - Must Have**
