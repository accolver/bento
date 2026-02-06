# Spec: AI Configuration Entity

**ID**: `L1:function:lib/features/ai/domain/entities:ai_config` **Type**: Entity
**Parent**: `L2:contract:lib/features/ai/domain`

## Purpose

Represent the user's AI configuration including mode, provider details, model
settings, and feature flags.

## Interface

```dart
/// AI operation mode
enum AiMode {
  /// Not configured - use mock/keyword matching
  unconfigured,
  
  /// On-device inference with flutter_llama
  local,
  
  /// Cloud API via OpenRouter
  cloud,
  
  /// Remote Ollama on SSH-connected server
  remote,
}

/// Cloud AI provider (via OpenRouter)
enum CloudAiProvider {
  claude,      // anthropic/claude-3.5-sonnet
  gpt4oMini,   // openai/gpt-4o-mini
  llama3,      // meta-llama/llama-3-70b-instruct
  gemini,      // google/gemini-pro
}

/// Local AI model definition
@freezed
class LocalAiModel with _$LocalAiModel {
  const factory LocalAiModel({
    required String id,
    required String name,
    required String description,
    required int sizeBytes,
    required String huggingFaceRepo,
    required String huggingFaceFile,
    required int qualityStars,
    @Default(false) bool isRecommended,
  }) = _LocalAiModel;
}

/// Main AI configuration
@freezed
class AiConfig with _$AiConfig {
  const factory AiConfig({
    required AiMode mode,
    
    // Local AI settings
    String? localModelId,
    String? localModelPath,
    
    // Cloud AI settings
    CloudAiProvider? cloudProvider,
    // Note: API key stored separately in secure storage
    
    // Remote AI settings
    @Default(true) bool remoteAutoDetect,
    
    // General settings
    @Default(true) bool showPrivacyIndicator,
    
    // Timestamps
    DateTime? configuredAt,
    DateTime? lastUsedAt,
  }) = _AiConfig;
  
  factory AiConfig.unconfigured() => const AiConfig(mode: AiMode.unconfigured);
}
```

## Available Local Models

```dart
const availableLocalModels = [
  LocalAiModel(
    id: 'tinyllama',
    name: 'TinyLlama',
    description: 'Fastest, works on any device',
    sizeBytes: 600 * 1024 * 1024, // 600 MB
    huggingFaceRepo: 'TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF',
    huggingFaceFile: 'tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
    qualityStars: 3,
  ),
  LocalAiModel(
    id: 'phi3-mini',
    name: 'Phi-3 Mini',
    description: 'Best quality for size, great reasoning',
    sizeBytes: 2 * 1024 * 1024 * 1024, // 2 GB
    huggingFaceRepo: 'microsoft/Phi-3-mini-4k-instruct-gguf',
    huggingFaceFile: 'Phi-3-mini-4k-instruct-q4.gguf',
    qualityStars: 5,
    isRecommended: true,
  ),
  LocalAiModel(
    id: 'gemma-2b',
    name: 'Gemma 2B',
    description: 'Good for multiple languages',
    sizeBytes: 1200 * 1024 * 1024, // 1.2 GB
    huggingFaceRepo: 'google/gemma-2b-it-GGUF',
    huggingFaceFile: 'gemma-2b-it.Q4_K_M.gguf',
    qualityStars: 4,
  ),
  LocalAiModel(
    id: 'braindler',
    name: 'Braindler',
    description: 'Ultra-compact, mobile optimized',
    sizeBytes: 88 * 1024 * 1024, // 88 MB
    huggingFaceRepo: 'nativemind/braindler',
    huggingFaceFile: 'braindler-q4_k_s.gguf',
    qualityStars: 3,
  ),
];
```

## Scenarios

### Scenario: Default Unconfigured State

```gherkin
Given no AI configuration exists
When AiConfig is loaded
Then mode is AiMode.unconfigured
And all provider-specific fields are null
```

### Scenario: Local Configuration

```gherkin
Given user completed local AI setup
When AiConfig is loaded
Then mode is AiMode.local
And localModelId is set
And localModelPath points to downloaded model
```

### Scenario: Cloud Configuration

```gherkin
Given user completed cloud AI setup
When AiConfig is loaded
Then mode is AiMode.cloud
And cloudProvider is set
And API key is retrievable from secure storage
```

### Scenario: Remote Configuration

```gherkin
Given user enabled remote AI detection
When AiConfig is loaded
Then mode is AiMode.remote (or unconfigured with remoteAutoDetect true)
And remoteAutoDetect is true
```
