// @telos L1:function:lib/database/tables:blocks

import 'package:drift/drift.dart';

/// Table for storing terminal blocks.
///
/// Each block represents a command/output pair in a terminal session.
/// Output is stored as compressed blob to save space for large outputs.
class Blocks extends Table {
  /// Auto-incrementing primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Reference to parent session (will be foreign key when sessions added).
  TextColumn get sessionId => text()();

  /// The command text entered by user.
  TextColumn get command => text()();

  /// The command output (gzip compressed).
  BlobColumn get output => blob()();

  /// Block status: 'running', 'success', 'failed', 'cancelled'.
  TextColumn get status => text()();

  /// Process exit code when completed (nullable).
  IntColumn get exitCode => integer().nullable()();

  /// Timestamp when command was entered (milliseconds since epoch).
  IntColumn get startedAt => integer()();

  /// Timestamp when command finished (milliseconds since epoch, nullable).
  IntColumn get completedAt => integer().nullable()();

  /// Whether block is collapsed in UI.
  BoolColumn get isCollapsed => boolean().withDefault(const Constant(false))();

  /// Whether this block represents a TUI session (vim, htop, etc.).
  BoolColumn get isTuiSession => boolean().withDefault(const Constant(false))();
}
