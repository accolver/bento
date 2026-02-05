<!-- telos-metadata
id: L1:function:lib/features/session/domain/entities:session
level: 1
title: Session Entity
parent: L2:contract:service-session
children: []
-->

# L1: Session Entity

## Overview

The Session entity represents a terminal session with connection state,
metadata, and lifecycle tracking. It supports multiple concurrent sessions with
status indicators.

## Function Signature

```dart
@freezed
class Session with _$Session {
  const factory Session({
    required String id,
    required String name,
    required SSHConnectionConfig connectionConfig,
    required SessionStatus status,
    required DateTime createdAt,
    required DateTime lastAccessedAt,
    @Default(0) int unreadCount,
    @Default(false) bool hasRunningCommand,
  }) = _Session;
}

enum SessionStatus {
  connecting,
  connected,
  disconnected,
  reconnecting,
  failed,
}
```

## Scenarios

### Scenario: Create session with default values

- **GIVEN** valid connection config and name
- **WHEN** Session is created
- **THEN** status is `connecting`
- **AND** unreadCount is 0
- **AND** hasRunningCommand is false
- **AND** createdAt equals lastAccessedAt

### Scenario: Session status transitions

- **GIVEN** a session in `connecting` status
- **WHEN** copyWith is called with status `connected`
- **THEN** new session has status `connected`
- **AND** original session remains unchanged (immutable)

### Scenario: Session with unread count

- **GIVEN** a connected session
- **WHEN** output is received while not active
- **THEN** unreadCount increments
- **AND** can be reset to 0 when session becomes active

### Scenario: Session equality

- **GIVEN** two sessions with same id
- **WHEN** compared for equality
- **THEN** they are equal if all fields match

### Scenario: Session validation

- **GIVEN** a session
- **WHEN** isValid is called
- **THEN** returns true if connectionConfig is valid
- **AND** name is not empty

## Edge Cases

- Session name can be auto-generated from host if not provided
- Session id should be UUID
- lastAccessedAt updates on any interaction

## Related Specs

- L2: [Session Service](../L2-contract/service-session.md)
- L2: [Tab Bar Component](../L2-contract/component-tab-bar.md)
- L1: [SSH Connection Config](session-connect-session.md)
