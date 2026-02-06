# Spec: AI Service Factory

**ID**: `L1:function:lib/features/ai/domain/services:ai_service_factory`
**Type**: Factory **Parent**:
`L2:contract:lib/features/ai/domain/services:ai_service`

## Purpose

Create the appropriate AiService implementation based on the user's AI
configuration, handling initialization and fallback behavior.

## Interface

```dart
/// Factory for creating AI service instances based on configuration.
class AiServiceFactory {
  AiServiceFactory({
    required AiConfigRepository configRepository,
    required FlutterSecureStorage secureStorage,
  });

  /// Create an AI service based on the current configuration.
  ///
  /// [sshConnection] - Required for remote mode to communicate with Ollama.
  /// Returns the appropriate service, falling back to MockAiService if
  /// configuration is invalid or unavailable.
  Future<AiService> createService({SshConnection? sshConnection});

  /// Create a specific service type (for testing/override).
  Future<AiService> createLocalService(String modelPath);
  Future<AiService> createCloudService(String apiKey, CloudAiProvider provider);
  Future<AiService> createRemoteService(SshConnection connection);
  AiService createMockService();
}
```

## Behavior

### Service Selection Logic

```dart
Future<AiService> createService({SshConnection? sshConnection}) async {
  final config = await configRepository.loadConfig();
  
  switch (config.mode) {
    case AiMode.local:
      if (config.localModelPath != null) {
        try {
          return await createLocalService(config.localModelPath!);
        } catch (e) {
          // Model not found or failed to load
          return createMockService();
        }
      }
      return createMockService();
      
    case AiMode.cloud:
      final apiKey = await secureStorage.read(key: 'openrouter_api_key');
      if (apiKey != null && config.cloudProvider != null) {
        return createCloudService(apiKey, config.cloudProvider!);
      }
      return createMockService();
      
    case AiMode.remote:
      if (sshConnection != null && config.remoteAutoDetect) {
        try {
          final service = await createRemoteService(sshConnection);
          if (await service.isAvailable()) {
            return service;
          }
        } catch (e) {
          // Ollama not available on remote
        }
      }
      return createMockService();
      
    case AiMode.unconfigured:
      return createMockService();
  }
}
```

## Scenarios

### Scenario: Create Local Service

```gherkin
Given config mode is "local"
And localModelPath is "/path/to/model.gguf"
And the model file exists
When createService is called
Then LocalAiService is returned
And the model is loaded
```

### Scenario: Create Cloud Service

```gherkin
Given config mode is "cloud"
And cloudProvider is "claude"
And API key is stored in secure storage
When createService is called
Then CloudAiService is returned
And the service is configured for Claude via OpenRouter
```

### Scenario: Create Remote Service

```gherkin
Given config mode is "remote"
And remoteAutoDetect is true
And sshConnection is provided
And Ollama is running on the remote host
When createService is called
Then RemoteAiService is returned
And the service connects to Ollama
```

### Scenario: Fallback to Mock

```gherkin
Given config mode is "local"
And localModelPath points to non-existent file
When createService is called
Then MockAiService is returned
And no error is thrown
```

### Scenario: Unconfigured Mode

```gherkin
Given config mode is "unconfigured"
When createService is called
Then MockAiService is returned
```
