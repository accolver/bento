// @telos L1:function:lib/features/terminal/presentation/providers:tui_mode_detector_provider

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/services/tui_mode_detector.dart';
import 'terminal_display_mode_provider.dart';

part 'tui_mode_detector_provider.g.dart';

/// Provides a TuiModeDetector instance and wires it to state management.
///
/// This provider:
/// - Creates and manages a TuiModeDetector instance
/// - Listens to TUI mode events and updates TerminalDisplayModeProvider
/// - Exposes methods for processing terminal output
@Riverpod(keepAlive: true)
class TuiModeDetectorController extends _$TuiModeDetectorController {
  TuiModeDetector? _detector;
  StreamSubscription<TuiModeEvent>? _eventSubscription;

  @override
  TuiModeDetector build() {
    _detector = TuiModeDetector();

    // Listen to TUI mode events and update display mode provider
    _eventSubscription = _detector!.events.listen(_handleTuiModeEvent);

    // Clean up on dispose
    ref.onDispose(() {
      _eventSubscription?.cancel();
      _detector?.dispose();
    });

    return _detector!;
  }

  /// Handle TUI mode events by updating the display mode provider.
  void _handleTuiModeEvent(TuiModeEvent event) {
    final displayModeController =
        ref.read(terminalDisplayModeProvider.notifier);

    switch (event) {
      case TuiModeActivated(:final triggeringCommand):
        displayModeController.enterTuiMode(
          triggeringCommand: triggeringCommand,
        );
      case TuiModeDeactivated():
        displayModeController.exitTuiMode();
    }
  }

  /// Process terminal output, checking for TUI mode escape sequences.
  ///
  /// Call this with each chunk of terminal output data.
  void processOutput(Uint8List data) {
    _detector?.processOutput(data);
  }

  /// Process terminal output from a string.
  void processOutputString(String data) {
    _detector?.processOutputString(data);
  }

  /// Set the last command for triggering command detection.
  void setLastCommand(String command) {
    _detector?.setLastCommand(command);
  }

  /// Force deactivate TUI mode (e.g., on disconnect).
  void forceDeactivate() {
    _detector?.forceDeactivate();
  }

  /// Reset the detector state.
  void reset() {
    _detector?.reset();
  }

  /// Whether TUI mode is currently active.
  bool get isActive => _detector?.isActive ?? false;
}

/// Provides whether TUI mode is currently active from the detector.
@riverpod
bool isTuiModeActive(Ref ref) {
  final detector = ref.watch(tuiModeDetectorControllerProvider);
  return detector.isActive;
}
