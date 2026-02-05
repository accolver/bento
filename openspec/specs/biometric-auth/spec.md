# Spec: Biometric Authentication

## ADDED Requirements

### Requirement: Biometric authentication for protected credentials

The system SHALL support biometric authentication (Face ID, Touch ID,
fingerprint) for accessing protected credentials.

#### Scenario: Access biometric-protected key

- **WHEN** accessing a credential marked as biometric-protected
- **THEN** the system prompts for biometric authentication before returning the
  credential

#### Scenario: Biometric authentication succeeds

- **WHEN** user successfully authenticates via biometrics
- **THEN** the credential is decrypted and returned

#### Scenario: Biometric authentication fails

- **WHEN** user fails biometric authentication
- **THEN** an AuthenticationFailure is returned and credential remains
  inaccessible

#### Scenario: Biometric cancelled by user

- **WHEN** user cancels the biometric prompt
- **THEN** the operation is cancelled without error

### Requirement: Device without biometrics falls back to PIN

The system SHALL fall back to device PIN/password authentication on devices
without biometric support.

#### Scenario: Device has no biometrics

- **WHEN** accessing a protected credential on a device without biometric
  hardware
- **THEN** the system uses device PIN/password authentication instead

### Requirement: Per-credential biometric setting

The system SHALL allow users to configure biometric protection per credential.

#### Scenario: Enable biometric protection on credential

- **WHEN** user enables biometric protection for a credential
- **THEN** subsequent access requires biometric authentication

#### Scenario: Disable biometric protection on credential

- **WHEN** user disables biometric protection for a credential
- **THEN** the credential can be accessed without biometric prompt

### Requirement: Biometric availability detection

The system SHALL detect biometric availability and inform the user.

#### Scenario: Check biometric availability

- **WHEN** initializing the credential vault
- **THEN** the system detects if biometrics are available and enrolled

#### Scenario: Biometrics not enrolled

- **WHEN** device supports biometrics but none are enrolled
- **THEN** the user is informed and offered to use device passcode
