<!-- telos-metadata
id: L2:contract:service-session
level: 2
title: Session Service
parent: L3:experience:session-management
children:
  - L1:function:lib/features/terminal/domain/usecases:connectSession
-->

# L2: Session Service

## Overview

The Session Service manages terminal session lifecycle including connection
establishment, state persistence, reconnection, and multi-session coordination.

## Interface

### SessionService

```dart
abstract class SessionService {
  /// Create a new session and connect to host
  Future<Either<SessionFailure, Session>> createSession({
    required String hostId,
    ConnectionProtocol? preferredProtocol,
  });
  
  /// Get an existing session by ID
  Future<Either<SessionFailure, Session>> getSession(String sessionId);
  
  /// Get all active sessions
  Stream<List<Session>> watchActiveSessions();
  
  /// Reconnect a disconnected session
  Future<Either<SessionFailure, Session>> reconnect(String sessionId);
  
  /// Disconnect and close a session
  Future<Either<SessionFailure, void>> closeSession(String sessionId);
  
  /// Send input to a session's terminal
  Future<void> sendInput(String sessionId, String input);
  
  /// Send special key combination
  Future<void> sendKey(String sessionId, {
    required String key,
    bool ctrl = false,
    bool alt = false,
    bool shift = false,
  });
  
  /// Resize terminal dimensions
  Future<void> resize(String sessionId, int cols, int rows);
  
  /// Get output stream for a session
  Stream<TerminalOutput> watchOutput(String sessionId);
}
```

### Data Models

```dart
@freezed
class Session with _$Session {
  const factory Session({
    required String id,
    required String hostId,
    required String name,
    required ConnectionProtocol protocol,
    required SessionStatus status,
    required DateTime createdAt,
    required DateTime lastAccessedAt,
    String? moshState,  // For session resume
    int? cols,
    int? rows,
  }) = _Session;
}

enum SessionStatus {
  connecting,
  connected,
  disconnected,
  reconnecting,
  failed,
}

enum ConnectionProtocol { ssh, mosh }

@freezed
class TerminalOutput with _$TerminalOutput {
  const factory TerminalOutput.stdout(String data) = _Stdout;
  const factory TerminalOutput.stderr(String data) = _Stderr;
  const factory TerminalOutput.exit(int code) = _Exit;
}

@freezed
class SessionFailure with _$SessionFailure {
  const factory SessionFailure.connectionFailed(String message) = _ConnectionFailed;
  const factory SessionFailure.authenticationFailed(String message) = _AuthFailed;
  const factory SessionFailure.hostNotFound() = _HostNotFound;
  const factory SessionFailure.sessionNotFound() = _SessionNotFound;
  const factory SessionFailure.timeout() = _Timeout;
  const factory SessionFailure.networkUnavailable() = _NetworkUnavailable;
}
```

## Behavior

### Connection Protocol Selection

- Default to Mosh if available on server and enabled in host config
- Fall back to SSH if Mosh unavailable or connection fails
- Respect user preference for protocol per host

### Session Persistence

- Session metadata persisted to SQLite on creation
- Mosh state serialized on app background for resume
- Session restored on app restart, auto-reconnect attempted

### Connection Lifecycle

1. Create session record in database
2. Resolve host configuration
3. Attempt connection with preferred protocol
4. On success: update status, begin output streaming
5. On failure: update status, return error with details

### Reconnection

- Mosh sessions: attempt UDP reconnection automatically
- SSH sessions: require explicit reconnect action
- Preserve block history regardless of connection state

## Error Handling

| Error               | Behavior                                                    |
| ------------------- | ----------------------------------------------------------- |
| Network unavailable | Return `SessionFailure.networkUnavailable()`                |
| Auth failure        | Return `SessionFailure.authenticationFailed()` with details |
| Host unreachable    | Return `SessionFailure.connectionFailed()` after timeout    |
| Session not found   | Return `SessionFailure.sessionNotFound()`                   |

## Related Specs

- L3: [Session Management](../L3-experience/session-management.md)
- L3: [Incident Response](../L3-experience/incident-response.md)
- L2: [Host Service](service-host.md)
- L1: [To be defined - SSH connection functions]
- L1: [To be defined - Mosh connection functions]
