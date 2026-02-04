# Proposal: SSH Connectivity

## Why

SSH is the fundamental connectivity protocol for remote terminal access. Using
dartssh2, a pure Dart implementation, ensures cross-platform compatibility
without native dependencies. This enables users to connect to any standard SSH
server with key-based or password authentication.

## What Changes

- Integrate dartssh2 package for SSH/SFTP
- Implement SSHClient wrapper with Either-based error handling
- Support key-based authentication (RSA, Ed25519, ECDSA)
- Support password authentication
- Handle connection errors with typed failures
- Implement PTY configuration for interactive shells
- Stream stdout/stderr to terminal
- Handle connection lifecycle (connect, disconnect, reconnect)

## Capabilities

### New Capabilities

- `ssh-client`: Pure Dart SSH2 client
- `key-auth`: SSH key authentication
- `password-auth`: Password authentication
- `pty-session`: Interactive PTY sessions
- `stream-output`: Real-time stdout/stderr streaming

## Impact

- `lib/features/terminal/data/datasources/ssh_datasource.dart`: SSH client
- `lib/features/terminal/domain/repositories/terminal_repository.dart`:
  Repository interface
- `lib/features/terminal/domain/usecases/connect_session.dart`: Connect usecase
- `lib/core/errors/failures.dart`: Connection failure types

## Dependencies

- `scaffold-flutter-project`: Requires Flutter project structure
- `credential-storage`: Requires secure key storage

## Phase

**Phase 1 - MVP** (Weeks 5-6)

## Priority

**P0 - Must Have**
