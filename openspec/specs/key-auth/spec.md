# Capability: Key Authentication

SSH key-based authentication support for RSA, Ed25519, and ECDSA keys.

## ADDED Requirements

### Requirement: Private key authentication

The system SHALL support authentication using SSH private keys.

#### Scenario: Successful RSA key authentication

- **WHEN** user provides valid RSA private key and username
- **THEN** system authenticates using the key and establishes session

#### Scenario: Successful Ed25519 key authentication

- **WHEN** user provides valid Ed25519 private key and username
- **THEN** system authenticates using the key and establishes session

#### Scenario: Successful ECDSA key authentication

- **WHEN** user provides valid ECDSA private key and username
- **THEN** system authenticates using the key and establishes session

#### Scenario: Invalid key format

- **WHEN** user provides malformed private key
- **THEN** system returns AuthenticationFailure with "Invalid key format"
  message

#### Scenario: Key not accepted by server

- **WHEN** user provides valid key not in server's authorized_keys
- **THEN** system returns AuthenticationFailure with "Key not authorized"
  message

### Requirement: Encrypted key passphrase

The system SHALL support passphrase-protected private keys.

#### Scenario: Correct passphrase for encrypted key

- **WHEN** user provides encrypted key with correct passphrase
- **THEN** system decrypts key and authenticates successfully

#### Scenario: Incorrect passphrase for encrypted key

- **WHEN** user provides encrypted key with incorrect passphrase
- **THEN** system returns AuthenticationFailure with "Invalid passphrase"
  message

#### Scenario: Missing passphrase for encrypted key

- **WHEN** user provides encrypted key without passphrase
- **THEN** system returns AuthenticationFailure with "Passphrase required"
  message

### Requirement: Key auth method type safety

The system SHALL provide type-safe SSHKeyAuth class for key credentials.

#### Scenario: Create key auth without passphrase

- **WHEN** SSHKeyAuth is instantiated with username and privateKey
- **THEN** credentials are accessible, passphrase is null

#### Scenario: Create key auth with passphrase

- **WHEN** SSHKeyAuth is instantiated with username, privateKey, and passphrase
- **THEN** all credentials including passphrase are accessible

#### Scenario: Key auth is SSHAuthMethod

- **WHEN** SSHKeyAuth is created
- **THEN** it is a subtype of sealed SSHAuthMethod class
