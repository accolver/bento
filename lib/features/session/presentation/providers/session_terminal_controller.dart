// @telos L1:function:lib/features/session/presentation/providers:session_terminal_provider

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xterm/xterm.dart';

import '../../../../core/errors/failures.dart';
import '../../../terminal/data/datasources/ssh_datasource.dart';
import '../../../terminal/domain/entities/ssh_connection_config.dart';
import '../../../terminal/domain/entities/terminal_config.dart';
import '../../../terminal/presentation/providers/terminal_config_provider.dart';
import 'session_list_controller.dart';
import '../../domain/entities/session_status.dart';

part 'session_terminal_controller.g.dart';

/// Per-session terminal controller using family pattern.
///
/// Each session ID gets its own isolated Terminal instance and SSH connection.
/// This allows multiple concurrent SSH sessions with independent state.
@Riverpod(keepAlive: true)
class SessionTerminalController extends _$SessionTerminalController {
  StreamSubscription<dynamic>? _outputSubscription;
  SSHDataSource? _sshDataSource;

  @override
  Terminal build(String sessionId) {
    final config = ref.read(terminalConfigProvider);

    final terminal = Terminal(
      maxLines: config.scrollbackLines,
    );

    // Listen for user input from the terminal and forward to SSH
    terminal.onOutput = _handleTerminalOutput;

    // Clean up when this specific session is disposed
    ref.onDispose(() {
      _outputSubscription?.cancel();
      _sshDataSource?.close();
    });

    return terminal;
  }

  /// Handles output from the terminal (user keystrokes)
  void _handleTerminalOutput(String data) {
    if (_sshDataSource?.isConnected ?? false) {
      _sshDataSource!.writeString(data);
    }
  }

  /// Connects to a remote host via SSH.
  ///
  /// Establishes the SSH connection and wires the terminal I/O.
  /// Returns [Right] on success, [Left] with [Failure] on error.
  Future<Either<Failure, void>> connect(SSHConnectionConfig config) async {
    // Clean up any existing connection
    await disconnect();

    // Create SSH data source
    _sshDataSource = SSHDataSource();

    // Attempt connection
    final result = await _sshDataSource!.connect(config);

    if (result.isLeft()) {
      await _sshDataSource?.close();
      _sshDataSource = null;
      return result;
    }

    // Wire SSH output to terminal
    _outputSubscription = _sshDataSource!.output.listen((data) {
      // Decode UTF-8 properly - SSH sends UTF-8 encoded text
      final output = utf8.decode(data, allowMalformed: true);
      state.write(output);
    });

    // Re-attach the onOutput handler to the current terminal
    state.onOutput = _handleTerminalOutput;

    return const Right(null);
  }

  /// Disconnects from the current SSH session.
  Future<void> disconnect() async {
    await _outputSubscription?.cancel();
    _outputSubscription = null;
    await _sshDataSource?.close();
    _sshDataSource = null;
  }

  /// Returns true if connected to an SSH session.
  bool get isConnected => _sshDataSource?.isConnected ?? false;

  /// Write a string to the terminal/SSH session.
  void write(String text) {
    if (_sshDataSource?.isConnected ?? false) {
      _sshDataSource!.writeString(text);
    } else {
      state.write(text);
    }
  }

  /// Write bytes to the terminal/SSH session.
  void writeBytes(List<int> data) {
    if (_sshDataSource?.isConnected ?? false) {
      _sshDataSource!.write(Uint8List.fromList(data));
    } else {
      state.write(String.fromCharCodes(data));
    }
  }

  /// Clear the terminal screen.
  void clear() {
    state.write('\x1b[2J\x1b[H');
  }

  /// Resize the terminal and SSH PTY.
  void resize(int cols, int rows) {
    state.resize(cols, rows);
    _sshDataSource?.resize(TerminalDimensions(columns: cols, rows: rows));
  }
}

/// Manages lifecycle of all session terminals.
///
/// Integrates with SessionListController to manage terminal lifecycle
/// when sessions are created, connected, and closed.
@Riverpod(keepAlive: true)
class SessionTerminalManager extends _$SessionTerminalManager {
  @override
  void build() {
    // Listen for session changes
    ref.listen(sessionListControllerProvider, (previous, next) {
      // Clean up terminals for closed sessions
      if (previous != null) {
        final previousIds = previous.sessions.map((s) => s.id).toSet();
        final currentIds = next.sessions.map((s) => s.id).toSet();

        for (final removedId in previousIds.difference(currentIds)) {
          disposeSession(removedId);
        }
      }
    });
  }

  /// Connect a session to SSH.
  ///
  /// Updates session status based on connection result.
  Future<Either<Failure, void>> connectSession(
    String sessionId,
    SSHConnectionConfig config,
  ) async {
    // Update session status to connecting
    ref
        .read(sessionListControllerProvider.notifier)
        .updateSessionStatus(sessionId, SessionStatus.connecting);

    // Get the session's terminal controller
    final terminalController =
        ref.read(sessionTerminalControllerProvider(sessionId).notifier);

    // Attempt connection
    final result = await terminalController.connect(config);

    // Update session status based on result
    result.fold(
      (failure) {
        ref
            .read(sessionListControllerProvider.notifier)
            .updateSessionStatus(sessionId, SessionStatus.failed);
      },
      (_) {
        ref
            .read(sessionListControllerProvider.notifier)
            .updateSessionStatus(sessionId, SessionStatus.connected);
      },
    );

    return result;
  }

  /// Disconnect a session.
  Future<void> disconnectSession(String sessionId) async {
    final terminalController =
        ref.read(sessionTerminalControllerProvider(sessionId).notifier);

    await terminalController.disconnect();

    ref
        .read(sessionListControllerProvider.notifier)
        .updateSessionStatus(sessionId, SessionStatus.disconnected);
  }

  /// Clean up all resources for a session.
  ///
  /// Invalidates the family provider for this session ID,
  /// triggering cleanup of terminal and SSH connection.
  void disposeSession(String sessionId) {
    // Invalidate the family provider to trigger disposal
    ref.invalidate(sessionTerminalControllerProvider(sessionId));
  }
}
