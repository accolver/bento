# Capability: SSH Client

Pure Dart SSH2 client implementation using dartssh2 package.

## ADDED Requirements

### Requirement: SSH connection establishment

The system SHALL establish SSH connections to remote hosts using the dartssh2
package.

#### Scenario: Successful connection to standard port

- **WHEN** user provides valid host, port 22, and credentials
- **THEN** system establishes SSH connection and returns connected session

#### Scenario: Successful connection to custom port

- **WHEN** user provides valid host, port 2222, and credentials
- **THEN** system establishes SSH connection on specified port

#### Scenario: Connection to unreachable host

- **WHEN** user provides unreachable host address
- **THEN** system returns ConnectionFailure with host and port details

#### Scenario: Connection timeout

- **WHEN** connection attempt exceeds configured timeout (default 30 seconds)
- **THEN** system returns ConnectionFailure with timeout message

### Requirement: SSH connection configuration

The system SHALL accept connection configuration via SSHConnectionConfig entity.

#### Scenario: Configuration with all parameters

- **WHEN** SSHConnectionConfig is created with host, port, auth, terminalType,
  and timeout
- **THEN** all parameters are accessible and immutable

#### Scenario: Configuration with defaults

- **WHEN** SSHConnectionConfig is created with only host and auth
- **THEN** port defaults to 22, terminalType defaults to "xterm-256color",
  timeout defaults to 30 seconds

### Requirement: SSH connection lifecycle

The system SHALL manage the full connection lifecycle including connect,
disconnect, and state tracking.

#### Scenario: Clean disconnect

- **WHEN** user disconnects from an active session
- **THEN** system closes SSH channel and socket cleanly

#### Scenario: Connection state tracking

- **WHEN** connection state changes
- **THEN** system exposes current state (connecting, connected, disconnected,
  error)

#### Scenario: Disconnect on dispose

- **WHEN** SSHDataSource is disposed while connected
- **THEN** system automatically closes the connection

### Requirement: SSH error handling

The system SHALL map SSH errors to typed Failure classes using Either pattern.

#### Scenario: Authentication error mapping

- **WHEN** SSH server rejects authentication
- **THEN** system returns Left(AuthenticationFailure)

#### Scenario: Network error mapping

- **WHEN** network error occurs during session
- **THEN** system returns Left(ConnectionFailure) with error details

#### Scenario: Unknown error mapping

- **WHEN** unexpected error occurs
- **THEN** system returns Left(UnknownFailure) with original error preserved
