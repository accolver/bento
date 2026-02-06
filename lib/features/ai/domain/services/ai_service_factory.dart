// @telos L1:function:lib/features/ai/domain/services:ai_service_factory

import '../entities/ai_config.dart';
import '../../data/repositories/ai_config_repository.dart';
import '../../data/services/cloud_ai_service.dart';
import '../../data/services/local_ai_service.dart';
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
  /// The [configRepository] is required for cloud mode to retrieve API keys.
  ///
  /// Returns the appropriate service, falling back to [MockAiService] if
  /// the requested service is unavailable.
  Future<AiService> createService(
    AiConfig config, {
    // SSH session for remote mode - type will be SshSession when that's implemented
    dynamic sshSession,
    // Config repository for API key access
    AiConfigRepository? configRepository,
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
        if (configRepository != null && config.cloudProvider != null) {
          try {
            final hasKey = await configRepository.hasApiKey();
            if (hasKey) {
              return createCloudService(
                  configRepository, config.cloudProvider!);
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
  /// Uses flutter_llama for on-device inference with llama.cpp backend.
  /// Supports GPU acceleration on iOS/macOS (Metal) and Android (Vulkan/OpenCL).
  Future<AiService> createLocalService(String modelPath) async {
    final service = LocalAiService(
      modelPath: modelPath,
      contextSize: 2048,
      maxTokens: 256,
      temperature: 0.3,
      nThreads: 4,
      useGpu: true,
    );

    // Verify the service is available (model exists and can load)
    if (!await service.isAvailable()) {
      await service.dispose();
      throw AiServiceException(
        'Local model not available at: $modelPath',
        code: 'model_not_found',
      );
    }

    return service;
  }

  /// Create a cloud AI service with the specified provider.
  ///
  /// [configRepository] - Repository for accessing API key.
  /// [provider] - Which cloud model to use.
  ///
  /// Returns a [CloudAiService] configured for the specified provider.
  AiService createCloudService(
    AiConfigRepository configRepository,
    CloudAiProvider provider,
  ) {
    return CloudAiService(
      configRepository: configRepository,
      provider: provider,
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
