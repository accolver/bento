// @telos L1:function:lib/features/terminal/presentation/providers:output_router_provider

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/services/output_router.dart';
import '../../data/services/prompt_detector.dart';
import 'block_provider.dart';
import 'terminal_config_provider.dart';
import 'terminal_provider.dart';

part 'output_router_provider.g.dart';

/// Provides an OutputRouter instance for the current session.
///
/// The OutputRouter intercepts terminal output, detects command boundaries,
/// and routes data to the BlockListController for semantic block display.
@Riverpod(keepAlive: true)
class OutputRouterController extends _$OutputRouterController {
  OutputRouter? _router;

  @override
  OutputRouter? build() {
    print('[OutputRouterController] build() called - creating new router');
    // Get dependencies
    // Use ref.read to avoid rebuilds - we only need the notifier reference once
    final blockController = ref.read(blockListControllerProvider.notifier);
    print(
        '[OutputRouterController] blockController hashCode: ${blockController.hashCode}');
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

    // Create output router
    _router = OutputRouter(
      blockController: blockController,
      promptDetector: promptDetector,
    );

    // Set up the terminal write callback automatically
    // This ensures output is written to terminal even if TerminalScreen hasn't initialized yet
    final terminal = ref.read(terminalControllerProvider);
    _router!.onProcessedOutput = (data) {
      print(
          '[OutputRouterController] Writing to terminal: ${data.length} chars');
      terminal.write(data);
    };
    print('[OutputRouterController] Terminal callback automatically set');

    // Clean up on dispose
    ref.onDispose(() {
      _router?.dispose();
    });

    return _router;
  }

  /// Processes incoming terminal output.
  ///
  /// Call this for each chunk of data received from SSH.
  void processOutput(String data) {
    print(
        '[OutputRouterController] processOutput called, router is ${_router == null ? "null" : "valid"}');
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
  void reset() {
    _router?.reset();
  }

  /// Sets a callback for processed output.
  ///
  /// This callback is invoked with raw output after processing,
  /// allowing it to be written to the xterm terminal.
  void setOutputCallback(void Function(String) callback) {
    print(
        '[OutputRouterController] setOutputCallback called, router is ${_router == null ? "null" : "valid"}');
    if (_router != null) {
      _router!.onProcessedOutput = callback;
      print('[OutputRouterController] Callback set on router');
    }
  }
}
