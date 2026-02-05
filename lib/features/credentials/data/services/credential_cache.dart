// @telos L1:function:lib/features/credentials/data/services:credential_cache

import 'dart:async';

import 'package:flutter/widgets.dart';

/// Entry in the credential cache with expiration tracking.
class _CacheEntry {
  _CacheEntry({
    required this.value,
    required this.expiresAt,
  });

  final String value;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// In-memory cache for decrypted credentials with TTL-based expiration.
///
/// Credentials are cached after successful retrieval to avoid repeated
/// secure storage access and biometric prompts during active use.
/// The cache is cleared when the app goes to background.
class CredentialCache with WidgetsBindingObserver {
  CredentialCache({
    Duration ttl = const Duration(minutes: 5),
  }) : _ttl = ttl;

  final Duration _ttl;
  final Map<String, _CacheEntry> _cache = {};
  Timer? _cleanupTimer;
  bool _isObserving = false;

  /// Starts observing app lifecycle for automatic cache clearing.
  ///
  /// Must be called to enable background clearing.
  void startObserving() {
    if (!_isObserving) {
      WidgetsBinding.instance.addObserver(this);
      _isObserving = true;
      _startCleanupTimer();
    }
  }

  /// Stops observing app lifecycle.
  void stopObserving() {
    if (_isObserving) {
      WidgetsBinding.instance.removeObserver(this);
      _isObserving = false;
      _cleanupTimer?.cancel();
      _cleanupTimer = null;
    }
  }

  /// Caches a credential value with the configured TTL.
  void put(String key, String value) {
    _cache[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(_ttl),
    );
  }

  /// Gets a cached credential if it exists and hasn't expired.
  ///
  /// Returns null if not cached or expired.
  String? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.value;
  }

  /// Removes a specific credential from the cache.
  void remove(String key) {
    _cache.remove(key);
  }

  /// Clears all cached credentials.
  ///
  /// Called automatically when the app goes to background.
  void clear() {
    _cache.clear();
  }

  /// Returns whether the cache contains a valid entry for the key.
  bool contains(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  /// Current number of cached entries.
  int get length => _cache.length;

  /// Whether the cache is empty.
  bool get isEmpty => _cache.isEmpty;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      // App is going to background - clear sensitive data
      clear();
    }
  }

  /// Starts periodic cleanup of expired entries.
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    // Run cleanup every minute
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _removeExpiredEntries();
    });
  }

  /// Removes all expired entries from the cache.
  void _removeExpiredEntries() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }

  /// Disposes the cache, removing lifecycle observer and clearing data.
  void dispose() {
    stopObserving();
    clear();
  }
}
