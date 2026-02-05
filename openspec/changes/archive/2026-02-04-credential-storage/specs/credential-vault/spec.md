# Spec: Credential Vault

## ADDED Requirements

### Requirement: CredentialVault service manages secure storage

The system SHALL provide a CredentialVault service that abstracts secure
credential storage operations.

#### Scenario: Store a credential

- **WHEN** storing a credential with a unique key
- **THEN** the credential is encrypted and saved to platform secure storage

#### Scenario: Retrieve a credential

- **WHEN** retrieving a credential by its key
- **THEN** the credential is decrypted and returned

#### Scenario: Delete a credential

- **WHEN** deleting a credential by its key
- **THEN** the credential is removed from secure storage

#### Scenario: Credential not found

- **WHEN** retrieving a non-existent credential
- **THEN** null is returned without error

### Requirement: CredentialMetadata tracks key information

The system SHALL store metadata about credentials in SQLite separate from the
credential material.

#### Scenario: Create metadata for SSH key

- **WHEN** importing or generating an SSH key
- **THEN** metadata (id, name, type, fingerprint, timestamps) is stored in
  SQLite

#### Scenario: List all credentials

- **WHEN** querying credential metadata
- **THEN** all stored credentials are returned with their metadata, without
  decrypting key material

### Requirement: Memory clearing on app background

The system SHALL clear cached credentials from memory when the app enters
background.

#### Scenario: App enters background

- **WHEN** the app lifecycle changes to paused or inactive
- **THEN** all cached credentials are zeroed out in memory

#### Scenario: App returns to foreground

- **WHEN** the app returns to foreground after credentials were cleared
- **THEN** credentials must be retrieved from secure storage again (with
  biometric if required)
