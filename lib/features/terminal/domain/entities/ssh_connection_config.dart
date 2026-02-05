// @telos L1:function:lib/features/terminal/domain/entities:ssh_connection_config

import 'package:freezed_annotation/freezed_annotation.dart';

import 'ssh_auth_method.dart';

part 'ssh_connection_config.freezed.dart';

/// Configuration for establishing an SSH connection.
///
/// Contains all parameters needed to connect to a remote host including
/// authentication method, terminal settings, and connection timeouts.
@freezed
class SSHConnectionConfig with _$SSHConnectionConfig {
  const SSHConnectionConfig._();

  const factory SSHConnectionConfig({
    /// The hostname or IP address of the SSH server.
    required String host,

    /// Authentication method (password or key).
    required SSHAuthMethod authMethod,

    /// SSH port number. Defaults to 22.
    @Default(22) int port,

    /// Terminal type for PTY allocation. Defaults to "xterm-256color".
    @Default('xterm-256color') String terminalType,

    /// Connection timeout duration. Defaults to 30 seconds.
    @Default(Duration(seconds: 30)) Duration timeout,

    /// Environment variables to set in the remote shell.
    @Default(<String, String>{}) Map<String, String> environment,
  }) = _SSHConnectionConfig;

  /// Validates the configuration and returns any validation errors.
  List<String> validate() {
    final errors = <String>[];

    if (host.isEmpty) {
      errors.add('Host cannot be empty');
    }

    if (port < 1 || port > 65535) {
      errors.add('Port must be between 1 and 65535');
    }

    if (timeout.isNegative) {
      errors.add('Timeout cannot be negative');
    }

    return errors;
  }

  /// Returns true if the configuration is valid.
  bool get isValid => validate().isEmpty;
}
