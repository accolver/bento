// @telos L1:function:lib/features/connections/domain/entities:saved_connection

import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_connection.freezed.dart';
part 'saved_connection.g.dart';

/// Represents a saved SSH connection configuration.
///
/// Contains all metadata needed to establish a connection,
/// except for the actual credentials which are stored securely.
@freezed
class SavedConnection with _$SavedConnection {
  const factory SavedConnection({
    /// Unique identifier
    required int id,

    /// User-friendly name for this connection
    required String name,

    /// Hostname or IP address
    required String host,

    /// SSH port (default 22)
    required int port,

    /// Username for authentication
    required String username,

    /// Authentication type: 'password' or 'key'
    required String authType,

    /// Reference key for secure storage (where password/key is stored)
    String? credentialKey,

    /// Terminal type (e.g., 'xterm-256color')
    @Default('xterm-256color') String terminalType,

    /// Optional color for visual identification
    String? color,

    /// Optional notes about this connection
    String? notes,

    /// When this connection was created
    required DateTime createdAt,

    /// When this connection was last used
    DateTime? lastUsedAt,

    /// Number of times this connection has been used
    @Default(0) int useCount,

    /// Whether this connection is marked as favorite
    @Default(false) bool isFavorite,

    /// Sort order for manual ordering
    @Default(0) int sortOrder,

    /// Preferred view mode for this connection (split, fullTerminal, fullBlocks)
    @Default('split') String preferredViewMode,
  }) = _SavedConnection;

  factory SavedConnection.fromJson(Map<String, dynamic> json) =>
      _$SavedConnectionFromJson(json);
}

/// Extension methods for SavedConnection
extension SavedConnectionX on SavedConnection {
  /// Returns true if this uses password authentication
  bool get isPasswordAuth => authType == 'password';

  /// Returns true if this uses key authentication
  bool get isKeyAuth => authType == 'key';

  /// Returns a display string for the connection
  String get displayString => '$username@$host:$port';
}
