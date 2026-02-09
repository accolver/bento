// @telos L1:function:lib/features/session/domain/entities:session

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../terminal/domain/entities/ssh_connection_config.dart';
import 'session_status.dart';

part 'session.freezed.dart';

/// Represents a terminal session with connection state, metadata, and lifecycle tracking.
///
/// Sessions can be in various connection states and support features like
/// unread count tracking and running command indicators for multi-session
/// tab management.
@freezed
class Session with _$Session {
  const Session._();

  const factory Session({
    /// Unique identifier for this session (UUID).
    required String id,

    /// Display name for this session (shown in tab).
    required String name,

    /// SSH connection configuration for this session.
    required SSHConnectionConfig connectionConfig,

    /// Current connection status.
    @Default(SessionStatus.connecting) SessionStatus status,

    /// When this session was created.
    required DateTime createdAt,

    /// When this session was last accessed.
    required DateTime lastAccessedAt,

    /// Number of unread output lines since last viewed.
    @Default(0) int unreadCount,

    /// Whether a command is currently executing.
    @Default(false) bool hasRunningCommand,

    /// ID of the saved connection this session was created from, if any.
    ///
    /// Used for persisting per-connection preferences like view mode.
    int? savedConnectionId,
  }) = _Session;

  /// Returns the display name for the session.
  ///
  /// If name is empty, falls back to the host from connection config.
  String get displayName => name.isEmpty ? connectionConfig.host : name;

  /// Returns true if this session configuration is valid.
  ///
  /// Validates both the session name (non-empty) and the connection config.
  bool get isValid => name.isNotEmpty && connectionConfig.isValid;
}
