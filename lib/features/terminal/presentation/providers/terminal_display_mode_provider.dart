// @telos L1:function:lib/features/terminal/presentation/providers:terminal_display_mode_provider

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/terminal_mode.dart';
import '../../domain/entities/tui_mode_state.dart';
import 'terminal_config_provider.dart';

part 'terminal_display_mode_provider.g.dart';

/// State for terminal display mode management.
///
/// Tracks the current display mode, previous mode (for returning from TUI),
/// and TUI-specific state when in TUI mode.
class TerminalDisplayModeState {
  const TerminalDisplayModeState({
    required this.currentMode,
    required this.previousMode,
    required this.tuiState,
  });

  /// Creates initial state based on whether semantic blocks are enabled.
  factory TerminalDisplayModeState.initial(
      {required bool enableSemanticBlocks}) {
    final mode =
        enableSemanticBlocks ? TerminalMode.blocks : TerminalMode.classic;
    return TerminalDisplayModeState(
      currentMode: mode,
      previousMode: mode,
      tuiState: const TuiModeState.inactive(),
    );
  }

  /// The current display mode.
  final TerminalMode currentMode;

  /// The previous mode before entering TUI mode.
  ///
  /// Used to return to the correct mode when exiting TUI.
  final TerminalMode previousMode;

  /// TUI-specific state when in TUI mode.
  final TuiModeState tuiState;

  /// Whether we're currently in TUI mode.
  bool get isInTuiMode => currentMode == TerminalMode.tui;

  /// Whether we're currently in blocks mode.
  bool get isInBlocksMode => currentMode == TerminalMode.blocks;

  /// Whether we're currently in classic mode.
  bool get isInClassicMode => currentMode == TerminalMode.classic;

  /// Create a copy with specified fields replaced.
  TerminalDisplayModeState copyWith({
    TerminalMode? currentMode,
    TerminalMode? previousMode,
    TuiModeState? tuiState,
  }) {
    return TerminalDisplayModeState(
      currentMode: currentMode ?? this.currentMode,
      previousMode: previousMode ?? this.previousMode,
      tuiState: tuiState ?? this.tuiState,
    );
  }

  @override
  String toString() =>
      'TerminalDisplayModeState(current: $currentMode, previous: $previousMode, tui: $tuiState)';
}

/// Manages terminal display mode state including automatic TUI mode transitions.
///
/// This provider handles:
/// - Tracking current display mode (blocks, tui, classic)
/// - Automatic transition to TUI mode when detected by TuiModeDetector
/// - Returning to previous mode when TUI exits
/// - Exposing TUI state for creating TUI session blocks
@Riverpod(keepAlive: true)
class TerminalDisplayMode extends _$TerminalDisplayMode {
  @override
  TerminalDisplayModeState build() {
    final config = ref.read(terminalConfigProvider);
    return TerminalDisplayModeState.initial(
      enableSemanticBlocks: config.enableSemanticBlocks,
    );
  }

  /// Enter TUI mode.
  ///
  /// Called by TuiModeDetector when smcup (alternate screen) is detected.
  /// Stores the current mode as previousMode so we can return to it later.
  void enterTuiMode({
    String? triggeringCommand,
    String? tuiBlockId,
  }) {
    if (state.isInTuiMode) return; // Already in TUI mode

    state = state.copyWith(
      previousMode: state.currentMode,
      currentMode: TerminalMode.tui,
      tuiState: TuiModeState.active(
        activatedAt: DateTime.now(),
        triggeringCommand: triggeringCommand,
        tuiBlockId: tuiBlockId,
      ),
    );
  }

  /// Exit TUI mode and return to the previous mode.
  ///
  /// Called by TuiModeDetector when rmcup (exit alternate screen) is detected.
  void exitTuiMode() {
    if (!state.isInTuiMode) return; // Not in TUI mode

    state = state.copyWith(
      currentMode: state.previousMode,
      tuiState: const TuiModeState.inactive(),
    );
  }

  /// Force exit TUI mode (e.g., on disconnect).
  ///
  /// Similar to exitTuiMode but used for abnormal exits like disconnection.
  void forceExitTuiMode() {
    if (!state.isInTuiMode) return;
    exitTuiMode();
  }

  /// Update the TUI state (e.g., to set the block ID after creation).
  void updateTuiState(TuiModeState Function(TuiModeState) update) {
    if (!state.isInTuiMode) return;
    state = state.copyWith(tuiState: update(state.tuiState));
  }

  /// Toggle between blocks and classic mode (only when not in TUI mode).
  void toggleSemanticBlocks() {
    if (state.isInTuiMode) return; // Can't toggle during TUI

    final newMode = state.currentMode == TerminalMode.blocks
        ? TerminalMode.classic
        : TerminalMode.blocks;

    state = state.copyWith(
      currentMode: newMode,
      previousMode: newMode,
    );
  }
}

/// Provides just the current display mode for simple watching.
@riverpod
TerminalMode currentTerminalMode(Ref ref) {
  return ref.watch(
    terminalDisplayModeProvider.select((state) => state.currentMode),
  );
}

/// Provides just the TUI state for TUI-specific UI.
@riverpod
TuiModeState currentTuiState(Ref ref) {
  return ref.watch(
    terminalDisplayModeProvider.select((state) => state.tuiState),
  );
}

/// Provides whether we're currently in TUI mode.
@riverpod
bool isInTuiMode(Ref ref) {
  return ref.watch(
    terminalDisplayModeProvider.select((state) => state.isInTuiMode),
  );
}
