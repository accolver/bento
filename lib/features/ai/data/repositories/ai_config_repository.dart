// @telos L1:function:lib/features/ai/data/repositories:ai_config_repository

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/ai_config.dart';

/// Repository for persisting AI configuration.
///
/// Non-sensitive config (mode, model ID, flags) is stored in SharedPreferences.
/// Sensitive data (API keys) is stored in flutter_secure_storage.
class AiConfigRepository {
  AiConfigRepository({
    SharedPreferences? sharedPreferences,
    FlutterSecureStorage? secureStorage,
  })  : _sharedPreferences = sharedPreferences,
        _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  SharedPreferences? _sharedPreferences;
  final FlutterSecureStorage _secureStorage;

  static const String _configKey = 'bento_ai_config';
  static const String _apiKeyKey = 'bento_ai_api_key';

  /// Ensures SharedPreferences is initialized.
  Future<SharedPreferences> _prefs() async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    return _sharedPreferences!;
  }

  /// Loads the current AI configuration.
  ///
  /// Returns [AiConfig.unconfigured] if no config exists.
  Future<AiConfig> loadConfig() async {
    final prefs = await _prefs();
    final json = prefs.getString(_configKey);

    if (json == null) {
      return AiConfig.unconfigured();
    }

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return _configFromJson(map);
    } on FormatException {
      // Invalid JSON
      return AiConfig.unconfigured();
    } on Exception {
      // Any other parsing error
      return AiConfig.unconfigured();
    }
  }

  /// Saves the AI configuration.
  Future<void> saveConfig(AiConfig config) async {
    final prefs = await _prefs();
    final json = jsonEncode(_configToJson(config));
    await prefs.setString(_configKey, json);
  }

  /// Clears all AI configuration and stored keys.
  Future<void> clearConfig() async {
    final prefs = await _prefs();
    await prefs.remove(_configKey);
    await _secureStorage.delete(key: _apiKeyKey);
  }

  /// Gets the stored API key for cloud AI.
  ///
  /// Returns null if no key is stored.
  Future<String?> getApiKey() async {
    return _secureStorage.read(key: _apiKeyKey);
  }

  /// Stores an API key securely.
  Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyKey, value: apiKey);
  }

  /// Deletes the stored API key.
  Future<void> deleteApiKey() async {
    await _secureStorage.delete(key: _apiKeyKey);
  }

  /// Checks if an API key is stored.
  Future<bool> hasApiKey() async {
    final key = await _secureStorage.read(key: _apiKeyKey);
    return key != null && key.isNotEmpty;
  }

  // --- JSON Serialization ---

  Map<String, dynamic> _configToJson(AiConfig config) {
    return {
      'mode': config.mode.name,
      'localModelId': config.localModelId,
      'localModelPath': config.localModelPath,
      'cloudProvider': config.cloudProvider?.name,
      'remoteAutoDetect': config.remoteAutoDetect,
      'remoteModelName': config.remoteModelName,
      'showPrivacyIndicator': config.showPrivacyIndicator,
      'configuredAt': config.configuredAt?.toIso8601String(),
      'lastUsedAt': config.lastUsedAt?.toIso8601String(),
    };
  }

  AiConfig _configFromJson(Map<String, dynamic> json) {
    return AiConfig(
      mode: AiMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => AiMode.unconfigured,
      ),
      localModelId: json['localModelId'] as String?,
      localModelPath: json['localModelPath'] as String?,
      cloudProvider: json['cloudProvider'] != null
          ? CloudAiProvider.values.firstWhere(
              (p) => p.name == json['cloudProvider'],
              orElse: () => CloudAiProvider.claude,
            )
          : null,
      remoteAutoDetect: json['remoteAutoDetect'] as bool? ?? true,
      remoteModelName: json['remoteModelName'] as String?,
      showPrivacyIndicator: json['showPrivacyIndicator'] as bool? ?? true,
      configuredAt: json['configuredAt'] != null
          ? DateTime.tryParse(json['configuredAt'] as String)
          : null,
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.tryParse(json['lastUsedAt'] as String)
          : null,
    );
  }
}
