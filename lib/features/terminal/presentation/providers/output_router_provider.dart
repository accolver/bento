// @telos L1:function:lib/features/terminal/presentation/providers:output_router_provider

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/services/output_router.dart';
import '../../data/services/prompt_detector.dart';
import '../../data/services/tui_mode_detector.dart';
import '../../../session/presentation/providers/session_terminal_controller.dart';
import 'block_provider.dart';
import 'terminal_config_provider.dart';
import 'terminal_display_mode_provider.dart';

part 'output_router_provider.g.dart';

/// Provides an OutputRouter instance for a specific session.
///
/// The OutputRouter intercepts terminal output, detects command boundaries,
/// and routes data to the BlockListController for semantic block display.
/// Also handles TUI mode detection and automatic pause/resume of block processing.
///
/// Uses family pattern keyed on sessionId so each session has
/// its own independent output router.
@Riverpod(keepAlive: true)
class OutputRouterController extends _$OutputRouterController {
  OutputRouter? _router;
  TuiModeDetector? _tuiModeDetector;

  @override
  OutputRouter? build(String sessionId) {
    // Get dependencies - use per-session block controller
    // Use ref.read instead of ref.watch to avoid rebuilds - we only need the notifier reference once
    final blockController =
        ref.read(blockListControllerProvider(sessionId).notifier);
    final config = ref.read(terminalConfigProvider);

    // Create prompt detector with custom patterns if configured
    PromptDetector promptDetector;
    if (config.customPromptPatterns.isNotEmpty) {
      promptDetector = PromptDetector().withCustomPatterns(
        config.customPromptPatterns,
      );
    } else {
      promptDetector = PromptDetector();
    }

    // Create TUI mode detector
    _tuiModeDetector = TuiModeDetector();

    // Create output router with TUI mode detection
    _router = OutputRouter(
      blockController: blockController,
      promptDetector: promptDetector,
      tuiModeDetector: _tuiModeDetector,
    );

    // Set up the terminal write callback automatically
    // This ensures output is written to terminal even if TerminalScreen hasn't initialized yet
    final terminal = ref.read(sessionTerminalControllerProvider(sessionId));
    _router!.onProcessedOutput = (data) {
      terminal.write(data);
    };

    // Wire up TUI mode callbacks to update display mode provider and create blocks
    _router!.onTuiModeEnter = (triggeringCommand) {
      // Update display mode state
      ref.read(terminalDisplayModeProvider.notifier).enterTuiMode(
            triggeringCommand: triggeringCommand,
          );
      // Create a TUI session block to record this session
      ref
          .read(blockListControllerProvider(sessionId).notifier)
          .createTuiSessionBlock(triggeringCommand);
    };
    _router!.onTuiModeExit = () {
      // Complete the TUI session block
      ref
          .read(blockListControllerProvider(sessionId).notifier)
          .completeTuiSessionBlock();
      // Update display mode state
      ref.read(terminalDisplayModeProvider.notifier).exitTuiMode();
    };

    // Clean up on dispose
    ref.onDispose(() {
      _router?.dispose();
      _tuiModeDetector?.dispose();
    });

    return _router;
  }

  /// Processes incoming terminal output.
  ///
  /// Call this for each chunk of data received from SSH.
  void processOutput(String data) {
    _router?.processOutput(data);
  }

  /// Processes user input.
  ///
  /// Call this before sending input to SSH (for Ctrl+C detection).
  void processInput(String data) {
    _router?.processInput(data);
  }

  /// Resets the router state.
  ///
  /// Call when starting a new session or disconnecting.
  /// Also cancels any active TUI session to properly record interruption.
  void reset() {
    // Cancel any active TUI session before resetting
    ref
        .read(blockListControllerProvider(sessionId).notifier)
        .cancelActiveTuiSession();
    _router?.reset();
  }

  /// Sets a callback for processed output.
  ///
  /// This callback is invoked with raw output after processing,
  /// allowing it to be written to the xterm terminal.
  void setOutputCallback(void Function(String) callback) {
    if (_router != null) {
      _router!.onProcessedOutput = callback;
    }
  }

  /// Sets a callback for when a command is submitted.
  ///
  /// This is called when the user presses Enter after typing a command.
  /// Useful for dismissing the keyboard.
  void setCommandSubmittedCallback(void Function() callback) {
    _router?.onCommandSubmitted = callback;
  }

  /// Whether the router is currently paused (e.g., during TUI mode).
  bool get isPaused => _router?.isPaused ?? false;

  /// Whether we're currently in TUI mode.
  bool get isInTuiMode => _router?.isInTuiMode ?? false;

  /// Manually pause block detection.
  void pause() {
    _router?.pause();
  }

  /// Manually resume block detection.
  void resume() {
    _router?.resume();
  }
}
