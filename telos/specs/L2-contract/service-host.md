<!-- telos-metadata
id: L2:contract:service-host
level: 2
title: Host Service
parent: L3:experience:session-management
children: []
-->

# L2: Host Service

## Overview

The Host Service manages saved host configurations, including connection
details, authentication, and organization into folders. It also integrates with
Tailscale for automatic node discovery.

## Interface

### HostService

```dart
abstract class HostService {
  /// Create a new host configuration
  Future<Either<HostFailure, Host>> createHost(HostConfig config);
  
  /// Update an existing host
  Future<Either<HostFailure, Host>> updateHost(String hostId, HostConfig config);
  
  /// Delete a host
  Future<Either<HostFailure, void>> deleteHost(String hostId);
  
  /// Get a host by ID
  Future<Either<HostFailure, Host>> getHost(String hostId);
  
  /// Get all hosts
  Future<List<Host>> getAllHosts();
  
  /// Watch all hosts (live updates)
  Stream<List<Host>> watchHosts();
  
  /// Get hosts by folder
  Future<List<Host>> getHostsByFolder(String? folderId);
  
  /// Get recent hosts (by last connection time)
  Future<List<Host>> getRecentHosts({int limit = 5});
  
  /// Search hosts by name or hostname
  Future<List<Host>> searchHosts(String query);
  
  /// Test connection to a host
  Future<Either<HostFailure, Duration>> testConnection(String hostId);
  
  /// Import hosts from SSH config file
  Future<List<Host>> importFromSSHConfig(String configContent);
  
  /// Get Tailscale nodes (if available)
  Future<Either<HostFailure, List<TailscaleNode>>> getTailscaleNodes();
  
  /// Watch Tailscale nodes (live updates)
  Stream<List<TailscaleNode>> watchTailscaleNodes();
}
```

### Data Models

```dart
@freezed
class Host with _$Host {
  const factory Host({
    required String id,
    required String name,
    required String hostname,
    @Default(22) int port,
    required String username,
    String? keyId,  // Reference to secure storage
    String? password,  // Only for import, not persisted
    @Default(true) bool useMosh,
    String? jumpHostId,
    String? folderId,
    List<String>? tags,
    required DateTime createdAt,
    DateTime? lastConnectedAt,
  }) = _Host;
}

@freezed
class HostConfig with _$HostConfig {
  const factory HostConfig({
    required String name,
    required String hostname,
    @Default(22) int port,
    required String username,
    String? privateKey,
    String? passphrase,
    @Default(true) bool useMosh,
    String? jumpHostId,
    String? folderId,
    List<String>? tags,
  }) = _HostConfig;
}

@freezed
class HostFolder with _$HostFolder {
  const factory HostFolder({
    required String id,
    required String name,
    int? sortOrder,
  }) = _HostFolder;
}

@freezed
class TailscaleNode with _$TailscaleNode {
  const factory TailscaleNode({
    required String id,
    required String name,
    required String ipv4,
    String? ipv6,
    required bool online,
    required String os,
    String? hostname,
  }) = _TailscaleNode;
}

@freezed
class HostFailure with _$HostFailure {
  const factory HostFailure.notFound() = _NotFound;
  const factory HostFailure.duplicateName() = _DuplicateName;
  const factory HostFailure.invalidConfig(String message) = _InvalidConfig;
  const factory HostFailure.connectionFailed(String message) = _ConnectionFailed;
  const factory HostFailure.tailscaleUnavailable() = _TailscaleUnavailable;
  const factory HostFailure.storageError(String message) = _StorageError;
}
```

## Behavior

### Host Creation

1. Validate configuration (hostname, username required)
2. If private key provided, store in secure storage, save reference
3. Generate unique host ID
4. Persist to database
5. Return created host

### Key Management

- Private keys stored in flutter_secure_storage
- Keys encrypted with platform keychain (iOS Keychain, Android Keystore)
- Only key reference (ID) stored in SQLite
- Biometric auth required to access keys

### Tailscale Integration

- Query installed Tailscale app via platform channel
- Return available nodes with online status
- Allow quick-connect to Tailscale nodes
- Create temporary host config for Tailscale connections

### SSH Config Import

Parse standard `~/.ssh/config` format:

```
Host myserver
    HostName 192.168.1.10
    User admin
    Port 22
    IdentityFile ~/.ssh/id_rsa
```

## Persistence

### SQLite Schema

```sql
CREATE TABLE hosts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  hostname TEXT NOT NULL,
  port INTEGER DEFAULT 22,
  username TEXT NOT NULL,
  key_id TEXT,
  use_mosh INTEGER DEFAULT 1,
  jump_host_id TEXT,
  folder_id TEXT,
  tags TEXT,  -- JSON array
  created_at INTEGER NOT NULL,
  last_connected_at INTEGER,
  FOREIGN KEY (jump_host_id) REFERENCES hosts(id),
  FOREIGN KEY (folder_id) REFERENCES host_folders(id)
);

CREATE TABLE host_folders (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  sort_order INTEGER
);
```

## Error Handling

| Error                   | Behavior                                          |
| ----------------------- | ------------------------------------------------- |
| Duplicate name          | Return `HostFailure.duplicateName()`              |
| Invalid config          | Return `HostFailure.invalidConfig()` with details |
| Key storage fails       | Return `HostFailure.storageError()`               |
| Tailscale not installed | Return `HostFailure.tailscaleUnavailable()`       |

## Related Specs

- L3: [Session Management](../L3-experience/session-management.md)
- L2: [Session Service](service-session.md)
- L2: [Connection Picker](component-connection-picker.md)
- L1: [To be defined - SSH config parser]
- L1: [To be defined - Tailscale query functions]
