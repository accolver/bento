# Capability: PTY Session

Interactive pseudo-terminal (PTY) session support for SSH.

## ADDED Requirements

### Requirement: PTY allocation

The system SHALL allocate a PTY for interactive shell sessions.

#### Scenario: PTY with default terminal type

- **WHEN** session is established without explicit terminal type
- **THEN** PTY is allocated with terminal type "xterm-256color"

#### Scenario: PTY with custom terminal type

- **WHEN** session config specifies terminal type "vt100"
- **THEN** PTY is allocated with terminal type "vt100"

#### Scenario: PTY allocation failure

- **WHEN** server denies PTY allocation
- **THEN** system returns ConnectionFailure with "PTY allocation failed" message

### Requirement: PTY dimensions

The system SHALL configure PTY dimensions from TerminalDimensions.

#### Scenario: Initial dimensions

- **WHEN** PTY is allocated with dimensions 80x24
- **THEN** server receives dimensions (80 columns, 24 rows)

#### Scenario: Resize dimensions

- **WHEN** terminal view resizes to 120x40
- **THEN** system sends window-change signal with new dimensions

#### Scenario: Minimum dimensions enforcement

- **WHEN** resize request specifies dimensions below minimum
- **THEN** system clamps to minimum (20 columns, 5 rows) before sending

### Requirement: Shell environment

The system SHALL configure shell environment variables.

#### Scenario: Default TERM variable

- **WHEN** session is established
- **THEN** TERM environment variable is set to terminal type

#### Scenario: Default LANG variable

- **WHEN** session is established
- **THEN** LANG environment variable is set to "en_US.UTF-8"

#### Scenario: Custom environment variables

- **WHEN** connection config includes custom environment variables
- **THEN** custom variables are set in the shell session

### Requirement: Shell startup

The system SHALL start an interactive shell after PTY allocation.

#### Scenario: Default shell

- **WHEN** session is established without shell specification
- **THEN** system requests user's default login shell

#### Scenario: Shell ready indication

- **WHEN** shell is ready for input
- **THEN** system begins streaming output to terminal
