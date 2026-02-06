// @telos L1:function:lib/features/ai/domain/services:ai_service_factory

import '../entities/ai_config.dart';
import '../../data/services/mock_ai_service.dart';
import 'ai_service.dart';

/// Factory for creating AI service instances based on configuration.
///
/// The factory handles:
/// - Service selection based on [AiConfig.mode]
/// - Fallback to mock service when real services aren't available
/// - Placeholder methods for services to be implemented in other changes
///
/// Usage:
/// ```dart
/// final factory = AiServiceFactory();
/// final service = await factory.createService(config);
/// ```
class AiServiceFactory {
  const AiServiceFactory();

  /// Create an AI service based on the current configuration.
  ///
  /// Routes to the appropriate service implementation based on [config.mode]:
  /// - [AiMode.unconfigured] → MockAiService
  /// - [AiMode.local] → LocalAiService (if model available) or fallback to mock
  /// - [AiMode.cloud] → CloudAiService (if API key available) or fallback to mock
  /// - [AiMode.remote] → RemoteAiService (if Ollama detected) or fallback to mock
  ///
  /// The [sshSession] parameter is required for remote mode to communicate
  /// with Ollama on the connected server.
  ///
  /// Returns the appropriate service, falling back to [MockAiService] if
  /// the requested service is unavailable.
  Future<AiService> createService(
    AiConfig config, {
    // SSH session for remote mode - type will be SshSession when that's implemented
    dynamic sshSession,
    // Secure storage for API keys - type will be FlutterSecureStorage
    dynamic secureStorage,
  }) async {
    switch (config.mode) {
      case AiMode.unconfigured:
        return createMockService();

      case AiMode.local:
        // Try to create local service, fallback to mock if not available
        if (config.localModelPath != null) {
          try {
            return await createLocalService(config.localModelPath!);
          } catch (e) {
            // Model not found or failed to load, fallback to mock
            return createMockService();
          }
        }
        return createMockService();

      case AiMode.cloud:
        // Try to create cloud service, fallback to mock if no API key
        if (secureStorage != null && config.cloudProvider != null) {
          try {
            // API key retrieval will be implemented in cloud-ai-providers change
            final apiKey = await _getApiKey(secureStorage);
            if (apiKey != null) {
              return await createCloudService(apiKey, config.cloudProvider!);
            }
          } catch (e) {
            // API key invalid or network error, fallback to mock
          }
        }
        return createMockService();

      case AiMode.remote:
        // Try to create remote service, fallback to mock if not connected
        if (sshSession != null && config.remoteAutoDetect) {
          try {
            final service = await createRemoteService(
              sshSession,
              config.remoteModelName,
            );
            if (await service.isAvailable()) {
              return service;
            }
          } catch (e) {
            // Ollama not available or SSH error, fallback to mock
          }
        }
        return createMockService();
    }
  }

  /// Create a mock service (for testing and fallback).
  ///
  /// Returns immediately as mock service requires no initialization.
  AiService createMockService() {
    return MockAiService();
  }

  /// Create a local AI service with the specified model.
  ///
  /// [modelPath] - Path to the GGUF model file.
  ///
  /// Throws [AiServiceException] if the model file doesn't exist or fails to load.
  ///
  /// **Note**: Implementation will be added in `local-llm` change.
  /// Currently throws to fall back to mock.
  Future<AiService> createLocalService(String modelPath) async {
    // TODO: Implement in local-llm change using flutter_llama
    throw AiServiceException(
      'Local AI not yet implemented',
      code: 'not_implemented',
    );
  }

  /// Create a cloud AI service with the specified provider.
  ///
  /// [apiKey] - OpenRouter API key.
  /// [provider] - Which cloud model to use.
  ///
  /// Throws [AiServiceException] if the API key is invalid.
  ///
  /// **Note**: Implementation will be added in `cloud-ai-providers` change.
  /// Currently throws to fall back to mock.
  Future<AiService> createCloudService(
    String apiKey,
    CloudAiProvider provider,
  ) async {
    // TODO: Implement in cloud-ai-providers change using OpenRouter
    throw AiServiceException(
      'Cloud AI not yet implemented',
      code: 'not_implemented',
    );
  }

  /// Create a remote AI service using Ollama over SSH.
  ///
  /// [sshSession] - Active SSH connection.
  /// [modelName] - Optional specific model to use.
  ///
  /// Throws [AiServiceException] if Ollama is not detected on the server.
  ///
  /// **Note**: Implementation will be added in `remote-ai-ollama` change.
  /// Currently throws to fall back to mock.
  Future<AiService> createRemoteService(
    dynamic sshSession, [
    String? modelName,
  ]) async {
    // TODO: Implement in remote-ai-ollama change
    throw AiServiceException(
      'Remote AI not yet implemented',
      code: 'not_implemented',
    );
  }

  /// Helper to retrieve API key from secure storage.
  ///
  /// Returns null if no key is stored.
  Future<String?> _getApiKey(dynamic secureStorage) async {
    // Will be implemented when FlutterSecureStorage is integrated
    // For now, return null to trigger fallback
    return null;
  }
}
