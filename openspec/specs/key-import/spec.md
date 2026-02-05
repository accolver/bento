# Spec: Key Import

## ADDED Requirements

### Requirement: Import SSH key from file

The system SHALL allow users to import SSH private keys from files.

#### Scenario: Import unencrypted PEM key file

- **WHEN** user selects a valid PEM private key file
- **THEN** the key is parsed, validated, and stored securely

#### Scenario: Import encrypted PEM key file

- **WHEN** user selects an encrypted PEM private key file
- **THEN** the system prompts for passphrase, decrypts for validation, and
  stores both key and passphrase

#### Scenario: Import invalid key file

- **WHEN** user selects a file that is not a valid SSH private key
- **THEN** an error is shown explaining the file format is invalid

#### Scenario: Import public key file (reject)

- **WHEN** user selects a public key file (.pub)
- **THEN** an error is shown explaining that private keys are required

### Requirement: Import SSH key from clipboard

The system SHALL allow users to paste SSH private keys from clipboard.

#### Scenario: Paste valid PEM key

- **WHEN** user pastes valid PEM-formatted key content
- **THEN** the key is parsed, validated, and stored securely

#### Scenario: Paste encrypted key

- **WHEN** user pastes an encrypted PEM key
- **THEN** the system prompts for passphrase before storing

#### Scenario: Paste invalid content

- **WHEN** user pastes content that is not a valid SSH key
- **THEN** an error is shown explaining the format is invalid

### Requirement: Clear clipboard after key import

The system SHALL clear the clipboard after successfully importing a key from it.

#### Scenario: Successful clipboard import

- **WHEN** key is successfully imported from clipboard
- **THEN** the clipboard is cleared to prevent key exposure

### Requirement: Detect key type on import

The system SHALL automatically detect the key type (RSA, Ed25519, etc.) during
import.

#### Scenario: Import RSA key

- **WHEN** importing an RSA private key
- **THEN** the key is identified as type "rsa" in metadata

#### Scenario: Import Ed25519 key

- **WHEN** importing an Ed25519 private key
- **THEN** the key is identified as type "ed25519" in metadata

### Requirement: User names imported key

The system SHALL prompt user to name the imported key.

#### Scenario: Name the key

- **WHEN** key is validated and ready to store
- **THEN** user is prompted to provide a name for the key
