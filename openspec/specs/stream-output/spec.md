# Capability: Stream Output

Real-time stdout/stderr streaming from SSH sessions.

## ADDED Requirements

### Requirement: Output streaming

The system SHALL stream terminal output as a Dart Stream of Uint8List.

#### Scenario: Continuous output streaming

- **WHEN** remote command produces output
- **THEN** output is emitted on the output stream in real-time

#### Scenario: Large output handling

- **WHEN** remote command produces large output (e.g., cat large file)
- **THEN** output is streamed in chunks without blocking

#### Scenario: Stream completion on disconnect

- **WHEN** SSH session disconnects
- **THEN** output stream completes (closes)

### Requirement: Input writing

The system SHALL accept input to send to the remote shell.

#### Scenario: Write bytes to terminal

- **WHEN** write(Uint8List) is called with data
- **THEN** data is sent to the SSH channel stdin

#### Scenario: Write string to terminal

- **WHEN** writeString(String) is called
- **THEN** string is UTF-8 encoded and sent to SSH channel stdin

#### Scenario: Write while disconnected

- **WHEN** write is called on disconnected session
- **THEN** write is silently ignored (no exception)

### Requirement: Stderr handling

The system SHALL handle stderr output from the SSH session.

#### Scenario: Stderr merged with stdout

- **WHEN** remote command writes to stderr
- **THEN** stderr data is included in the output stream

#### Scenario: ANSI escape sequences preserved

- **WHEN** output includes ANSI escape sequences (colors, cursor movement)
- **THEN** sequences are passed through unmodified

### Requirement: Stream lifecycle

The system SHALL manage stream lifecycle with connection state.

#### Scenario: Stream available after connect

- **WHEN** SSH connection is established
- **THEN** output stream is available and listening

#### Scenario: Stream cleanup on close

- **WHEN** close() is called on SSHDataSource
- **THEN** output stream controller is closed and resources freed

#### Scenario: No output buffering

- **WHEN** output is received but no listeners on stream
- **THEN** output is discarded (no memory accumulation)
