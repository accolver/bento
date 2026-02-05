<!-- telos-metadata
id: L1:function:lib/features/session/presentation/providers:session_controller
level: 1
title: Session Controller
parent: L2:contract:service-session
children: []
-->

# L1: Session Controller

## Overview

The SessionController manages the state of multiple terminal sessions using
Riverpod. It tracks all sessions, the active session, and provides methods for
creating, closing, switching, and updating sessions.

## Function Signatures

```dart
@Riverpod(keepAlive: true)
class SessionListController extends _$SessionListController {
  @override
  SessionListState build();

  /// Create a new session with the given connection config
  String createSession({
    required SSHConnectionConfig config,
    String? name,
  });

  /// Close and remove a session by ID
  void closeSession(String sessionId);

  /// Set the active session
  void setActiveSession(String sessionId);

  /// Update session status
  void updateSessionStatus(String sessionId, SessionStatus status);

  /// Increment unread count for a session
  void incrementUnread(String sessionId);

  /// Reset unread count for a session
  void resetUnread(String sessionId);

  /// Set running command state for a session
  void setRunningCommand(String sessionId, bool isRunning);

  /// Reorder sessions
  void reorderSessions(int oldIndex, int newIndex);

  /// Get session by ID
  Session? getSession(String sessionId);
}

@freezed
class SessionListState with _$SessionListState {
  const factory SessionListState({
    required List<Session> sessions,
    String? activeSessionId,
  }) = _SessionListState;
}
```

## Scenarios

### Scenario: Create first session

- **GIVEN** no sessions exist
- **WHEN** createSession is called with valid config
- **THEN** a new session is added to the list
- **AND** the new session becomes the active session
- **AND** session status is `connecting`

### Scenario: Create additional session

- **GIVEN** one session exists and is active
- **WHEN** createSession is called
- **THEN** a new session is added to the list
- **AND** the new session becomes the active session
- **AND** previous session remains in list

### Scenario: Close active session

- **GIVEN** multiple sessions exist with one active
- **WHEN** closeSession is called for active session
- **THEN** session is removed from list
- **AND** another session becomes active (next or previous)

### Scenario: Close last session

- **GIVEN** only one session exists
- **WHEN** closeSession is called
- **THEN** session list becomes empty
- **AND** activeSessionId becomes null

### Scenario: Switch active session

- **GIVEN** multiple sessions exist
- **WHEN** setActiveSession is called with different session ID
- **THEN** activeSessionId changes to new session
- **AND** unread count of new active session is reset

### Scenario: Update session status

- **GIVEN** a session exists
- **WHEN** updateSessionStatus is called
- **THEN** session status is updated
- **AND** other sessions remain unchanged

### Scenario: Track unread output

- **GIVEN** a background session exists
- **WHEN** incrementUnread is called
- **THEN** unreadCount increases by 1

### Scenario: Reorder sessions

- **GIVEN** sessions [A, B, C] exist
- **WHEN** reorderSessions(0, 2) is called
- **THEN** sessions become [B, C, A]

### Scenario: Max sessions limit

- **GIVEN** 10 sessions exist (soft limit)
- **WHEN** createSession is called
- **THEN** new session is created (warning only, not enforced in controller)

## Edge Cases

- Creating session with empty name uses host as name
- Closing non-existent session is a no-op
- Setting active to non-existent session is a no-op
- Session IDs are UUIDs generated internally

## Related Specs

- L2: [Session Service](../L2-contract/service-session.md)
- L1: [Session Entity](session-entity.md)
