// @telos L1:function:lib/features/terminal/data/repositories:block_repository

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/database.dart';
import '../../domain/entities/block.dart';
import '../../domain/entities/block_status.dart';

/// Repository for managing TerminalBlock persistence.
///
/// Handles CRUD operations for blocks in the SQLite database.
/// Output is compressed using gzip to save space.
class BlockRepository {
  BlockRepository(this._db);

  final BentoDatabase _db;

  /// Saves a block to the database.
  ///
  /// Compresses the output using gzip before storage.
  Future<int> saveBlock(TerminalBlock block) async {
    final compressedOutput = _compressOutput(block.output);

    return _db.into(_db.blocks).insert(
          BlocksCompanion.insert(
            sessionId: block.sessionId,
            command: block.command,
            output: compressedOutput,
            status: block.status.name,
            exitCode: Value(block.exitCode),
            startedAt: block.startedAt.millisecondsSinceEpoch,
            completedAt: Value(block.completedAt?.millisecondsSinceEpoch),
            isCollapsed: Value(block.isCollapsed),
            isTuiSession: Value(block.isTuiSession),
          ),
        );
  }

  /// Updates an existing block in the database.
  Future<bool> updateBlock(TerminalBlock block) async {
    final compressedOutput = _compressOutput(block.output);

    // We need the database ID - for now, we'll use sessionId + startedAt as unique
    // In production, you'd track the database ID in the TerminalBlock entity
    final count = await (_db.update(_db.blocks)
          ..where((t) =>
              t.sessionId.equals(block.sessionId) &
              t.startedAt.equals(block.startedAt.millisecondsSinceEpoch)))
        .write(
      BlocksCompanion(
        command: Value(block.command),
        output: Value(compressedOutput),
        status: Value(block.status.name),
        exitCode: Value(block.exitCode),
        completedAt: Value(block.completedAt?.millisecondsSinceEpoch),
        isCollapsed: Value(block.isCollapsed),
        isTuiSession: Value(block.isTuiSession),
      ),
    );

    return count > 0;
  }

  /// Loads all blocks for a session.
  ///
  /// Decompresses output for each block.
  Future<List<TerminalBlock>> getBlocksForSession(String sessionId) async {
    final rows = await (_db.select(_db.blocks)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
        .get();

    return rows.map(_rowToBlock).toList();
  }

  /// Gets a single block by session and start time.
  Future<TerminalBlock?> getBlock(String sessionId, DateTime startedAt) async {
    final row = await (_db.select(_db.blocks)
          ..where((t) =>
              t.sessionId.equals(sessionId) &
              t.startedAt.equals(startedAt.millisecondsSinceEpoch)))
        .getSingleOrNull();

    return row != null ? _rowToBlock(row) : null;
  }

  /// Deletes a block from the database.
  Future<bool> deleteBlock(String sessionId, DateTime startedAt) async {
    final count = await (_db.delete(_db.blocks)
          ..where((t) =>
              t.sessionId.equals(sessionId) &
              t.startedAt.equals(startedAt.millisecondsSinceEpoch)))
        .go();

    return count > 0;
  }

  /// Deletes all blocks for a session.
  Future<int> deleteBlocksForSession(String sessionId) async {
    return (_db.delete(_db.blocks)..where((t) => t.sessionId.equals(sessionId)))
        .go();
  }

  /// Converts a database row to a TerminalBlock entity.
  TerminalBlock _rowToBlock(Block row) {
    final decompressedOutput = _decompressOutput(row.output);

    return TerminalBlock(
      id: '${row.sessionId}_${row.startedAt}', // Composite ID
      sessionId: row.sessionId,
      command: row.command,
      output: decompressedOutput,
      status: BlockStatus.values.firstWhere(
        (s) => s.name == row.status,
        orElse: () => BlockStatus.running,
      ),
      exitCode: row.exitCode,
      startedAt: DateTime.fromMillisecondsSinceEpoch(row.startedAt),
      completedAt: row.completedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.completedAt!)
          : null,
      isCollapsed: row.isCollapsed,
      isTuiSession: row.isTuiSession,
    );
  }

  /// Compresses output string using gzip.
  Uint8List _compressOutput(String output) {
    final bytes = utf8.encode(output);
    return Uint8List.fromList(gzip.encode(bytes));
  }

  /// Decompresses output from gzip.
  String _decompressOutput(Uint8List compressed) {
    try {
      final decompressed = gzip.decode(compressed);
      return utf8.decode(decompressed);
    } catch (_) {
      // Fallback for uncompressed data (shouldn't happen)
      return utf8.decode(compressed);
    }
  }
}

/// Provider for BlockRepository.
final blockRepositoryProvider = Provider<BlockRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BlockRepository(db);
});
