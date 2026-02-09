// @telos L1:function:lib/database/tables:saved_connections

import 'package:drift/drift.dart';

/// Table for storing saved SSH connection configurations.
///
/// Passwords are NOT stored here - they go in flutter_secure_storage.
/// This table stores connection metadata and references to secure credentials.
@DataClassName('SavedConnectionEntry')
class SavedConnections extends Table {
  /// Unique identifier for the connection
  IntColumn get id => integer().autoIncrement()();

  /// User-friendly name for this connection
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Hostname or IP address
  TextColumn get host => text().withLength(min: 1, max: 255)();

  /// SSH port (default 22)
  IntColumn get port => integer().withDefault(const Constant(22))();

  /// Username for authentication
  TextColumn get username => text().withLength(min: 1, max: 100)();

  /// Authentication type: 'password' or 'key'
  TextColumn get authType => text().withDefault(const Constant('password'))();

  /// Reference key for secure storage (where password/key is stored)
  /// Format: "bento_ssh_cred_{id}"
  TextColumn get credentialKey => text().nullable()();

  /// Terminal type (e.g., 'xterm-256color')
  TextColumn get terminalType =>
      text().withDefault(const Constant('xterm-256color'))();

  /// Optional color/icon for visual identification
  TextColumn get color => text().nullable()();

  /// Optional notes about this connection
  TextColumn get notes => text().nullable()();

  /// When this connection was created
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When this connection was last used
  DateTimeColumn get lastUsedAt => dateTime().nullable()();

  /// Number of times this connection has been used
  IntColumn get useCount => integer().withDefault(const Constant(0))();

  /// Whether this connection is marked as favorite
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// Sort order for manual ordering
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Preferred view mode for this connection (split, fullTerminal, fullBlocks)
  TextColumn get preferredViewMode =>
      text().withDefault(const Constant('split')).nullable()();
}
