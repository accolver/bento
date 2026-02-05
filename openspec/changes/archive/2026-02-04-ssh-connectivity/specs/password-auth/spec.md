# Capability: Password Authentication

SSH password-based authentication support.

## ADDED Requirements

### Requirement: Password authentication method

The system SHALL support password-based SSH authentication.

#### Scenario: Successful password authentication

- **WHEN** user provides valid username and password
- **THEN** system authenticates and establishes session

#### Scenario: Invalid password

- **WHEN** user provides valid username but incorrect password
- **THEN** system returns AuthenticationFailure with "Invalid credentials"
  message

#### Scenario: Invalid username

- **WHEN** user provides non-existent username
- **THEN** system returns AuthenticationFailure with "Invalid credentials"
  message

### Requirement: Password auth method type safety

The system SHALL provide type-safe SSHPasswordAuth class for password
credentials.

#### Scenario: Create password auth

- **WHEN** SSHPasswordAuth is instantiated with username and password
- **THEN** credentials are accessible via typed properties

#### Scenario: Password auth is SSHAuthMethod

- **WHEN** SSHPasswordAuth is created
- **THEN** it is a subtype of sealed SSHAuthMethod class
