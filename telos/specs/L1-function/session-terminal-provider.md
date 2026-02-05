<!-- telos-metadata
id: L1:function:lib/features/session/presentation/providers:session_terminal_provider
level: 1
title: Session Terminal Provider
parent: L2:contract:service-session
children: []
-->

# L1: Session Terminal Provider

## Overview

Provides per-session terminal and SSH connection management using Riverpod
family providers. Each session gets its own independent Terminal instance and
SSH connection.

## Function Signatures

```dart
/// Per-session terminal controller using family pattern.
/// Each session ID gets its own isolated Terminal instance.
@Riverpod(keepAlive: true)
class SessionTerminalController extends _$SessionTerminalController {
  @override
  Terminal build(String sessionId);
  
  Future<Either<Failure, void>> connect(SSHConnectionConfig config);
  Future<void> disconnect();
  bool get isConnected;
  void write(String text);
  void resize(int cols, int rows);
}

/// Per-session block controller using family pattern.
@Riverpod(keepAlive: true) 
class SessionBlockController extends _$SessionBlockController {
  @override
  BlockListState build(String sessionId);
  
  String createBlock(String command);
  void appendOutput(String output, {String? blockId});
  Future<void> completeBlock({BlockStatus status, int? exitCode});
  // ... other block methods
}

/// Manages lifecycle of all session terminals.
/// Integrates with SessionListController.
@Riverpod(keepAlive: true)
class SessionTerminalManager extends _$SessionTerminalManager {
  @override
  void build();
  
  /// Connect a session to SSH.
  Future<Either<Failure, void>> connectSession(String sessionId, SSHConnectionConfig config);
  
  /// Disconnect a session.
  Future<void> disconnectSession(String sessionId);
  
  /// Clean up all resources for a session.
  void disposeSession(String sessionId);
}
```

## Scenarios

### Scenario: Create terminal for session

- **GIVEN** a new session ID
- **WHEN** sessionTerminalControllerProvider(sessionId) is accessed
- **THEN** a new Terminal instance is created
- **AND** terminal is configured with scrollback lines
- **AND** terminal is independent from other sessions

### Scenario: Connect session to SSH

- **GIVEN** a session with terminal
- **WHEN** connect() is called with valid config
- **THEN** SSH connection is established
- **AND** terminal I/O is wired to SSH
- **AND** session status updates to connected

### Scenario: Disconnect session

- **GIVEN** a connected session
- **WHEN** disconnect() is called
- **THEN** SSH connection is closed
- **AND** terminal remains for viewing history
- **AND** session status updates to disconnected

### Scenario: Multiple sessions independent

- **GIVEN** two sessions with terminals
- **WHEN** output is sent to session A
- **THEN** only session A's terminal shows output
- **AND** session B's terminal is unchanged

### Scenario: Session blocks isolated

- **GIVEN** two sessions with semantic blocks enabled
- **WHEN** command is run in session A
- **THEN** block is created only in session A
- **AND** session B has no new blocks

### Scenario: Dispose session resources

- **GIVEN** a session being closed
- **WHEN** disposeSession is called
- **THEN** terminal is disposed
- **AND** SSH connection is closed
- **AND** output router is cleaned up
- **AND** family provider state is invalidated

## Edge Cases

- Accessing disposed session should create fresh state
- Multiple simultaneous connects should queue
- Network interruption should update session status

## Related Specs

- L2: [Session Service](../L2-contract/service-session.md)
- L1: [Session Entity](session-entity.md)
- L1:
  [Terminal Provider](../../lib/features/terminal/presentation/providers/terminal_provider.md)
