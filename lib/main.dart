// @telos L1:function:lib:main

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/utils/logger.dart';
import 'database/database.dart';
import 'features/credentials/data/services/credential_vault.dart';
import 'features/credentials/presentation/providers/credential_providers.dart';

/// Pre-loads custom fonts to ensure they're available before rendering.
///
/// This is especially important for Nerd Fonts which contain special
/// Unicode glyphs used by shell prompts like Starship.
Future<void> _loadFonts() async {
  // Load the Nerd Font for terminal rendering
  final fontLoader = FontLoader('JetBrainsMonoNF');
  fontLoader.addFont(
    rootBundle.load('assets/fonts/JetBrainsMonoNerdFont-Regular.ttf'),
  );
  fontLoader.addFont(
    rootBundle.load('assets/fonts/JetBrainsMonoNerdFont-Bold.ttf'),
  );
  await fontLoader.load();
  AppLogger.i('JetBrainsMonoNF font loaded');

  // Also pre-load the standard JetBrains Mono
  final standardFontLoader = FontLoader('JetBrainsMono');
  standardFontLoader.addFont(
    rootBundle.load('assets/fonts/JetBrainsMono-Regular.ttf'),
  );
  standardFontLoader.addFont(
    rootBundle.load('assets/fonts/JetBrainsMono-Bold.ttf'),
  );
  await standardFontLoader.load();
  AppLogger.i('JetBrainsMono font loaded');
}

/// Application entry point.
///
/// Initializes Flutter bindings, database, credential vault, and runs the
/// app within a [ProviderScope] for Riverpod state management.
Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  AppLogger.i('Starting Bento...');

  // Pre-load custom fonts to ensure they're available for terminal rendering
  await _loadFonts();

  // Initialize database
  final database = BentoDatabase();
  AppLogger.i('Database initialized');

  // Initialize credential vault with cache observer
  final credentialVault = CredentialVault();
  credentialVault.startCacheObserver();
  AppLogger.i('Credential vault initialized with cache observer');

  // Run the app
  runApp(
    ProviderScope(
      overrides: [
        // Provide the database instance
        databaseProvider.overrideWithValue(database),
        // Provide the credential vault instance
        credentialVaultProvider.overrideWithValue(credentialVault),
      ],
      child: const BentoApp(),
    ),
  );
}
