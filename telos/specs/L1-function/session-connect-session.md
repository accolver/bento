<!-- telos-metadata
id: L1:function:lib/features/terminal/domain/usecases:connectSession
level: 1
title: connectSession
parent: L2:contract:service-session
-->

# L1: connectSession

## Purpose

Establishes a terminal connection to a remote host using either SSH or Mosh
protocol, handling authentication, protocol selection, and connection state
management.

## Signature

```dart
Future<Either<SessionFailure, Session>> connectSession({
  required String hostId,
  ConnectionProtocol? preferredProtocol,
  int? cols,
  int? rows,
});
```

## Parameters

| Name              | Type                | Description                                    |
| ----------------- | ------------------- | ---------------------------------------------- |
| hostId            | String              | ID of the host configuration to connect to     |
| preferredProtocol | ConnectionProtocol? | Override default protocol selection (ssh/mosh) |
| cols              | int?                | Terminal columns (default: 80)                 |
| rows              | int?                | Terminal rows (default: 24)                    |

## Returns

| Type                            | Description                                              |
| ------------------------------- | -------------------------------------------------------- |
| Either<SessionFailure, Session> | Right(Session) on success, Left(SessionFailure) on error |

## TDD Scenarios

### Scenario: Successful SSH connection

```gherkin
Given a valid host configuration exists with hostId "host-123"
And the host has SSH credentials stored securely
And the remote server is reachable
When connectSession is called with hostId "host-123"
Then a new Session is created with status "connected"
And the session protocol is "ssh"
And the session is persisted to the database
And Right(session) is returned
```

### Scenario: Successful Mosh connection

```gherkin
Given a valid host configuration exists with hostId "host-456"
And the host has useMosh enabled
And the remote server supports Mosh
And network conditions are unstable
When connectSession is called with hostId "host-456"
Then a new Session is created with status "connected"
And the session protocol is "mosh"
And moshState is initialized for session resume
And Right(session) is returned
```

### Scenario: Fallback from Mosh to SSH

```gherkin
Given a valid host configuration exists with hostId "host-789"
And the host has useMosh enabled
And the remote server does not have Mosh installed
When connectSession is called with hostId "host-789"
Then Mosh connection is attempted first
And Mosh connection fails with "mosh-server not found"
Then SSH connection is attempted as fallback
And a new Session is created with protocol "ssh"
And Right(session) is returned
```

### Scenario: Authentication failure

```gherkin
Given a valid host configuration exists with hostId "host-auth-fail"
And the stored SSH key is invalid or revoked
When connectSession is called with hostId "host-auth-fail"
Then connection attempt fails with authentication error
And Left(SessionFailure.authenticationFailed) is returned
And the failure message contains "Authentication failed"
```

### Scenario: Host not found

```gherkin
Given no host configuration exists with hostId "nonexistent-host"
When connectSession is called with hostId "nonexistent-host"
Then Left(SessionFailure.hostNotFound) is returned
And no connection attempt is made
```

### Scenario: Network unreachable

```gherkin
Given a valid host configuration exists with hostId "host-offline"
And the device has no network connectivity
When connectSession is called with hostId "host-offline"
Then Left(SessionFailure.networkUnavailable) is returned
And the session is not created
```

### Scenario: Connection timeout

```gherkin
Given a valid host configuration exists with hostId "host-slow"
And the remote server is not responding
When connectSession is called with hostId "host-slow"
And 30 seconds pass without response
Then Left(SessionFailure.timeout) is returned
And any partial connection is cleaned up
```

### Scenario: Jump host connection

```gherkin
Given a host configuration exists with hostId "host-behind-bastion"
And the host has jumpHostId set to "bastion-host"
And both hosts have valid credentials
When connectSession is called with hostId "host-behind-bastion"
Then connection to bastion-host is established first
Then connection to target host is established through bastion
And a single Session is created for the target host
And Right(session) is returned
```

### Scenario: Custom terminal dimensions

```gherkin
Given a valid host configuration exists with hostId "host-123"
When connectSession is called with hostId "host-123", cols 120, rows 40
Then the session is created with cols 120 and rows 40
And the PTY is configured with the specified dimensions
And Right(session) is returned
```

### Scenario: Protocol override

```gherkin
Given a host configuration exists with useMosh enabled
When connectSession is called with preferredProtocol "ssh"
Then SSH is used regardless of host configuration
And the session protocol is "ssh"
And Right(session) is returned
```

## Implementation Notes

- Use dartssh2 for SSH connections
- Use platform channel for Mosh (native implementation)
- Store session in database before connection attempt (status: connecting)
- Update session status on success/failure
- Retrieve credentials from secure storage with biometric auth
- Implement connection timeout (default 30s)
- Clean up resources on failure

## Error Mapping

| Exception        | SessionFailure       |
| ---------------- | -------------------- |
| SSHAuthFailure   | authenticationFailed |
| SocketException  | connectionFailed     |
| TimeoutException | timeout              |
| No network       | networkUnavailable   |
| Host not in DB   | hostNotFound         |

## Related Specs

- L2: [Session Service](../L2-contract/service-session.md)
- L2: [Host Service](../L2-contract/service-host.md)
- L1: [disconnectSession](session-disconnect-session.md)
- L1: [reconnectSession](session-reconnect-session.md)
