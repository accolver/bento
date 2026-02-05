// @telos L1:function:lib/features/credentials/data/services:credential_vault

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'credential_cache.dart';

/// Service for secure credential storage using platform keychain.
///
/// Provides encrypted storage for sensitive credential material
/// (SSH private keys, passwords). Uses flutter_secure_storage which
/// leverages iOS Keychain and Android Keystore.
///
/// Includes an in-memory cache with TTL-based expiration for
/// recently accessed credentials. Cache is cleared when app backgrounds.
class CredentialVault {
  CredentialVault({
    FlutterSecureStorage? secureStorage,
    CredentialCache? cache,
  })  : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            ),
        _cache = cache ?? CredentialCache();

  final FlutterSecureStorage _secureStorage;
  final CredentialCache _cache;

  /// Storage key prefix for credentials
  static const String _keyPrefix = 'bento_credential_';

  /// Storage key prefix for passphrases
  static const String _passphrasePrefix = 'bento_passphrase_';

  /// Generates a storage key for a credential ID.
  String _credentialKey(int id) => '$_keyPrefix$id';

  /// Generates a storage key for a passphrase ID.
  String _passphraseKey(int id) => '$_passphrasePrefix$id';

  /// Starts the cache lifecycle observer.
  ///
  /// Call this during app initialization to enable automatic
  /// cache clearing when the app goes to background.
  void startCacheObserver() {
    _cache.startObserving();
  }

  /// Stops the cache lifecycle observer.
  void stopCacheObserver() {
    _cache.stopObserving();
  }

  /// Clears all cached credentials from memory.
  ///
  /// Call this when you want to force re-authentication.
  void clearCache() {
    _cache.clear();
  }

  /// Stores a credential (key material or password) securely.
  ///
  /// [id] is the credential metadata ID from the database.
  /// [credential] is the sensitive material to store (PEM key or password).
  Future<void> store(int id, String credential) async {
    await _secureStorage.write(
      key: _credentialKey(id),
      value: credential,
    );
    // Also cache it for quick access
    _cache.put(_credentialKey(id), credential);
  }

  /// Retrieves a stored credential.
  ///
  /// First checks the in-memory cache, then falls back to secure storage.
  /// Returns null if the credential doesn't exist.
  Future<String?> retrieve(int id) async {
    final cacheKey = _credentialKey(id);

    // Check cache first
    final cached = _cache.get(cacheKey);
    if (cached != null) {
      return cached;
    }

    // Fall back to secure storage
    final value = await _secureStorage.read(key: cacheKey);
    if (value != null) {
      // Cache for future access
      _cache.put(cacheKey, value);
    }
    return value;
  }

  /// Deletes a stored credential and its passphrase if present.
  Future<void> delete(int id) async {
    // Remove from cache
    _cache.remove(_credentialKey(id));
    _cache.remove(_passphraseKey(id));

    // Remove from secure storage
    await _secureStorage.delete(key: _credentialKey(id));
    await _secureStorage.delete(key: _passphraseKey(id));
  }

  /// Stores a passphrase for an encrypted key.
  Future<void> storePassphrase(int id, String passphrase) async {
    await _secureStorage.write(
      key: _passphraseKey(id),
      value: passphrase,
    );
    _cache.put(_passphraseKey(id), passphrase);
  }

  /// Retrieves a stored passphrase.
  ///
  /// First checks cache, then falls back to secure storage.
  /// Returns null if no passphrase is stored.
  Future<String?> retrievePassphrase(int id) async {
    final cacheKey = _passphraseKey(id);

    // Check cache first
    final cached = _cache.get(cacheKey);
    if (cached != null) {
      return cached;
    }

    // Fall back to secure storage
    final value = await _secureStorage.read(key: cacheKey);
    if (value != null) {
      _cache.put(cacheKey, value);
    }
    return value;
  }

  /// Checks if a credential exists in storage.
  Future<bool> exists(int id) async {
    final value = await _secureStorage.read(key: _credentialKey(id));
    return value != null;
  }

  /// Deletes all stored credentials.
  ///
  /// Use with caution - this is destructive.
  Future<void> deleteAll() async {
    _cache.clear();
    await _secureStorage.deleteAll();
  }

  /// Disposes the vault, stopping cache observer and clearing memory.
  void dispose() {
    _cache.dispose();
  }
}
