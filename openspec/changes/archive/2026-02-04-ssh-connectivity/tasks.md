# Tasks: SSH Connectivity

## Overview

Implementation tasks for SSH connectivity using dartssh2. Enables connecting to
remote servers with password or key-based authentication.

## Prerequisites

- Flutter project scaffold complete
- dartssh2 package in pubspec.yaml (already added)
- Terminal feature structure exists

---

## 1. Domain Entities

### 1.1 Authentication Types

- [x] 1.1.1 Create `SSHAuthMethod` sealed class in
      `lib/features/terminal/domain/entities/ssh_auth_method.dart`
- [x] 1.1.2 Implement `SSHPasswordAuth` subclass with username/password fields
- [x] 1.1.3 Implement `SSHKeyAuth` subclass with username/privateKey/passphrase
      fields
- [x] 1.1.4 Add freezed annotations for immutability

### 1.2 Connection Configuration

- [x] 1.2.1 Create `SSHConnectionConfig` freezed class in
      `lib/features/terminal/domain/entities/ssh_connection_config.dart`
- [x] 1.2.2 Add required fields: host, authMethod
- [x] 1.2.3 Add optional fields with defaults: port (22), terminalType
      ("xterm-256color"), timeout (30s)
- [x] 1.2.4 Add environment variables map field

### 1.3 Connection State

- [x] 1.3.1 Create `SSHConnectionState` enum in
      `lib/features/terminal/domain/entities/ssh_connection_state.dart`
- [x] 1.3.2 Define states: disconnected, connecting, connected, error
- [x] 1.3.3 Create `SSHConnectionStatus` class with state and optional error
      message

---

## 2. Data Layer - SSH Data Source

### 2.1 Core Implementation

- [x] 2.1.1 Create `SSHDataSource` class in
      `lib/features/terminal/data/datasources/ssh_datasource.dart`
- [x] 2.1.2 Implement `TerminalRepository` interface
- [x] 2.1.3 Add private `SSHClient?` field for dartssh2 client
- [x] 2.1.4 Add private `SSHSession?` field for shell session
- [x] 2.1.5 Add `StreamController<Uint8List>` for output buffering

### 2.2 Connection Logic

- [x] 2.2.1 Implement `connect(SSHConnectionConfig)` method returning
      `Future<Either<Failure, void>>`
- [x] 2.2.2 Add socket connection with timeout handling
- [x] 2.2.3 Implement password authentication path
- [x] 2.2.4 Implement key authentication path with passphrase support
- [x] 2.2.5 Map dartssh2 exceptions to Failure types

### 2.3 PTY and Shell

- [x] 2.3.1 Implement PTY allocation after authentication
- [x] 2.3.2 Configure PTY dimensions from TerminalDimensions
- [x] 2.3.3 Set TERM and LANG environment variables
- [x] 2.3.4 Request shell after PTY allocation
- [x] 2.3.5 Implement `resize(TerminalDimensions)` to send window-change

### 2.4 I/O Streaming

- [x] 2.4.1 Implement `Stream<Uint8List> get output` from session stdout/stderr
- [x] 2.4.2 Implement `write(Uint8List)` to session stdin
- [x] 2.4.3 Implement `writeString(String)` as UTF-8 encoded write
- [x] 2.4.4 Handle disconnected state in write methods (silently ignore)

### 2.5 Lifecycle

- [x] 2.5.1 Implement `close()` to cleanly disconnect
- [x] 2.5.2 Close SSH session and client
- [x] 2.5.3 Close output stream controller
- [x] 2.5.4 Implement `isConnected` getter
- [x] 2.5.5 Add connection state change tracking

---

## 3. Presentation Layer - Providers

### 3.1 Connection Provider

- [x] 3.1.1 Create `ssh_connection_provider.dart` in presentation/providers/
- [x] 3.1.2 Implement `sshConnectionProvider` with Riverpod code generation
- [x] 3.1.3 Expose connection state as stream
- [x] 3.1.4 Add `connect(SSHConnectionConfig)` method
- [x] 3.1.5 Add `disconnect()` method

### 3.2 Integration with Terminal

- [x] 3.2.1 Update `TerminalNotifier` to support SSH data source
- [x] 3.2.2 Add method to connect via SSH config
- [x] 3.2.3 Wire SSH output stream to terminal emulator

---

## 4. Testing

### 4.1 Unit Tests - Entities

- [x] 4.1.1 Test `SSHPasswordAuth` creation and properties
- [x] 4.1.2 Test `SSHKeyAuth` creation with/without passphrase
- [x] 4.1.3 Test `SSHConnectionConfig` defaults and custom values
- [x] 4.1.4 Test `SSHConnectionState` enum values

### 4.2 Unit Tests - Data Source

- [x] 4.2.1 Test connection failure scenarios (timeout, unreachable)
- [x] 4.2.2 Test authentication failure mapping
- [x] 4.2.3 Test write methods with disconnected state
- [x] 4.2.4 Test resize dimension clamping
- [x] 4.2.5 Test clean disconnect and resource cleanup

---

## 5. Code Generation and Verification

- [x] 5.1 Run `dart run build_runner build --delete-conflicting-outputs`
- [x] 5.2 Run `flutter analyze` - verify no errors
- [x] 5.3 Run `flutter test` - verify all tests pass
- [x] 5.4 Verify all @telos annotations are present

---

## Notes

- dartssh2 is already in pubspec.yaml
- ConnectionFailure and AuthenticationFailure already exist in core/errors
- TerminalRepository interface already defines write/resize/output/close methods
- Credential persistence is NOT in scope (handled by credential-storage change)
