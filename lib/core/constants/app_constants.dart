// @telos L1:function:lib/core/constants:app_constants

/// Application-wide constants.
abstract class AppConstants {
  AppConstants._();

  /// Application name
  static const String appName = 'Bento';

  /// Application version (should match pubspec.yaml)
  static const String version = '1.0.0';

  /// Build number (should match pubspec.yaml)
  static const int buildNumber = 1;
}

/// Network-related constants.
abstract class NetworkConstants {
  NetworkConstants._();

  /// Default connection timeout in milliseconds
  static const int connectionTimeout = 30000;

  /// Default receive timeout in milliseconds
  static const int receiveTimeout = 30000;

  /// Default send timeout in milliseconds
  static const int sendTimeout = 30000;

  /// Number of retry attempts for failed requests
  static const int maxRetries = 3;

  /// Delay between retries in milliseconds
  static const int retryDelay = 1000;
}

/// Cache-related constants.
abstract class CacheConstants {
  CacheConstants._();

  /// Default cache duration in seconds
  static const int defaultCacheDuration = 3600; // 1 hour

  /// Maximum number of items in memory cache
  static const int maxMemoryCacheItems = 100;

  /// Maximum size of disk cache in bytes (50 MB)
  static const int maxDiskCacheSize = 50 * 1024 * 1024;
}

/// Terminal-related constants.
abstract class TerminalConstants {
  TerminalConstants._();

  /// Default terminal width in columns
  static const int defaultColumns = 80;

  /// Default terminal height in rows
  static const int defaultRows = 24;

  /// Default SSH port
  static const int defaultSshPort = 22;

  /// Default Mosh port range start
  static const int moshPortStart = 60000;

  /// Default Mosh port range end
  static const int moshPortEnd = 61000;

  /// Maximum scrollback buffer lines
  static const int maxScrollbackLines = 10000;

  /// Cursor blink interval in milliseconds
  static const int cursorBlinkInterval = 500;
}

/// Database-related constants.
abstract class DatabaseConstants {
  DatabaseConstants._();

  /// Database file name
  static const String databaseName = 'bento.db';

  /// Current database schema version
  /// v1: Initial schema with SavedConnections
  /// v2: Added CredentialMetadata table
  /// v3: Added Blocks table for semantic blocks
  static const int schemaVersion = 3;
}

/// Animation-related constants.
abstract class AnimationConstants {
  AnimationConstants._();

  /// Default animation duration in milliseconds
  static const int defaultDuration = 300;

  /// Fast animation duration in milliseconds
  static const int fastDuration = 150;

  /// Slow animation duration in milliseconds
  static const int slowDuration = 500;
}
