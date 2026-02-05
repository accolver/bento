// @telos L1:function:lib/features/terminal/domain/entities:block_status

/// Status of a terminal block.
///
/// Each block progresses through states:
/// - [running]: Command is currently executing
/// - [success]: Command completed with exit code 0
/// - [failed]: Command completed with non-zero exit code
/// - [cancelled]: Command was interrupted (e.g., Ctrl+C)
enum BlockStatus {
  /// Command is currently executing.
  running,

  /// Command completed successfully (exit code 0).
  success,

  /// Command completed with an error (non-zero exit code).
  failed,

  /// Command was interrupted by the user.
  cancelled,
}

/// Extension methods for [BlockStatus].
extension BlockStatusExtension on BlockStatus {
  /// Returns true if this status represents a terminal (final) state.
  bool get isTerminal => this != BlockStatus.running;

  /// Returns true if this status represents an error state.
  bool get isError =>
      this == BlockStatus.failed || this == BlockStatus.cancelled;

  /// Returns a human-readable label for this status.
  String get label {
    switch (this) {
      case BlockStatus.running:
        return 'Running';
      case BlockStatus.success:
        return 'Success';
      case BlockStatus.failed:
        return 'Failed';
      case BlockStatus.cancelled:
        return 'Cancelled';
    }
  }
}
