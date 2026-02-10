# Capability: TUI Mode Detection

Escape sequence monitoring to detect alternate screen buffer
activation/deactivation for full-screen TUI applications.

## ADDED Requirements

### Requirement: Detect alternate screen buffer activation

The system SHALL detect when a TUI application activates the alternate screen
buffer by monitoring for the DECSET 1049 escape sequence (`\x1b[?1049h` /
smcup).

#### Scenario: TUI application enters alternate screen mode

- **WHEN** output stream contains the byte sequence
  `[0x1B, 0x5B, 0x3F, 0x31, 0x30, 0x34, 0x39, 0x68]` (smcup)
- **THEN** TUI mode activation is signaled

#### Scenario: Sequence split across output chunks

- **WHEN** the smcup sequence is split across two consecutive output chunks
- **THEN** TUI mode activation is still detected using a small lookback buffer

#### Scenario: Detection ignores sequences in output content

- **WHEN** output contains the escape sequence as printed text (e.g., in a
  tutorial)
- **THEN** detection still triggers as terminal cannot distinguish intent

### Requirement: Detect alternate screen buffer deactivation

The system SHALL detect when a TUI application exits the alternate screen buffer
by monitoring for the DECSET 1049 reset sequence (`\x1b[?1049l` / rmcup).

#### Scenario: TUI application exits alternate screen mode

- **WHEN** output stream contains the byte sequence
  `[0x1B, 0x5B, 0x3F, 0x31, 0x30, 0x34, 0x39, 0x6C]` (rmcup)
- **THEN** TUI mode deactivation is signaled

#### Scenario: Rapid mode switches are debounced

- **WHEN** rmcup occurs within 100ms of smcup with no other output between them
- **THEN** the mode switch is treated as a no-op (false positive suppression)

### Requirement: Track TUI mode state

The system SHALL maintain a boolean state indicating whether TUI mode is
currently active.

#### Scenario: Initial state is inactive

- **WHEN** terminal session is created
- **THEN** TUI mode state is false (inactive)

#### Scenario: State transitions on smcup

- **WHEN** smcup is detected and debounce period passes
- **THEN** TUI mode state becomes true (active)

#### Scenario: State transitions on rmcup

- **WHEN** rmcup is detected while TUI mode is active
- **THEN** TUI mode state becomes false (inactive)

#### Scenario: Multiple smcup sequences are idempotent

- **WHEN** smcup is detected while TUI mode is already active
- **THEN** TUI mode state remains active (no change)

### Requirement: Notify listeners of mode changes

The system SHALL notify registered listeners when TUI mode state changes.

#### Scenario: Listener notified on activation

- **WHEN** TUI mode transitions from inactive to active
- **THEN** all registered listeners receive an activation callback with the
  triggering command if known

#### Scenario: Listener notified on deactivation

- **WHEN** TUI mode transitions from active to inactive
- **THEN** all registered listeners receive a deactivation callback

#### Scenario: No notification on same-state

- **WHEN** TUI mode state does not change (e.g., smcup while already active)
- **THEN** listeners are not notified

### Requirement: Handle disconnection during TUI mode

The system SHALL handle terminal disconnection while in TUI mode gracefully.

#### Scenario: Disconnect during TUI mode

- **WHEN** SSH session disconnects while TUI mode is active
- **THEN** TUI mode transitions to inactive
- **AND** listeners are notified of forced deactivation

### Requirement: Provide TUI mode stream

The system SHALL expose TUI mode state as a reactive stream for UI binding.

#### Scenario: Stream emits current state on subscribe

- **WHEN** a new listener subscribes to TUI mode stream
- **THEN** the current TUI mode state is immediately emitted

#### Scenario: Stream emits on state changes

- **WHEN** TUI mode state changes
- **THEN** the new state is emitted to all stream subscribers
