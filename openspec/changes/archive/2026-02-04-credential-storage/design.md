# Design: Credential Storage

## Context

Bento is a mobile SSH terminal app that needs to securely store sensitive
credentials including:

- SSH passwords (already partially implemented via flutter_secure_storage)
- SSH private keys (RSA, Ed25519)
- Key passphrases

Current state:

- Basic password storage exists in `SavedConnectionsRepository` using
  `flutter_secure_storage`
- No support for SSH key authentication
- No biometric unlock
- No key import/generation features

Platform considerations:

- iOS: Keychain with Secure Enclave for biometric-protected keys
- Android: Android Keystore with BiometricPrompt

## Goals / Non-Goals

**Goals:**

- Securely store SSH private keys with AES-256 encryption at rest
- Support biometric authentication (Face ID, Touch ID, fingerprint) for key
  access
- Allow importing SSH keys from files or clipboard
- Generate new SSH key pairs (RSA-4096, Ed25519)
- Store and retrieve key passphrases securely
- Clear sensitive data from memory when app backgrounds

**Non-Goals:**

- SSH agent forwarding (separate feature)
- Hardware security key support (YubiKey, etc.)
- Cloud sync of credentials
- Key sharing between devices

## Decisions

### 1. Storage Architecture

**Decision:** Use `flutter_secure_storage` with platform keychain integration,
plus a separate CredentialVault abstraction layer.

**Rationale:**

- `flutter_secure_storage` already handles platform-specific secure storage
  (Keychain/Keystore)
- Adding a CredentialVault service provides:
  - Consistent API for different credential types
  - Memory management (clearing on background)
  - Biometric gating logic

**Alternatives considered:**

- Direct keychain/keystore access: More complex, flutter_secure_storage
  abstracts well
- Encrypted SQLite: Less secure than platform keychain, no hardware backing

### 2. Key Storage Format

**Decision:** Store keys as PEM strings in secure storage, with metadata in the
main database.

**Rationale:**

- PEM is the standard SSH key format, already supported by `dartssh2`
- Separating metadata (key name, type, fingerprint) from the key material allows
  listing keys without decrypting
- Key material never touches SQLite, only secure storage

**Storage schema:**

```
SecureStorage:
  bento_key_{id} → PEM-encoded private key
  bento_passphrase_{id} → key passphrase (if any)

SQLite (CredentialMetadata table):
  id, name, type (rsa/ed25519), fingerprint, createdAt, lastUsedAt
```

### 3. Biometric Authentication

**Decision:** Use `local_auth` package with optional biometric requirement
per-key.

**Rationale:**

- `local_auth` provides cross-platform biometric API
- Per-key biometric setting allows users to protect high-value keys while
  keeping convenience for others
- Fallback to device PIN/password for devices without biometrics

**Flow:**

1. User attempts to use a biometric-protected key
2. BiometricPrompt shown with reason
3. On success, key is decrypted and returned
4. Key cleared from memory after use (configurable timeout)

### 4. Key Import Methods

**Decision:** Support file picker and clipboard paste.

**Rationale:**

- File picker: Import from Files app, AirDrop, email attachments
- Clipboard: Quick paste from password manager or other app
- Both methods validate key format before storing

**Implementation:**

- Use `file_picker` package for file selection
- Parse PEM to validate and detect key type
- Prompt for passphrase if key is encrypted

### 5. Key Generation

**Decision:** Generate keys client-side using `pointycastle` (already a dartssh2
dependency).

**Rationale:**

- No network dependency for key generation
- User controls their keys entirely
- `pointycastle` provides RSA and Ed25519 support

**Key types:**

- RSA-4096: Maximum compatibility
- Ed25519: Modern, faster, smaller keys (recommended)

### 6. Memory Management

**Decision:** Use a CredentialCache with configurable TTL and app lifecycle
hooks.

**Rationale:**

- Keys should not persist in memory indefinitely
- Clear on app background (via WidgetsBindingObserver)
- Configurable TTL for active session use

## Risks / Trade-offs

**[Risk] Key loss on device reset** → Mitigation: Warn users to backup keys;
provide export functionality

**[Risk] Biometric bypass on rooted/jailbroken devices** → Mitigation: Detect
and warn; keys still encrypted even if biometric bypassed

**[Risk] Clipboard contains sensitive data** → Mitigation: Clear clipboard after
paste; warn user

**[Risk] Large key files from import** → Mitigation: Validate file size limits;
parse incrementally

**[Trade-off] Per-key biometric vs global** → Chose per-key for flexibility;
adds complexity but better UX

**[Trade-off] Memory clearing aggressiveness** → Chose configurable TTL; too
aggressive hurts UX, too lax hurts security
