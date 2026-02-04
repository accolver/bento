// @telos L1:function:lib/database:database

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/constants/app_constants.dart';

part 'database.g.dart';

// Import tables here as they are created by feature changes
// import 'tables/connections.dart';
// import 'tables/sessions.dart';
// import 'tables/blocks.dart';

/// The main application database.
///
/// Uses Drift for type-safe SQLite operations.
/// Tables are added by feature changes and imported above.
@DriftDatabase(
  tables: [
    // Add tables here as they are created
    // Connections,
    // Sessions,
    // Blocks,
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
        // Add migration logic as schema evolves
        // Example:
        // if (from < 2) {
        //   await m.addColumn(connections, connections.someNewColumn);
        // }
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
