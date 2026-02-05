// @telos L1:function:lib/features/session/domain/entities:session_status

/// Represents the connection status of a terminal session.
enum SessionStatus {
  /// Session is establishing connection
  connecting,

  /// Session is actively connected
  connected,

  /// Session has been disconnected
  disconnected,

  /// Session is attempting to reconnect
  reconnecting,

  /// Session connection failed
  failed,
}

/// Extension methods for SessionStatus
extension SessionStatusExtension on SessionStatus {
  /// Returns true if the session is currently connected.
  bool get isConnected => this == SessionStatus.connected;

  /// Returns true if the session is in an active state
  /// (connecting, connected, or reconnecting).
  bool get isActive =>
      this == SessionStatus.connecting ||
      this == SessionStatus.connected ||
      this == SessionStatus.reconnecting;

  /// Returns true if the session can attempt reconnection.
  bool get canReconnect =>
      this == SessionStatus.disconnected || this == SessionStatus.failed;
}
