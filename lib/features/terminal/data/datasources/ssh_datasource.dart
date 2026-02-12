// @telos L1:function:lib/features/terminal/data/datasources:ssh_datasource

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/ssh_auth_method.dart';
import '../../domain/entities/ssh_connection_config.dart';
import '../../domain/entities/ssh_connection_state.dart';
import '../../domain/entities/terminal_config.dart';
import '../../domain/repositories/terminal_repository.dart';

/// SSH data source implementing [TerminalRepository].
///
/// Uses dartssh2 for pure Dart SSH connectivity.
/// Manages connection lifecycle, PTY sessions, and I/O streaming.
class SSHDataSource implements TerminalRepository {
  SSHDataSource();

  /// The dartssh2 SSH client.
  SSHClient? _client;

  /// The active shell session.
  SSHSession? _session;

  /// Stream controller for output data.
  final StreamController<Uint8List> _outputController =
      StreamController<Uint8List>.broadcast();

  /// Stream controller for title changes (not typically used in SSH).
  final StreamController<String> _titleController =
      StreamController<String>.broadcast();

  /// Current connection status.
  SSHConnectionStatus _status = const SSHConnectionStatus.disconnected();

  /// Stream controller for connection state changes.
  final StreamController<SSHConnectionStatus> _statusController =
      StreamController<SSHConnectionStatus>.broadcast();

  /// Current connection configuration.
  SSHConnectionConfig? _config;

  /// The underlying SSH client, if connected.
  ///
  /// Exposed for features that need to execute commands on the remote
  /// host outside of the PTY session (e.g., remote AI detection).
  SSHClient? get client => _client;

  /// Stream of connection status changes.
  Stream<SSHConnectionStatus> get statusStream => _statusController.stream;

  /// Current connection status.
  SSHConnectionStatus get status => _status;

  /// Establishes an SSH connection with the given configuration.
  ///
  /// Returns [Right] on success, [Left] with appropriate [Failure] on error.
  Future<Either<Failure, void>> connect(SSHConnectionConfig config) async {
    // Validate configuration
    final errors = config.validate();
    if (errors.isNotEmpty) {
      return Left(ValidationFailure(message: errors.first));
    }

    _config = config;
    _updateStatus(SSHConnectionStatus.connecting(
      host: config.host,
      port: config.port,
    ));

    try {
      // Establish socket connection with timeout
      final socket = await SSHSocket.connect(
        config.host,
        config.port,
        timeout: config.timeout,
      );

      // Create SSH client
      _client = SSHClient(
        socket,
        username: _getUsername(config.authMethod),
        onPasswordRequest: () => _getPassword(config.authMethod),
        identities: _getIdentities(config.authMethod),
      );

      // Wait for authentication to complete
      // dartssh2 authenticates during client creation

      // Allocate PTY and start shell
      final result = await _startShell(config);
      if (result.isLeft()) {
        await _cleanup();
        return result;
      }

      _updateStatus(SSHConnectionStatus.connected(
        host: config.host,
        port: config.port,
      ));

      return const Right(null);
    } on SocketException catch (e) {
      await _cleanup();
      return Left(ConnectionFailure(
        message: 'Connection failed: ${e.message}',
        host: config.host,
        port: config.port,
      ));
    } on TimeoutException catch (_) {
      await _cleanup();
      return Left(ConnectionFailure(
        message: 'Connection timed out',
        host: config.host,
        port: config.port,
      ));
    } on SSHAuthFailError catch (e) {
      await _cleanup();
      return Left(AuthenticationFailure(
        message: _mapAuthError(e),
      ));
    } on SSHAuthAbortError catch (_) {
      await _cleanup();
      return Left(const AuthenticationFailure(
        message: 'Authentication aborted',
      ));
    } catch (e) {
      await _cleanup();
      return Left(UnknownFailure(
        message: 'SSH connection failed: $e',
        originalError: e,
      ));
    }
  }

  /// Extracts username from auth method.
  String _getUsername(SSHAuthMethod auth) {
    return switch (auth) {
      SSHPasswordAuth(:final username) => username,
      SSHKeyAuth(:final username) => username,
    };
  }

  /// Returns password callback for password auth, null otherwise.
  String? _getPassword(SSHAuthMethod auth) {
    return switch (auth) {
      SSHPasswordAuth(:final password) => password,
      SSHKeyAuth() => null,
    };
  }

  /// Returns identities list for key auth, empty otherwise.
  List<SSHKeyPair> _getIdentities(SSHAuthMethod auth) {
    return switch (auth) {
      SSHPasswordAuth() => <SSHKeyPair>[],
      SSHKeyAuth(:final privateKey, :final passphrase) =>
        SSHKeyPair.fromPem(privateKey, passphrase),
    };
  }

  /// Maps SSH authentication errors to user-friendly messages.
  String _mapAuthError(SSHAuthFailError error) {
    final message = error.message?.toLowerCase() ?? '';
    if (message.contains('passphrase')) {
      return 'Invalid passphrase';
    }
    if (message.contains('key')) {
      return 'Key not authorized';
    }
    return 'Invalid credentials';
  }

  /// Starts a shell session with PTY.
  Future<Either<Failure, void>> _startShell(SSHConnectionConfig config) async {
    try {
      // Try multiple approaches in order of preference:
      // 1. Execute an interactive shell with PTY (most compatible)
      // 2. Shell with default PTY
      // 3. Shell without PTY (degraded but functional)

      SSHSession? session;
      String? lastError;

      // Approach 1: Execute interactive shell with PTY
      // This is often more compatible than shell() on some servers
      try {
        debugPrint('Trying execute with PTY for interactive shell');
        session = await _client?.execute(
          r'$SHELL -l', // Run user's login shell
          pty: SSHPtyConfig(
            type: config.terminalType,
            width: 80,
            height: 24,
          ),
        );
      } on Object catch (e) {
        lastError = e.toString();
        debugPrint('Execute with PTY failed: $e');
      }

      // Approach 2: Regular shell() with default PTY
      if (session == null) {
        try {
          debugPrint('Trying shell with default PTY');
          session = await _client?.shell(
            pty: const SSHPtyConfig(),
          );
        } on Object catch (e) {
          lastError = e.toString();
          debugPrint('Shell with PTY failed: $e');
        }
      }

      // Approach 3: Shell without PTY
      if (session == null) {
        try {
          debugPrint('Trying shell without PTY');
          session = await _client?.shell(pty: null);
        } on Object catch (e) {
          lastError = e.toString();
          debugPrint('Shell without PTY failed: $e');
        }
      }

      // Approach 4: Execute /bin/bash directly
      if (session == null) {
        try {
          debugPrint('Trying execute /bin/bash -i');
          session = await _client?.execute(
            '/bin/bash -i',
            pty: SSHPtyConfig(
              type: config.terminalType,
              width: 80,
              height: 24,
            ),
          );
        } on Object catch (e) {
          lastError = e.toString();
          debugPrint('Execute /bin/bash failed: $e');
        }
      }

      if (session == null) {
        return Left(ConnectionFailure(
          message: 'Failed to start shell: $lastError',
        ));
      }

      _session = session;

      // Listen to stdout and stderr
      _session!.stdout.listen(
        (data) {
          if (!_outputController.isClosed) {
            _outputController.add(Uint8List.fromList(data));
          }
        },
        onError: (Object error) {
          _updateStatus(SSHConnectionStatus.error(
            errorMessage: 'Stream error: $error',
            host: config.host,
            port: config.port,
          ));
        },
        onDone: () {
          if (_status.isConnected) {
            _updateStatus(const SSHConnectionStatus.disconnected());
          }
        },
      );

      _session!.stderr.listen(
        (data) {
          if (!_outputController.isClosed) {
            _outputController.add(Uint8List.fromList(data));
          }
        },
      );

      return const Right(null);
    } on SSHChannelOpenError catch (e) {
      return Left(ConnectionFailure(
        message: 'Shell failed: ${e.description}',
      ));
    } on Object catch (e) {
      return Left(UnknownFailure(
        message: 'Shell startup failed: $e',
        originalError: e,
      ));
    }
  }

  /// Updates connection status and notifies listeners.
  void _updateStatus(SSHConnectionStatus newStatus) {
    _status = newStatus;
    if (!_statusController.isClosed) {
      _statusController.add(newStatus);
    }
  }

  /// Cleans up connection resources.
  Future<void> _cleanup() async {
    _session?.close();
    _session = null;
    _client?.close();
    _client = null;
    _updateStatus(const SSHConnectionStatus.disconnected());
  }

  // TerminalRepository implementation

  @override
  void write(Uint8List data) {
    if (_session == null || !isConnected) return;
    _session!.stdin.add(data);
  }

  @override
  void writeString(String text) {
    write(Uint8List.fromList(utf8.encode(text)));
  }

  @override
  void resize(TerminalDimensions dimensions) {
    if (_session == null || !isConnected) return;

    // Clamp to valid ranges
    final cols = dimensions.columns.clamp(20, 500);
    final rows = dimensions.rows.clamp(5, 200);

    _session!.resizeTerminal(cols, rows);
  }

  @override
  Stream<Uint8List> get output => _outputController.stream;

  @override
  Stream<String> get titleChanges => _titleController.stream;

  @override
  Future<void> close() async {
    await _cleanup();
    await _outputController.close();
    await _titleController.close();
    await _statusController.close();
  }

  @override
  bool get isConnected => _status.isConnected && _session != null;
}
