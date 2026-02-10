// @telos L1:function:lib/features/ai/domain/services:ai_service_factory

import '../entities/ai_config.dart';
import '../../data/repositories/ai_config_repository.dart';
import '../../data/services/cloud_ai_service.dart';
import '../../data/services/local_ai_service.dart';
import '../../data/services/unconfigured_ai_service.dart';
import 'ai_service.dart';

/// Factory for creating AI service instances based on configuration.
///
/// The factory handles:
/// - Service selection based on [AiConfig.mode]
/// - Returning unconfigured service when AI is not set up
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
  /// - [AiMode.unconfigured] → UnconfiguredAiService (prompts user to configure)
  /// - [AiMode.local] → LocalAiService (if model available)
  /// - [AiMode.cloud] → CloudAiService (if API key available)
  /// - [AiMode.remote] → RemoteAiService (if Ollama detected)
  ///
  /// The [sshSession] parameter is required for remote mode to communicate
  /// with Ollama on the connected server.
  ///
  /// The [configRepository] is required for cloud mode to retrieve API keys.
  ///
  /// Returns the appropriate service, or [UnconfiguredAiService] if
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
        return createUnconfiguredService();

      case AiMode.local:
        // Try to create local service
        if (config.localModelPath != null) {
          try {
            return await createLocalService(config.localModelPath!);
          } catch (e) {
            // Model not found or failed to load
            return createUnconfiguredService();
          }
        }
        return createUnconfiguredService();

      case AiMode.cloud:
        // Try to create cloud service
        if (configRepository != null && config.cloudProvider != null) {
          try {
            final hasKey = await configRepository.hasApiKey();
            if (hasKey) {
              return createCloudService(
                  configRepository, config.cloudProvider!);
            }
          } catch (e) {
            // API key invalid or network error
          }
        }
        return createUnconfiguredService();

      case AiMode.remote:
        // Try to create remote service
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
            // Ollama not available or SSH error
          }
        }
        return createUnconfiguredService();
    }
  }

  /// Create an unconfigured service (prompts user to set up AI).
  ///
  /// Returns immediately as this service has no initialization.
  AiService createUnconfiguredService() {
    return const UnconfiguredAiService();
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
      // Use conservative settings for stability
      contextSize: 2048,
      maxTokens: 64, // Commands are short, limit for speed
      temperature: 0.1, // Lower for deterministic output
      nThreads: 2, // Reduce thread contention for stability
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
