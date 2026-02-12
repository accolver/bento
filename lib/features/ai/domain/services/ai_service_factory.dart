// @telos L1:function:lib/features/ai/domain/services:ai_service_factory

import 'package:dartssh2/dartssh2.dart';

import '../entities/ai_config.dart';
import '../entities/remote_ai_detection.dart';
import '../entities/remote_ai_provider.dart';
import '../../data/repositories/ai_config_repository.dart';
import '../../data/services/cloud_ai_service.dart';
import '../../data/services/cloud_proxy_backend.dart';
import '../../data/services/local_ai_service.dart';
import '../../data/services/ollama_backend.dart';
import '../../data/services/remote_ai_service.dart';
import '../../data/services/remote_backend.dart';
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
  /// Note: Local AI is experimental and may not work on all devices.
  ///
  /// Memory optimization: We use a small context size (512 tokens) to reduce
  /// RAM usage. This is sufficient for command generation (typically <100 tokens).
  Future<AiService> createLocalService(String modelPath) async {
    final service = LocalAiService(
      modelPath: modelPath,
      // Small context to minimize RAM usage - commands are short
      contextSize: 512,
      maxTokens: 64, // Commands are short
      temperature: 0.3, // Lower for deterministic output
      nThreads: 2, // Fewer threads = less memory pressure
      useGpu: false, // Disabled due to compatibility issues on some devices
    );

    // Verify the service is available (model exists)
    final isAvailable = await service.isAvailable();

    if (!isAvailable) {
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

  /// Create a remote AI service using detected providers over SSH.
  ///
  /// [client] - Active SSH client connection.
  /// [detectionResult] - Result from [RemoteAiDetector] scan.
  /// [preferredProvider] - Optional preferred cloud provider.
  /// [preferredOllamaModel] - Optional preferred Ollama model name.
  ///
  /// Selects the best available backend based on:
  /// 1. User's saved preference (if still available)
  /// 2. Best cloud provider by quality rank
  /// 3. First available Ollama model
  ///
  /// Throws [AiServiceException] if no providers were detected.
  Future<AiService> createRemoteService(
    dynamic sshSession, [
    String? modelName,
    RemoteAiDetectionResult? detectionResult,
  ]) async {
    if (sshSession is! SSHClient) {
      throw const AiServiceException(
        'Invalid SSH session type for remote AI',
        code: 'invalid_session',
      );
    }

    final client = sshSession;

    // If no detection result provided, we can't create a service
    if (detectionResult == null || !detectionResult.hasAnyProvider) {
      throw const AiServiceException(
        'No AI providers detected on remote host',
        code: 'no_providers',
      );
    }

    // Determine backend based on what's available
    final backend = _selectBestBackend(
      detectionResult,
      preferredModel: modelName,
    );

    return RemoteAiService(
      client: client,
      backend: backend,
    );
  }

  /// Select the best backend from detection results.
  ///
  /// Priority:
  /// 1. If [preferredModel] is set and Ollama has it, use Ollama
  /// 2. If cloud providers are detected, use the best-ranked one
  /// 3. Fall back to first Ollama model
  RemoteBackend _selectBestBackend(
    RemoteAiDetectionResult result, {
    String? preferredModel,
  }) {
    // Check if user wants a specific Ollama model
    if (preferredModel != null && result.hasOllama) {
      final hasModel = result.ollamaModels.any(
        (m) => m.name == preferredModel,
      );
      if (hasModel) {
        return OllamaBackend(
          selectedModel: preferredModel,
          availableModels: result.ollamaModels,
        );
      }
    }

    // Prefer cloud providers (ranked by quality)
    if (result.hasCloudProviders) {
      final best = result.bestCloudProvider!;
      final config = RemoteProviderRegistry.forProvider(best.provider);
      if (config != null) {
        return CloudProxyBackend(
          providerConfig: config,
          envVarName: best.envVarName,
        );
      }
    }

    // Fall back to Ollama
    if (result.hasOllama) {
      return OllamaBackend(
        selectedModel: result.ollamaModels.first.name,
        availableModels: result.ollamaModels,
      );
    }

    // Should not reach here given hasAnyProvider check above
    throw const AiServiceException(
      'No usable AI backend found',
      code: 'no_backend',
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
