// @telos L1:function:lib/features/terminal/data/services:output_router

import 'dart:async';
import 'dart:typed_data';

import '../../domain/entities/block_status.dart';
import '../../presentation/providers/block_provider.dart';
import 'ansi_stripper.dart';
import 'prompt_detector.dart';
import 'tui_mode_detector.dart';

/// Routes terminal output to semantic blocks.
///
/// Intercepts terminal output, detects command/output boundaries using
/// prompt detection, and routes data to the [BlockListController].
/// Implements output buffering for efficient batch updates.
///
/// Also integrates with [TuiModeDetector] to pause block processing
/// when a TUI application (vim, htop, etc.) is active.
class OutputRouter {
  OutputRouter({
    required BlockListController blockController,
    PromptDetector? promptDetector,
    TuiModeDetector? tuiModeDetector,
    Duration bufferDuration = const Duration(milliseconds: 16),
  })  : _blockController = blockController,
        _promptDetector = promptDetector ?? PromptDetector(),
        _tuiModeDetector = tuiModeDetector,
        _bufferDuration = bufferDuration {
    // Listen to TUI mode events if detector is provided
    _tuiModeSubscription = _tuiModeDetector?.events.listen(_handleTuiModeEvent);
  }

  final BlockListController _blockController;
  final PromptDetector _promptDetector;
  final TuiModeDetector? _tuiModeDetector;
  final Duration _bufferDuration;

  /// Subscription to TUI mode events.
  StreamSubscription<TuiModeEvent>? _tuiModeSubscription;

  /// Buffer for collecting output before flushing.
  final StringBuffer _outputBuffer = StringBuffer();

  /// Timer for flushing buffered output.
  Timer? _flushTimer;

  /// Last detected command for deduplication.
  /// We track the command (not the full line) to avoid duplicates from
  /// terminal echo or slight formatting differences.
  String? _lastCommand;

  /// Buffer for user input (keystrokes before Enter).
  final StringBuffer _inputBuffer = StringBuffer();

  /// Whether we've seen a prompt and are ready for user input.
  bool _atPrompt = false;

  /// Whether block detection is paused (e.g., during TUI mode).
  bool _isPaused = false;

  /// Callback for processed output (to write to terminal).
  void Function(String)? onProcessedOutput;

  /// Callback when a command is submitted (Enter pressed).
  /// Used to dismiss the keyboard after sending a command.
  void Function()? onCommandSubmitted;

  /// Callback when TUI mode is detected.
  /// Called with the triggering command (if known) when smcup is detected.
  void Function(String?)? onTuiModeEnter;

  /// Callback when TUI mode ends.
  /// Called when rmcup is detected.
  void Function()? onTuiModeExit;

  /// Whether block detection is currently paused.
  bool get isPaused => _isPaused;

  /// Whether we're currently in TUI mode.
  bool get isInTuiMode => _tuiModeDetector?.isActive ?? false;

  /// Processes incoming output from SSH/PTY.
  ///
  /// Detects prompts, creates blocks for commands, and buffers output
  /// for efficient updates. Call this for each chunk of data received.
  ///
  /// Also monitors for TUI mode escape sequences and pauses block
  /// processing during TUI mode.
  void processOutput(String data) {
    // Check for TUI mode transitions (before any other processing)
    _checkTuiModeTransitions(data);

    // Forward raw output to terminal (always, regardless of pause state)
    onProcessedOutput?.call(data);

    // If paused (TUI mode active), skip block processing
    if (_isPaused) {
      return;
    }

    // Normalize line endings and split into lines for prompt detection
    // Terminals may use \r\n (CRLF), \n (LF), or just \r (CR)
    final normalizedData = data.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalizedData.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isLastLine = i == lines.length - 1;

      // Check for prompt
      final promptResult = _promptDetector.detectPrompt(line);

      if (promptResult.hasPrompt) {
        // Complete any running block when we see a new prompt
        if (_blockController.hasActiveBlock) {
          // Capture buffer content before flush for exit code detection
          final bufferContent = _outputBuffer.toString();
          _flushBuffer();
          _completeActiveBlock(line, bufferContent);
          // Clear last command after completing a block so same command can run again
          _lastCommand = null;
        } else {
          _flushBuffer();
        }

        // If there's a command on this line, create a new block
        // (This handles cases where the shell echoes the full prompt+command)
        if (promptResult.command != null && promptResult.command!.isNotEmpty) {
          // Only skip if this exact command just appeared (echo from typing)
          // This happens when terminal echoes back what you typed on same line
          if (promptResult.command != _lastCommand) {
            _lastCommand = promptResult.command;
            _blockController.createBlock(promptResult.command!);
            _atPrompt = false;
          }
        } else {
          // Just a prompt without command - ready for new input
          _atPrompt = true;
          _inputBuffer.clear(); // Clear any stale input
          _lastCommand = null;
        }
      } else if (_blockController.hasActiveBlock) {
        // Not a prompt line - add to buffer for current block
        if (isLastLine && line.isEmpty) {
          // Don't add trailing empty line
        } else {
          _outputBuffer.write(line);
          if (!isLastLine) {
            _outputBuffer.write('\n');
          }
        }
      }
    }

    // Schedule flush if we have buffered content
    if (_outputBuffer.isNotEmpty) {
      _scheduleFlush();
    }
  }

  /// Check for TUI mode transitions in the output data.
  void _checkTuiModeTransitions(String data) {
    if (_tuiModeDetector == null) return;

    // Convert string to bytes for TUI detector
    final bytes = Uint8List.fromList(data.codeUnits);

    // Just pass data to detector - events will be handled by _handleTuiModeEvent
    _tuiModeDetector.processOutput(bytes);
  }

  /// Handle TUI mode events from the detector.
  void _handleTuiModeEvent(TuiModeEvent event) {
    switch (event) {
      case TuiModeActivated(:final triggeringCommand):
        _enterTuiMode(triggeringCommand);
      case TuiModeDeactivated():
        _exitTuiMode();
    }
  }

  /// Called when entering TUI mode (smcup detected).
  void _enterTuiMode([String? triggeringCommand]) {
    _isPaused = true;

    // Flush any pending output before pausing
    _flushBuffer();

    // Notify callback with the triggering command from detector or fallback
    onTuiModeEnter?.call(triggeringCommand ?? _lastCommand);
  }

  /// Called when exiting TUI mode (rmcup detected).
  void _exitTuiMode() {
    _isPaused = false;

    // Notify callback
    onTuiModeExit?.call();
  }

  /// Pause block detection (manually, if not using TUI detection).
  void pause() {
    _isPaused = true;
    _flushBuffer();
  }

  /// Resume block detection.
  void resume() {
    _isPaused = false;
  }

  /// Processes user input (keystrokes).
  ///
  /// Tracks keystrokes to build up the command being typed.
  /// When Enter is pressed, creates a block for the command.
  /// Call this before sending input to SSH.
  void processInput(String data) {
    // Detect Ctrl+C for cancellation
    if (data == '\x03') {
      _inputBuffer.clear();
      if (_blockController.hasActiveBlock) {
        _blockController.completeBlock(status: BlockStatus.cancelled);
      }
      return;
    }

    // Detect Enter key (creates a block)
    if (data == '\r' || data == '\n' || data == '\r\n') {
      final command = _inputBuffer.toString().trim();
      _inputBuffer.clear();

      if (command.isNotEmpty && _atPrompt) {
        _lastCommand = command;
        _blockController.createBlock(command);
        _atPrompt = false; // We're now running a command, not at prompt

        // Notify that command was submitted (for keyboard dismissal)
        onCommandSubmitted?.call();
      }
      return;
    }

    // Detect backspace/delete
    if (data == '\x7f' || data == '\x08') {
      // Remove last character from buffer
      final current = _inputBuffer.toString();
      if (current.isNotEmpty) {
        _inputBuffer.clear();
        _inputBuffer.write(current.substring(0, current.length - 1));
      }
      return;
    }

    // Detect Ctrl+U (clear line)
    if (data == '\x15') {
      _inputBuffer.clear();
      return;
    }

    // Detect Ctrl+W (delete word)
    if (data == '\x17') {
      final current = _inputBuffer.toString().trimRight();
      final lastSpace = current.lastIndexOf(' ');
      _inputBuffer.clear();
      if (lastSpace > 0) {
        _inputBuffer.write(current.substring(0, lastSpace + 1));
      }
      return;
    }

    // Skip other control characters and escape sequences
    if (data.startsWith('\x1b') ||
        data.codeUnits.any((c) => c < 32 && c != 9)) {
      // Allow tab (9) but skip other control chars and escape sequences
      return;
    }

    // Regular character - add to buffer if we're at a prompt
    if (_atPrompt) {
      _inputBuffer.write(data);
    }
  }

  /// Flushes buffered output to the active block.
  void _flushBuffer() {
    _flushTimer?.cancel();
    _flushTimer = null;

    if (_outputBuffer.isEmpty) return;

    final rawOutput = _outputBuffer.toString();
    _outputBuffer.clear();

    if (_blockController.hasActiveBlock) {
      // Strip ANSI escape codes before storing in block
      // This removes colors, OSC sequences (shell integration), etc.
      // The terminal view shows the styled output; blocks show clean text
      final cleanOutput = AnsiStripper.strip(rawOutput);
      _blockController.appendOutput(cleanOutput);
    }
  }

  /// Schedules a buffer flush after the buffer duration.
  void _scheduleFlush() {
    _flushTimer ??= Timer(_bufferDuration, _flushBuffer);
  }

  /// Completes the active block, attempting to detect exit code.
  void _completeActiveBlock(String promptLine, String bufferContent) {
    // Try to detect exit code from recent output or prompt
    var exitCode = _promptDetector.detectExitCode(bufferContent);
    exitCode ??= _promptDetector.detectExitCode(promptLine);

    // Determine status based on exit code
    BlockStatus status;
    if (exitCode != null) {
      status = exitCode == 0 ? BlockStatus.success : BlockStatus.failed;
    } else {
      // Default to success if we can't determine
      status = BlockStatus.success;
    }

    // Check for cancellation indicators
    if (_promptDetector.detectCancellation(bufferContent)) {
      status = BlockStatus.cancelled;
    }

    _blockController.completeBlock(status: status, exitCode: exitCode);
  }

  /// Resets the router state.
  ///
  /// Call when starting a new session or disconnecting.
  void reset() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _outputBuffer.clear();
    _inputBuffer.clear();
    _lastCommand = null;
    _atPrompt = false;
    _isPaused = false;
    _tuiModeDetector?.reset();
  }

  /// Disposes resources.
  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _tuiModeSubscription?.cancel();
    _tuiModeSubscription = null;
  }

  /// Creates an output router with custom prompt patterns.
  OutputRouter withCustomPatterns(List<String> patterns) {
    return OutputRouter(
      blockController: _blockController,
      promptDetector: _promptDetector.withCustomPatterns(patterns),
      tuiModeDetector: _tuiModeDetector,
      bufferDuration: _bufferDuration,
    );
  }

  /// Set the last command hint for TUI mode detection.
  ///
  /// Call this when a command is about to be executed so the TUI detector
  /// can capture the triggering command.
  void setLastCommandHint(String command) {
    _lastCommand = command;
    _tuiModeDetector?.setLastCommand(command);
  }
}
