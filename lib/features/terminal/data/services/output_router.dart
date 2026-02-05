// @telos L1:function:lib/features/terminal/data/services:output_router

import 'dart:async';

import '../../domain/entities/block_status.dart';
import '../../presentation/providers/block_provider.dart';
import 'prompt_detector.dart';

/// Routes terminal output to semantic blocks.
///
/// Intercepts terminal output, detects command/output boundaries using
/// prompt detection, and routes data to the [BlockListController].
/// Implements output buffering for efficient batch updates.
class OutputRouter {
  OutputRouter({
    required BlockListController blockController,
    PromptDetector? promptDetector,
    Duration bufferDuration = const Duration(milliseconds: 16),
  })  : _blockController = blockController,
        _promptDetector = promptDetector ?? PromptDetector(),
        _bufferDuration = bufferDuration;

  final BlockListController _blockController;
  final PromptDetector _promptDetector;
  final Duration _bufferDuration;

  /// Buffer for collecting output before flushing.
  final StringBuffer _outputBuffer = StringBuffer();

  /// Timer for flushing buffered output.
  Timer? _flushTimer;

  /// Last detected command for deduplication.
  /// We track the command (not the full line) to avoid duplicates from
  /// terminal echo or slight formatting differences.
  String? _lastCommand;

  /// Callback for processed output (to write to terminal).
  void Function(String)? onProcessedOutput;

  /// Processes incoming output from SSH/PTY.
  ///
  /// Detects prompts, creates blocks for commands, and buffers output
  /// for efficient updates. Call this for each chunk of data received.
  void processOutput(String data) {
    print('[OutputRouter] processOutput called with ${data.length} chars');
    print(
        '[OutputRouter] data: ${data.replaceAll('\n', '\\n').replaceAll('\r', '\\r')}');

    // Normalize line endings and split into lines for prompt detection
    // Terminals may use \r\n (CRLF), \n (LF), or just \r (CR)
    final normalizedData = data.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalizedData.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isLastLine = i == lines.length - 1;

      // Check for prompt
      final promptResult = _promptDetector.detectPrompt(line);
      print(
          '[OutputRouter] Line $i: "${line.replaceAll('\r', '\\r')}" -> hasPrompt: ${promptResult.hasPrompt}, command: ${promptResult.command}');

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
        if (promptResult.command != null && promptResult.command!.isNotEmpty) {
          // Only skip if this exact command just appeared (echo from typing)
          // This happens when terminal echoes back what you typed on same line
          print(
              '[OutputRouter] Command found: "${promptResult.command}", lastCommand: "$_lastCommand"');
          if (promptResult.command != _lastCommand) {
            print(
                '[OutputRouter] Creating block for command: ${promptResult.command}');
            _lastCommand = promptResult.command;
            _blockController.createBlock(promptResult.command!);
          } else {
            print('[OutputRouter] Skipping duplicate command');
          }
        } else {
          // Just a prompt without command - ready for new input
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

    // Forward raw output to terminal (if callback set)
    print(
        '[OutputRouter] Forwarding to terminal callback, callback is ${onProcessedOutput == null ? "null" : "set"}');
    onProcessedOutput?.call(data);
  }

  /// Processes user input (keystrokes).
  ///
  /// Detects when user types a command at the prompt.
  /// Call this before sending input to SSH.
  void processInput(String data) {
    // If user presses Enter and we have input, could be a command
    // But typically we detect commands from the output (echo)

    // Detect Ctrl+C for cancellation
    if (data == '\x03') {
      // Ctrl+C
      if (_blockController.hasActiveBlock) {
        _blockController.completeBlock(status: BlockStatus.cancelled);
      }
    }
  }

  /// Flushes buffered output to the active block.
  void _flushBuffer() {
    _flushTimer?.cancel();
    _flushTimer = null;

    if (_outputBuffer.isEmpty) return;

    final output = _outputBuffer.toString();
    _outputBuffer.clear();

    if (_blockController.hasActiveBlock) {
      _blockController.appendOutput(output);
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
    _lastCommand = null;
  }

  /// Disposes resources.
  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  /// Creates an output router with custom prompt patterns.
  OutputRouter withCustomPatterns(List<String> patterns) {
    return OutputRouter(
      blockController: _blockController,
      promptDetector: _promptDetector.withCustomPatterns(patterns),
      bufferDuration: _bufferDuration,
    );
  }
}
