// @telos L1:function:lib/features/terminal/domain/entities:ssh_connection_state

import 'package:equatable/equatable.dart';

/// Connection state for SSH sessions.
enum SSHConnectionState {
  /// Not connected to any host.
  disconnected,

  /// Currently attempting to connect.
  connecting,

  /// Successfully connected and session is active.
  connected,

  /// Connection failed or was lost.
  error,
}

/// Status of an SSH connection including state and optional error details.
class SSHConnectionStatus extends Equatable {
  const SSHConnectionStatus({
    required this.state,
    this.errorMessage,
    this.host,
    this.port,
  });

  /// Creates a disconnected status.
  const SSHConnectionStatus.disconnected()
      : state = SSHConnectionState.disconnected,
        errorMessage = null,
        host = null,
        port = null;

  /// Creates a connecting status.
  const SSHConnectionStatus.connecting({
    required String this.host,
    required int this.port,
  })  : state = SSHConnectionState.connecting,
        errorMessage = null;

  /// Creates a connected status.
  const SSHConnectionStatus.connected({
    required String this.host,
    required int this.port,
  })  : state = SSHConnectionState.connected,
        errorMessage = null;

  /// Creates an error status.
  const SSHConnectionStatus.error({
    required String this.errorMessage,
    this.host,
    this.port,
  }) : state = SSHConnectionState.error;

  /// The current connection state.
  final SSHConnectionState state;

  /// Error message when state is [SSHConnectionState.error].
  final String? errorMessage;

  /// The host being connected to or connected.
  final String? host;

  /// The port being used for the connection.
  final int? port;

  /// Returns true if the connection is active.
  bool get isConnected => state == SSHConnectionState.connected;

  /// Returns true if a connection attempt is in progress.
  bool get isConnecting => state == SSHConnectionState.connecting;

  /// Returns true if the connection failed.
  bool get hasError => state == SSHConnectionState.error;

  @override
  List<Object?> get props => [state, errorMessage, host, port];

  @override
  String toString() {
    switch (state) {
      case SSHConnectionState.disconnected:
        return 'SSHConnectionStatus(disconnected)';
      case SSHConnectionState.connecting:
        return 'SSHConnectionStatus(connecting to $host:$port)';
      case SSHConnectionState.connected:
        return 'SSHConnectionStatus(connected to $host:$port)';
      case SSHConnectionState.error:
        return 'SSHConnectionStatus(error: $errorMessage)';
    }
  }
}
