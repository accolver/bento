// @telos L1:function:lib/database:database

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/constants/app_constants.dart';
import 'tables/blocks.dart';
import 'tables/credential_metadata.dart';
import 'tables/saved_connections.dart';

part 'database.g.dart';

/// The main application database.
///
/// Uses Drift for type-safe SQLite operations.
/// Tables are added by feature changes and imported above.
@DriftDatabase(
  tables: [
    SavedConnections,
    CredentialMetadata,
    Blocks,
  ],
)
class BentoDatabase extends _$BentoDatabase {
  BentoDatabase() : super(_openConnection());

  /// Constructor for testing with custom executor.
  BentoDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => DatabaseConstants.schemaVersion;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Migrations run sequentially from 'from' version to 'to' version
        for (var version = from + 1; version <= to; version++) {
          switch (version) {
            case 2:
              // v2: Add CredentialMetadata table
              await customStatement('''
                CREATE TABLE IF NOT EXISTS credential_metadata (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  name TEXT NOT NULL,
                  type TEXT NOT NULL,
                  fingerprint TEXT,
                  storage_key TEXT NOT NULL,
                  requires_biometric INTEGER NOT NULL DEFAULT 0,
                  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
                  last_used_at INTEGER,
                  notes TEXT
                )
              ''');
            case 3:
              // v3: Add Blocks table for semantic blocks
              await customStatement('''
                CREATE TABLE IF NOT EXISTS blocks (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  session_id TEXT NOT NULL,
                  command TEXT NOT NULL,
                  output BLOB NOT NULL,
                  status TEXT NOT NULL,
                  exit_code INTEGER,
                  started_at INTEGER NOT NULL,
                  completed_at INTEGER,
                  is_collapsed INTEGER NOT NULL DEFAULT 0
                )
              ''');
              // Index for faster session queries
              await customStatement('''
                CREATE INDEX IF NOT EXISTS idx_blocks_session_id ON blocks(session_id)
              ''');
            case 4:
              // v4: Add is_tui_session column to Blocks table for TUI mode support
              await customStatement('''
                ALTER TABLE blocks ADD COLUMN is_tui_session INTEGER NOT NULL DEFAULT 0
              ''');
          }
        }
      },
      beforeOpen: (details) async {
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

/// Opens the database connection.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, DatabaseConstants.databaseName));
    return NativeDatabase.createInBackground(file);
  });
}

/// Provider for the database instance.
///
/// This should be overridden in main.dart with the actual database instance.
final databaseProvider = Provider<BentoDatabase>((ref) {
  throw UnimplementedError(
    'Database provider must be overridden in ProviderScope',
  );
});
