# Tasks: Credential Storage

## 1. Dependencies & Setup

- [x] 1.1 Add `local_auth` package to pubspec.yaml for biometric authentication
- [x] 1.2 Add `file_picker` package to pubspec.yaml for key import
- [x] 1.3 Add `pointycastle` package to pubspec.yaml for key generation (if not
      already via dartssh2)
- [x] 1.4 Configure iOS Info.plist for Face ID usage description
- [x] 1.5 Configure Android for biometric permissions

## 2. Database Schema

- [x] 2.1 Create CredentialMetadata Drift table (id, name, type, fingerprint,
      requiresBiometric, createdAt, lastUsedAt)
- [x] 2.2 Add migration for new table
- [x] 2.3 Run code generation for Drift

## 3. Credential Vault Service

- [x] 3.1 Create CredentialVault service class with flutter_secure_storage
- [x] 3.2 Implement store(key, credential) method
- [x] 3.3 Implement retrieve(key) method
- [x] 3.4 Implement delete(key) method
- [x] 3.5 Create CredentialVaultRepository for metadata CRUD
- [x] 3.6 Create Riverpod providers for CredentialVault

## 4. Biometric Authentication

- [x] 4.1 Create BiometricService wrapper around local_auth
- [x] 4.2 Implement checkAvailability() method
- [x] 4.3 Implement authenticate(reason) method with fallback to PIN
- [x] 4.4 Integrate biometric check into CredentialVault.retrieve() for
      protected credentials
- [x] 4.5 Create Riverpod provider for BiometricService

## 5. Memory Management

- [x] 5.1 Create CredentialCache class with TTL-based expiration
- [x] 5.2 Implement WidgetsBindingObserver for app lifecycle
- [x] 5.3 Clear cached credentials on app background
      (didChangeAppLifecycleState)
- [x] 5.4 Integrate cache with CredentialVault

## 6. SSH Key Utilities

- [x] 6.1 Create SSHKeyUtils class for key parsing and validation
- [x] 6.2 Implement parsePEM(content) to detect key type and validate
- [x] 6.3 Implement computeFingerprint(publicKey) for SHA-256 fingerprint
- [x] 6.4 Implement isEncrypted(pemContent) to detect passphrase-protected keys

## 7. Key Import

- [x] 7.1 Create KeyImportScreen with file picker option
- [x] 7.2 Implement file picker integration for selecting key files
- [x] 7.3 Implement clipboard paste for key import
- [x] 7.4 Add passphrase prompt dialog for encrypted keys
- [x] 7.5 Add key naming dialog before saving
- [x] 7.6 Clear clipboard after successful import
- [x] 7.7 Add validation error handling and user feedback

## 8. Key Generation

- [x] 8.1 Create KeyGenerateScreen with type selection (Ed25519/RSA)
- [x] 8.2 Implement Ed25519 key pair generation
- [x] 8.3 Implement RSA-4096 key pair generation
- [x] 8.4 Add optional passphrase input
- [x] 8.5 Display generated public key with copy button
- [x] 8.6 Add key naming dialog before saving

## 9. UI Integration

- [x] 9.1 Add "Manage Keys" button to SSH connect screen
- [x] 9.2 Create KeyListScreen showing all stored keys
- [x] 9.3 Add key detail view with fingerprint display
- [x] 9.4 Add delete key functionality with confirmation
- [x] 9.5 Add toggle for biometric protection per key
- [x] 9.6 Integrate key selection into SSH connection flow

## 10. SSH Key Authentication

- [x] 10.1 Update SSHAuthMethod to support key authentication
- [x] 10.2 Modify SSHDataSource to use key auth when selected
- [x] 10.3 Update SSH connect screen to allow key selection
- [x] 10.4 Test key-based SSH authentication end-to-end
