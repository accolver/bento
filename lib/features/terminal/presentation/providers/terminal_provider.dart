// @telos L1:function:lib/features/terminal/presentation/providers:terminal_provider

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xterm/xterm.dart';

import '../../../../core/constants/terminal_colors.dart';
import '../../../../core/errors/failures.dart';
import '../../../ai/presentation/providers/ai_providers.dart';
import '../../../ai/presentation/providers/remote_ai_providers.dart';
import '../../data/datasources/ssh_datasource.dart';
import '../../domain/entities/ssh_connection_config.dart';
import '../../domain/entities/terminal_config.dart';
import 'block_provider.dart' show kDefaultSessionId;
import 'output_router_provider.dart';
import 'terminal_config_provider.dart';

part 'terminal_provider.g.dart';

/// Manages terminal instance lifecycle and SSH connectivity.
///
/// Creates and disposes Terminal instances, configuring them with
/// the appropriate settings. Integrates with SSHDataSource for
/// remote terminal sessions.
///
/// Note: keepAlive=true prevents auto-disposal during navigation,
/// which would close the SSH connection.
@Riverpod(keepAlive: true)
class TerminalController extends _$TerminalController {
  StreamSubscription<dynamic>? _outputSubscription;
  SSHDataSource? _sshDataSource;
  Timer? _detectionTimer;

  @override
  Terminal build() {
    // Use ref.read instead of ref.watch to avoid rebuilds
    final config = ref.read(terminalConfigProvider);

    final terminal = Terminal(
      maxLines: config.scrollbackLines,
    );

    // Listen for user input from the terminal and forward to SSH
    terminal.onOutput = _handleTerminalOutput;

    // Clean up when provider is disposed
    ref.onDispose(() {
      _detectionTimer?.cancel();
      _outputSubscription?.cancel();
      _sshDataSource?.close();
    });

    return terminal;
  }

  /// Handles output from the terminal (user keystrokes)
  void _handleTerminalOutput(String data) {
    if (_sshDataSource?.isConnected ?? false) {
      // Debug: Log raw input data for troubleshooting keyboard issues
      if (data.isNotEmpty) {
        final codeUnits = data.codeUnits;
        debugPrint(
          'Terminal input: "${_escapeForLog(data)}" '
          'codeUnits: $codeUnits '
          'length: ${data.length}',
        );
      } else {
        debugPrint('Terminal input: EMPTY STRING');
      }

      // Transform newlines: soft keyboards may send LF (\n) but terminals
      // expect CR (\r) for Enter. Replace \n with \r for proper behavior.
      // Note: Don't replace \r\n as that's already correct for some modes.
      var transformedData = data;
      if (data == '\n') {
        // Single newline from soft keyboard Enter key
        transformedData = '\r';
      }

      // Route through OutputRouter for command detection if semantic blocks enabled
      // Note: This uses kDefaultSessionId as the legacy shared controller
      // doesn't know which session it belongs to. The per-session path
      // (SessionTerminalController) is the preferred code path.
      final terminalConfig = ref.read(terminalConfigProvider);
      if (terminalConfig.enableSemanticBlocks) {
        ref
            .read(outputRouterControllerProvider(kDefaultSessionId).notifier)
            .processInput(transformedData);
      }
      _sshDataSource!.writeString(transformedData);
    }
  }

  /// Escapes special characters for logging.
  String _escapeForLog(String data) {
    return data
        .replaceAll('\x7f', '<DEL>')
        .replaceAll('\x08', '<BS>')
        .replaceAll('\r', '<CR>')
        .replaceAll('\n', '<LF>')
        .replaceAll('\x1b', '<ESC>')
        .replaceAll('\x03', '<CTRL-C>')
        .replaceAll('\t', '<TAB>');
  }

  /// Connects to a remote host via SSH.
  ///
  /// Establishes the SSH connection and wires the terminal I/O.
  /// Returns [Right] on success, [Left] with [Failure] on error.
  Future<Either<Failure, void>> connectSSH(SSHConnectionConfig config) async {
    // Clean up any existing connection
    await disconnectSSH();

    // Create SSH data source
    _sshDataSource = SSHDataSource();

    // Attempt connection
    final result = await _sshDataSource!.connect(config);

    if (result.isLeft()) {
      await _sshDataSource?.close();
      _sshDataSource = null;
      return result;
    }

    // Wire SSH output to terminal (possibly via OutputRouter)
    final terminalConfig = ref.read(terminalConfigProvider);

    _outputSubscription = _sshDataSource!.output.listen((data) {
      // Decode UTF-8 properly - SSH sends UTF-8 encoded text
      final output = utf8.decode(data, allowMalformed: true);

      if (terminalConfig.enableSemanticBlocks) {
        // Route through OutputRouter for block detection
        // The OutputRouter will write to the terminal via its callback
        // Note: Uses kDefaultSessionId as legacy shared controller fallback
        ref
            .read(outputRouterControllerProvider(kDefaultSessionId).notifier)
            .processOutput(output);
      } else {
        // Classic mode: write directly to terminal
        state.write(output);
      }
    });

    // Re-attach the onOutput handler to the current terminal
    state.onOutput = _handleTerminalOutput;

    // Trigger remote AI detection after connection settles.
    // Delay by 1 second to let the SSH session stabilize before probing.
    _triggerRemoteAiDetection(config);

    return const Right(null);
  }

  /// Triggers remote AI detection after a successful SSH connection.
  ///
  /// Uses a cancellable [Timer] so that if the session disconnects before
  /// the timer fires, detection is skipped.
  // @telos L1:function:lib/features/terminal/presentation/providers:terminal_provider:_triggerRemoteAiDetection
  void _triggerRemoteAiDetection(SSHConnectionConfig config) {
    _detectionTimer?.cancel();
    final hostId = '${config.host}:${config.port}';

    _detectionTimer = Timer(const Duration(seconds: 1), () {
      _detectionTimer = null;

      final client = _sshDataSource?.client;
      if (client == null) {
        debugPrint(
          '[TerminalController] SSH client gone before detection for $hostId',
        );
        return;
      }

      debugPrint(
        '[TerminalController] Triggering AI detection for $hostId',
      );

      ref
          .read(remoteAiDetectionStateProvider(hostId).notifier)
          .detect(client)
          .then((result) {
        if (result.hasAnyProvider) {
          debugPrint(
            '[TerminalController] AI detected on $hostId: '
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

          // Force the bridge providers to re-evaluate so the global
          // AI service picks up the newly available remote service.
          ref.invalidate(activeRemoteAiServiceProvider);
          ref.invalidate(aiServiceControllerProvider);

          debugPrint(
            '[TerminalController] Invalidated aiServiceControllerProvider '
            'after remote service init for $hostId',
          );
        }
      }).catchError((Object e) {
        debugPrint('[TerminalController] AI detection failed for $hostId: $e');
      });
    });
  }

  /// Disconnects from the current SSH session.
  Future<void> disconnectSSH() async {
    _detectionTimer?.cancel();
    _detectionTimer = null;
    await _outputSubscription?.cancel();
    _outputSubscription = null;
    await _sshDataSource?.close();
    _sshDataSource = null;
  }

  /// Returns true if connected to an SSH session.
  bool get isSSHConnected => _sshDataSource?.isConnected ?? false;

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

/// Provides an xterm TerminalTheme from our color scheme.
@riverpod
TerminalTheme terminalTheme(
  TerminalThemeRef ref,
  Brightness brightness,
) {
  final colors = TerminalColors.forBrightness(brightness);

  return TerminalTheme(
    cursor: colors.cursor,
    selection: colors.selection,
    foreground: colors.foreground,
    background: colors.background,
    black: colors.black,
    red: colors.red,
    green: colors.green,
    yellow: colors.yellow,
    blue: colors.blue,
    magenta: colors.magenta,
    cyan: colors.cyan,
    white: colors.white,
    brightBlack: colors.brightBlack,
    brightRed: colors.brightRed,
    brightGreen: colors.brightGreen,
    brightYellow: colors.brightYellow,
    brightBlue: colors.brightBlue,
    brightMagenta: colors.brightMagenta,
    brightCyan: colors.brightCyan,
    brightWhite: colors.brightWhite,
    searchHitBackground: colors.selection,
    searchHitBackgroundCurrent: colors.yellow,
    searchHitForeground: colors.foreground,
  );
}
