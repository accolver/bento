// @telos L1:function:lib/features/terminal/domain/entities:tui_mode_state

import 'package:equatable/equatable.dart';

/// State representing the current TUI mode detection state.
///
/// Tracks whether a TUI application is currently active (using alternate
/// screen buffer) and associated metadata for creating TUI session blocks.
class TuiModeState extends Equatable {
  const TuiModeState({
    required this.isActive,
    this.activatedAt,
    this.triggeringCommand,
    this.tuiBlockId,
  });

  /// Creates an inactive TUI mode state.
  const TuiModeState.inactive()
      : isActive = false,
        activatedAt = null,
        triggeringCommand = null,
        tuiBlockId = null;

  /// Creates an active TUI mode state.
  factory TuiModeState.active({
    required DateTime activatedAt,
    String? triggeringCommand,
    String? tuiBlockId,
  }) {
    return TuiModeState(
      isActive: true,
      activatedAt: activatedAt,
      triggeringCommand: triggeringCommand,
      tuiBlockId: tuiBlockId,
    );
  }

  /// Whether TUI mode is currently active.
  ///
  /// True when a TUI application has entered alternate screen buffer mode
  /// (smcup/DECSET 1049) and not yet exited (rmcup).
  final bool isActive;

  /// Timestamp when TUI mode was activated.
  ///
  /// Null when [isActive] is false.
  final DateTime? activatedAt;

  /// The command that triggered TUI mode, if known.
  ///
  /// This is typically the last command executed before smcup was detected.
  /// May be null if the triggering command couldn't be determined.
  final String? triggeringCommand;

  /// The ID of the TUI session block created for this TUI session.
  ///
  /// Used to update the block when TUI mode exits.
  final String? tuiBlockId;

  /// Returns the duration since TUI mode was activated.
  ///
  /// Returns null if TUI mode is not active.
  Duration? get elapsedDuration {
    if (!isActive || activatedAt == null) return null;
    return DateTime.now().difference(activatedAt!);
  }

  /// Creates a copy with the specified fields replaced.
  TuiModeState copyWith({
    bool? isActive,
    DateTime? activatedAt,
    String? triggeringCommand,
    String? tuiBlockId,
  }) {
    return TuiModeState(
      isActive: isActive ?? this.isActive,
      activatedAt: activatedAt ?? this.activatedAt,
      triggeringCommand: triggeringCommand ?? this.triggeringCommand,
      tuiBlockId: tuiBlockId ?? this.tuiBlockId,
    );
  }

  /// Creates an inactive state from this state, preserving nothing.
  TuiModeState deactivate() => const TuiModeState.inactive();

  @override
  List<Object?> get props =>
      [isActive, activatedAt, triggeringCommand, tuiBlockId];

  @override
  String toString() {
    if (!isActive) return 'TuiModeState(inactive)';
    return 'TuiModeState(active, command: $triggeringCommand, since: $activatedAt)';
  }
}
