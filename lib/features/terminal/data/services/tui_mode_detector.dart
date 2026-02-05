// @telos L1:function:lib/features/terminal/data/services:tui_mode_detector

import 'dart:async';
import 'dart:typed_data';

/// Event emitted when TUI mode changes.
sealed class TuiModeEvent {
  const TuiModeEvent();
}

/// TUI mode activated (smcup detected).
class TuiModeActivated extends TuiModeEvent {
  const TuiModeActivated({this.triggeringCommand});

  /// The command that triggered TUI mode, if known.
  final String? triggeringCommand;
}

/// TUI mode deactivated (rmcup detected).
class TuiModeDeactivated extends TuiModeEvent {
  const TuiModeDeactivated();
}

/// Detects TUI (Terminal User Interface) mode by monitoring for alternate
/// screen buffer escape sequences.
///
/// TUI applications like vim, htop, less, and Claude Code use the alternate
/// screen buffer (DECSET 1049) to take over the entire terminal display.
/// This detector monitors output for:
/// - smcup: `\x1b[?1049h` - Enter alternate screen buffer
/// - rmcup: `\x1b[?1049l` - Exit alternate screen buffer
///
/// Features:
/// - Byte-level detection (handles encoding correctly)
/// - Lookback buffer for sequences split across chunks
/// - Debounce to suppress false positives from rapid smcup/rmcup pairs
/// - Stream-based notification of mode changes
class TuiModeDetector {
  TuiModeDetector({
    this.debounceDuration = const Duration(milliseconds: 100),
  });

  /// Duration to wait before confirming smcup to filter false positives.
  final Duration debounceDuration;

  /// smcup: Enter alternate screen buffer (DECSET 1049)
  /// ESC [ ? 1 0 4 9 h
  static const smcupSequence = <int>[
    0x1B,
    0x5B,
    0x3F,
    0x31,
    0x30,
    0x34,
    0x39,
    0x68
  ];

  /// rmcup: Exit alternate screen buffer (DECSET 1049 reset)
  /// ESC [ ? 1 0 4 9 l
  static const rmcupSequence = <int>[
    0x1B,
    0x5B,
    0x3F,
    0x31,
    0x30,
    0x34,
    0x39,
    0x6C
  ];

  /// Current TUI mode state.
  bool _isActive = false;

  /// Timer for debouncing smcup detection.
  Timer? _debounceTimer;

  /// Lookback buffer for handling sequences split across chunks.
  /// Stores the last N bytes where N = sequence length - 1.
  final _lookbackBuffer = <int>[];

  /// Stream controller for mode change events.
  final _eventController = StreamController<TuiModeEvent>.broadcast();

  /// The last command that was executed (for triggering command detection).
  String? _lastCommand;

  /// Pending activation flag (during debounce period).
  bool _pendingActivation = false;

  /// Whether TUI mode is currently active.
  bool get isActive => _isActive;

  /// Stream of TUI mode change events.
  Stream<TuiModeEvent> get events => _eventController.stream;

  /// Set the last command (for triggering command detection).
  void setLastCommand(String command) {
    _lastCommand = command;
  }

  /// Process output data, checking for TUI mode escape sequences.
  ///
  /// Call this with each chunk of terminal output. The detector will
  /// emit events on the [events] stream when mode changes are detected.
  void processOutput(Uint8List data) {
    // Combine lookback buffer with new data for complete checking
    final combined = [..._lookbackBuffer, ...data];

    // Search for sequences in combined data
    for (var i = 0; i < combined.length; i++) {
      // Check for smcup (enter TUI mode)
      if (_matchesSequence(combined, i, smcupSequence)) {
        _handleSmcupDetected();
        i += smcupSequence.length - 1; // Skip past the sequence
      }
      // Check for rmcup (exit TUI mode)
      else if (_matchesSequence(combined, i, rmcupSequence)) {
        _handleRmcupDetected();
        i += rmcupSequence.length - 1; // Skip past the sequence
      }
    }

    // Update lookback buffer with end of current data
    _updateLookbackBuffer(data);
  }

  /// Process output from a string (convenience method).
  void processOutputString(String data) {
    processOutput(Uint8List.fromList(data.codeUnits));
  }

  /// Check if a sequence matches at the given position in data.
  bool _matchesSequence(List<int> data, int startIndex, List<int> sequence) {
    if (startIndex + sequence.length > data.length) return false;

    for (var i = 0; i < sequence.length; i++) {
      if (data[startIndex + i] != sequence[i]) return false;
    }
    return true;
  }

  /// Update the lookback buffer with the end of the data.
  void _updateLookbackBuffer(Uint8List data) {
    _lookbackBuffer.clear();

    // Keep the last (sequence.length - 1) bytes for split sequence detection
    final maxLookback = smcupSequence.length - 1;
    if (data.length >= maxLookback) {
      _lookbackBuffer.addAll(data.sublist(data.length - maxLookback));
    } else {
      _lookbackBuffer.addAll(data);
    }
  }

  /// Handle smcup detection.
  void _handleSmcupDetected() {
    if (_isActive) return; // Already in TUI mode

    // Cancel any pending deactivation
    _debounceTimer?.cancel();

    // Start debounce timer for activation
    _pendingActivation = true;
    _debounceTimer = Timer(debounceDuration, () {
      if (_pendingActivation) {
        _activateTuiMode();
      }
    });
  }

  /// Handle rmcup detection.
  void _handleRmcupDetected() {
    // If we have a pending activation (rapid smcup/rmcup), cancel it
    if (_pendingActivation) {
      _pendingActivation = false;
      _debounceTimer?.cancel();
      return;
    }

    if (!_isActive) return; // Not in TUI mode

    _deactivateTuiMode();
  }

  /// Activate TUI mode and emit event.
  void _activateTuiMode() {
    _pendingActivation = false;
    _isActive = true;
    _eventController.add(TuiModeActivated(triggeringCommand: _lastCommand));
  }

  /// Deactivate TUI mode and emit event.
  void _deactivateTuiMode() {
    _isActive = false;
    _eventController.add(const TuiModeDeactivated());
  }

  /// Force deactivate TUI mode (e.g., on disconnect).
  void forceDeactivate() {
    _debounceTimer?.cancel();
    _pendingActivation = false;

    if (_isActive) {
      _deactivateTuiMode();
    }
  }

  /// Reset the detector state.
  void reset() {
    _debounceTimer?.cancel();
    _pendingActivation = false;
    _isActive = false;
    _lookbackBuffer.clear();
    _lastCommand = null;
  }

  /// Dispose of resources.
  void dispose() {
    _debounceTimer?.cancel();
    _eventController.close();
  }
}
