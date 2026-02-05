// @telos L1:function:lib/features/terminal/domain/entities:terminal_block

import 'package:freezed_annotation/freezed_annotation.dart';

import 'block_status.dart';

part 'block.freezed.dart';
part 'block.g.dart';

/// A semantic block representing a command and its output.
///
/// Each block is a discrete, self-contained unit that can be collapsed,
/// expanded, searched, and navigated independently. This transforms the
/// chaotic terminal experience into an organized, structured interface.
///
/// Named `TerminalBlock` to avoid conflict with Drift-generated `Block` class.
@freezed
class TerminalBlock with _$TerminalBlock {
  const factory TerminalBlock({
    /// Unique identifier (UUID).
    required String id,

    /// Reference to parent session.
    required String sessionId,

    /// The command text entered by user.
    required String command,

    /// The command output including ANSI sequences.
    @Default('') String output,

    /// Current block status.
    @Default(BlockStatus.running) BlockStatus status,

    /// Process exit code when completed.
    int? exitCode,

    /// Timestamp when command was entered.
    required DateTime startedAt,

    /// Timestamp when command finished.
    DateTime? completedAt,

    /// Whether block is collapsed in UI.
    @Default(false) bool isCollapsed,

    /// Whether user manually expanded this block.
    /// When true, auto-collapse on new command won't affect this block.
    @Default(false) bool manuallyExpanded,

    /// Whether output was truncated in memory.
    @Default(false) bool isTruncated,

    /// Whether this block represents a TUI session (vim, htop, etc.).
    /// TUI session blocks don't capture output - they just record
    /// the command, duration, and exit status.
    @Default(false) bool isTuiSession,
  }) = _TerminalBlock;

  const TerminalBlock._();

  /// Creates a TerminalBlock from JSON.
  factory TerminalBlock.fromJson(Map<String, dynamic> json) =>
      _$TerminalBlockFromJson(json);

  /// Returns the execution duration if completed.
  Duration? get executionDuration {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt);
  }

  /// Returns the number of lines in the output.
  int get outputLineCount => output.split('\n').length;

  /// Returns true if this block is still running.
  bool get isRunning => status == BlockStatus.running;

  /// Returns true if this block completed (any terminal state).
  bool get isCompleted => status.isTerminal;
}
