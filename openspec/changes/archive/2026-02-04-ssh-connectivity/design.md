# Design: SSH Connectivity

## Context

Bento requires SSH connectivity to enable users to connect to remote servers.
The existing terminal feature provides local terminal emulation with a
`TerminalRepository` interface for I/O operations. SSH connectivity extends this
to remote hosts using the dartssh2 package, a pure Dart SSH2 implementation that
ensures cross-platform compatibility without native dependencies.

**Current State:**

- `TerminalRepository` interface exists for terminal I/O
- `TerminalConfig` and `TerminalDimensions` entities handle configuration
- `ConnectionFailure` and `AuthenticationFailure` types exist in core errors
- No SSH client implementation exists yet

**Constraints:**

- Must use dartssh2 (already in pubspec.yaml)
- Must support both password and key-based authentication
- Must integrate with existing TerminalRepository interface
- Credential storage is a separate change (credential-storage) - for now,
  credentials passed at connection time

## Goals / Non-Goals

**Goals:**

- Implement SSH client wrapper using dartssh2
- Support password authentication
- Support key-based authentication (RSA, Ed25519, ECDSA)
- Create PTY sessions for interactive shells
- Stream stdout/stderr to terminal in real-time
- Handle connection lifecycle (connect, disconnect, reconnect)
- Provide typed error handling with Either pattern

**Non-Goals:**

- Credential storage/persistence (separate change: credential-storage)
- SSH agent forwarding (future enhancement)
- SFTP file operations (separate change: sftp-browser)
- Jump host/proxy support (future enhancement)
- Mosh protocol support (separate change: mosh-connectivity)

## Decisions

### D1: SSHDataSource as TerminalRepository Implementation

**Decision:** Create `SSHDataSource` that implements `TerminalRepository` and
wraps dartssh2's `SSHClient`.

**Rationale:** This allows the presentation layer to use the same interface for
local and SSH terminals. The repository pattern abstracts the connection type,
making it easy to add Mosh support later.

**Alternatives considered:**

- Direct SSHClient usage in providers: Rejected - couples presentation to SSH
  implementation
- Separate SSH-specific interface: Rejected - increases complexity without
  benefit

### D2: Authentication Strategy Pattern

**Decision:** Use an `SSHAuthMethod` sealed class hierarchy for authentication:

- `SSHPasswordAuth(username, password)`
- `SSHKeyAuth(username, privateKey, passphrase?)`

**Rationale:** Type-safe authentication handling that's extensible for future
methods (keyboard-interactive, agent). Sealed classes ensure exhaustive pattern
matching.

**Alternatives considered:**

- Union type / dynamic map: Rejected - loses type safety
- Separate connect methods per auth type: Rejected - duplicates logic

### D3: Connection Configuration Entity

**Decision:** Create `SSHConnectionConfig` freezed entity containing:

- host, port (default 22)
- authentication method
- terminal type (default "xterm-256color")
- environment variables
- connection timeout

**Rationale:** Immutable configuration simplifies state management and makes
connection parameters explicit.

**Alternatives considered:**

- Multiple parameters to connect(): Rejected - too many parameters, hard to
  extend
- Builder pattern: Overkill for this use case

### D4: Error Mapping Strategy

**Decision:** Map dartssh2 exceptions to existing failure types:

- `SSHAuthFailure` → `AuthenticationFailure`
- Socket errors → `ConnectionFailure` with host/port
- Timeout → `ConnectionFailure` with appropriate message
- Unknown → `UnknownFailure` with original error

**Rationale:** Consistent error handling across the app using the existing
failure hierarchy.

### D5: Stream-Based Output

**Decision:** Use Dart streams for terminal I/O:

- `Stream<Uint8List> output` for data from server
- `void write(Uint8List data)` for data to server
- Internal `StreamController` for output buffering

**Rationale:** Streams naturally model the continuous, async nature of terminal
I/O and integrate well with Riverpod's stream providers.

### D6: PTY Configuration

**Decision:** Configure PTY with:

- Terminal type: "xterm-256color" (most compatible)
- Dimensions from `TerminalDimensions`
- Standard environment (TERM, LANG)

**Rationale:** xterm-256color provides good compatibility with most servers
while supporting colors. Dimensions sync with the terminal view.

## Risks / Trade-offs

**[Risk] dartssh2 limitations** Pure Dart implementation may have performance
differences from native SSH.

→ Mitigation: dartssh2 is well-maintained and sufficient for interactive
terminal use. Monitor performance; native FFI is a future option if needed.

**[Risk] Key format compatibility** Different key formats (OpenSSH, PEM, PPK)
may cause issues.

→ Mitigation: Start with OpenSSH format (most common). dartssh2 handles common
formats. Add format conversion if needed.

**[Risk] Connection state management** Connections can drop unexpectedly
(network changes, server issues).

→ Mitigation: Implement connection state enum (connecting, connected,
disconnected, error). Expose state via stream for UI updates. Reconnection logic
in future iteration.

**[Risk] Memory pressure from long sessions** Long-running sessions with heavy
output could accumulate memory.

→ Mitigation: Use existing scrollback buffer limits from TerminalConfig. Stream
data directly to terminal without intermediate buffering.

## File Structure

```
lib/features/terminal/
├── data/
│   └── datasources/
│       └── ssh_datasource.dart       # SSHClient wrapper implementing TerminalRepository
├── domain/
│   ├── entities/
│   │   ├── terminal_config.dart      # Existing
│   │   └── ssh_connection_config.dart # New - connection parameters
│   └── repositories/
│       └── terminal_repository.dart  # Existing interface
└── presentation/
    └── providers/
        └── ssh_connection_provider.dart # Connection state management
```
