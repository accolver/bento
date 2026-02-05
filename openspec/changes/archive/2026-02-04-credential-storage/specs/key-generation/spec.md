# Spec: Key Generation

## ADDED Requirements

### Requirement: Generate RSA key pair

The system SHALL allow users to generate RSA-4096 key pairs.

#### Scenario: Generate RSA-4096 key

- **WHEN** user requests RSA key generation
- **THEN** a 4096-bit RSA key pair is generated locally

#### Scenario: RSA key includes public key

- **WHEN** RSA key is generated
- **THEN** both private and public key are available (public in OpenSSH format)

### Requirement: Generate Ed25519 key pair

The system SHALL allow users to generate Ed25519 key pairs.

#### Scenario: Generate Ed25519 key

- **WHEN** user requests Ed25519 key generation
- **THEN** an Ed25519 key pair is generated locally

#### Scenario: Ed25519 key includes public key

- **WHEN** Ed25519 key is generated
- **THEN** both private and public key are available (public in OpenSSH format)

### Requirement: User selects key type

The system SHALL allow users to choose between RSA and Ed25519 key types.

#### Scenario: Key type selection

- **WHEN** user initiates key generation
- **THEN** user can select between RSA-4096 and Ed25519

#### Scenario: Ed25519 recommended by default

- **WHEN** showing key type options
- **THEN** Ed25519 is recommended as the modern, faster option

### Requirement: Optional passphrase for generated key

The system SHALL allow users to optionally set a passphrase for generated keys.

#### Scenario: Generate key with passphrase

- **WHEN** user provides a passphrase during generation
- **THEN** the private key is encrypted with the passphrase

#### Scenario: Generate key without passphrase

- **WHEN** user declines to set a passphrase
- **THEN** the private key is stored unencrypted (protected by device security)

### Requirement: Display public key for copying

The system SHALL display the public key after generation for copying to servers.

#### Scenario: Copy public key

- **WHEN** key is generated
- **THEN** the public key is displayed with a copy button

#### Scenario: Public key in OpenSSH format

- **WHEN** displaying the public key
- **THEN** it is formatted in OpenSSH format (ssh-rsa/ssh-ed25519 ...)

### Requirement: User names generated key

The system SHALL prompt user to name the generated key.

#### Scenario: Name the key

- **WHEN** key is generated
- **THEN** user is prompted to provide a name before saving
