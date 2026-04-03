// @telos L1:function:lib/features/session/presentation/providers:session_terminal_provider

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xterm/xterm.dart';

import '../../../../core/errors/failures.dart';
import '../../../ai/presentation/providers/ai_providers.dart';
import '../../../ai/presentation/providers/remote_ai_providers.dart';
import '../../../terminal/data/datasources/ssh_datasource.dart';
import '../../../terminal/domain/entities/ssh_connection_config.dart';
import '../../../terminal/domain/entities/terminal_config.dart';
import '../../../terminal/presentation/providers/output_router_provider.dart';
import '../../../terminal/presentation/providers/prompt_input_controller.dart';
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
      // Transform newlines: mobile soft keyboards send LF (\n) for Enter,
      // but terminals expect CR (\r). Without this, TUI apps (vim, htop,
      // OpenCode, etc.) receive a literal newline instead of a submit action.
      // Only transform a bare \n — don't touch \r\n which is already correct.
      final transformed = data == '\n' ? '\r' : data;

      _syncPromptInput(transformed);

      // Route through OutputRouter for command/input tracking when semantic
      // blocks are enabled. This allows the router to detect Enter presses
      // and buffer typed characters for block creation.
      final terminalConfig = ref.read(terminalConfigProvider);
      if (terminalConfig.enableSemanticBlocks) {
        ref
            .read(outputRouterControllerProvider(sessionId).notifier)
            .processInput(transformed);
      }

      _sshDataSource!.writeString(transformed);
    }
  }

  void _syncPromptInput(String data) {
    final promptState = ref.read(promptInputControllerProvider(sessionId));
    if (!promptState.isAtPrompt || promptState.isInTuiMode) {
      return;
    }

    final promptController =
        ref.read(promptInputControllerProvider(sessionId).notifier);

    if (data == '\r' || data == '\n' || data == '\r\n') {
      return;
    }

    if (data == '\x7f' || data == '\x08') {
      promptController.deleteBackward();
      return;
    }

    if (data == '\x15') {
      promptController.clear();
      return;
    }

    if (data.startsWith('\x1b') ||
        data.codeUnits.any((c) => c < 32 && c != 9)) {
      return;
    }

    promptController.insertText(data);
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

    // Wire SSH output to terminal (possibly via OutputRouter for block detection)
    final terminalConfig = ref.read(terminalConfigProvider);

    _outputSubscription = _sshDataSource!.output.listen((data) {
      // Decode UTF-8 properly - SSH sends UTF-8 encoded text
      final output = utf8.decode(data, allowMalformed: true);

      if (terminalConfig.enableSemanticBlocks) {
        // Route through OutputRouter for prompt/block detection.
        // The OutputRouter will write to the terminal via its onProcessedOutput callback.
        ref
            .read(outputRouterControllerProvider(sessionId).notifier)
            .processOutput(output);
      } else {
        // Classic mode: write directly to terminal
        state.write(output);
      }
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

  /// The underlying SSH client, if connected.
  ///
  /// Used by remote AI detection and command execution.
  SSHClient? get sshClient => _sshDataSource?.client;

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

        // Trigger remote AI detection after successful SSH connection.
        // Delay by 1 second to let the connection settle before probing.
        _triggerRemoteAiDetection(sessionId, config, terminalController);
      },
    );

    return result;
  }

  /// Disconnect a session.
  Future<void> disconnectSession(String sessionId) async {
    final terminalController =
        ref.read(sessionTerminalControllerProvider(sessionId).notifier);

    await terminalController.disconnect();

    // Clean up remote AI state for this session's host
    _cleanUpRemoteAi(sessionId);

    ref
        .read(sessionListControllerProvider.notifier)
        .updateSessionStatus(sessionId, SessionStatus.disconnected);
  }

  /// Clean up all resources for a session.
  ///
  /// Invalidates the family provider for this session ID,
  /// triggering cleanup of terminal and SSH connection.
  void disposeSession(String sessionId) {
    // Cancel any pending detection timer for this session
    _detectionTimers[sessionId]?.cancel();
    _detectionTimers.remove(sessionId);

    // Clean up remote AI state before invalidating the session
    _cleanUpRemoteAi(sessionId);

    // Invalidate the family provider to trigger disposal
    ref.invalidate(sessionTerminalControllerProvider(sessionId));
  }

  /// Triggers remote AI detection after a successful SSH connection.
  ///
  /// Uses a cancellable [Timer] to wait 1 second for the connection to settle,
  /// then runs detection in the background. If the session disconnects before
  /// the timer fires, it is cancelled in [disposeSession]/[disconnectSession].
  ///
  /// Results are available via [remoteAiDetectionStateProvider].
  void _triggerRemoteAiDetection(
    String sessionId,
    SSHConnectionConfig config,
    SessionTerminalController terminalController,
  ) {
    final hostId = _hostIdFromConfig(config);

    // Cancel any existing timer for this session
    _detectionTimers[sessionId]?.cancel();

    // Use a cancellable Timer instead of Future.delayed
    _detectionTimers[sessionId] = Timer(const Duration(seconds: 1), () {
      _detectionTimers.remove(sessionId);

      final client = terminalController.sshClient;
      if (client == null) {
        debugPrint(
          '[SessionTerminalManager] SSH client gone before detection for $hostId',
        );
        return;
      }

      // Store the session-to-host mapping for cleanup
      _sessionHostMap[sessionId] = hostId;

      // Trigger detection asynchronously
      debugPrint(
        '[SessionTerminalManager] Triggering AI detection for $hostId',
      );
      ref
          .read(remoteAiDetectionStateProvider(hostId).notifier)
          .detect(client)
          .then((result) {
        if (result.hasAnyProvider) {
          debugPrint(
            '[SessionTerminalManager] AI detected on $hostId: '
            '${result.providerCount} providers',
          );

          // Auto-initialize the remote AI service controller
          final savedConfig = ref.read(remoteAiConfigStateProvider(hostId));
          ref
              .read(remoteAiServiceControllerProvider(hostId).notifier)
              .initialize(
                client: client,
                detectionResult: result,
                config: savedConfig,
              );

          // Force the bridge providers to re-evaluate with fresh dependency
          // tracking. The keepAlive activeRemoteAiServiceProvider may have
          // a cached null from before this initialization, and stale
          // dependency tracking can prevent it from seeing the new state.
          ref.invalidate(activeRemoteAiServiceProvider);

          // Force the global AI service controller to rebuild so it picks
          // up the newly available remote service. Without this, the
          // controller may have already completed its build() with
          // UnconfiguredAiService and won't know the remote service is ready.
          ref.invalidate(aiServiceControllerProvider);

          debugPrint(
            '[SessionTerminalManager] Invalidated aiServiceControllerProvider '
            'after remote service init for $hostId',
          );
        }
      }).catchError((Object error) {
        debugPrint(
          '[SessionTerminalManager] AI detection failed for $hostId: $error',
        );
      });
    });
  }

  /// Cleans up remote AI state when a session disconnects or is disposed.
  void _cleanUpRemoteAi(String sessionId) {
    final hostId = _sessionHostMap.remove(sessionId);
    if (hostId == null) return;

    // Check if any other session is connected to the same host
    final otherSessionsOnHost =
        _sessionHostMap.values.where((h) => h == hostId).isNotEmpty;

    if (!otherSessionsOnHost) {
      debugPrint(
        '[SessionTerminalManager] Last session to $hostId disconnected, '
        'cleaning up remote AI',
      );

      // Fully tear down the remote AI service (dispose + null state).
      // Using teardown() instead of onDisconnected() to release the
      // SSHClient reference and allow garbage collection.
      ref.read(remoteAiServiceControllerProvider(hostId).notifier).teardown();

      // Clear detection cache (will re-detect on reconnect)
      ref.read(remoteAiDetectionStateProvider(hostId).notifier).clear();

      // Force global AI service to rebuild without the stale remote service
      ref.invalidate(aiServiceControllerProvider);
    }
  }

  /// Derives a host identifier from an SSH connection config.
  ///
  /// Uses host:port as the unique identifier for caching and lookups.
  static String _hostIdFromConfig(SSHConnectionConfig config) {
    return '${config.host}:${config.port}';
  }

  /// Maps session IDs to their host identifiers for cleanup tracking.
  final Map<String, String> _sessionHostMap = {};

  /// Cancellable detection timers per session ID.
  ///
  /// When a session disconnects before the 1-second detection delay,
  /// the timer is cancelled to avoid wasted detection attempts.
  final Map<String, Timer> _detectionTimers = {};
}
