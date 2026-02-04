// @telos L1:function:lib:main

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/utils/logger.dart';
import 'database/database.dart';

/// Application entry point.
///
/// Initializes Flutter bindings, database, and runs the app within a
/// [ProviderScope] for Riverpod state management.
Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  AppLogger.i('Starting Bento...');

  // Initialize database
  final database = BentoDatabase();
  AppLogger.i('Database initialized');

  // Run the app
  runApp(
    ProviderScope(
      overrides: [
        // Provide the database instance
        databaseProvider.overrideWithValue(database),
      ],
      child: const BentoApp(),
    ),
  );
}
