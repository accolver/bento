# Proposal: AI Gateway (Service Abstraction)

## Why

Bento's AI features need a unified interface that abstracts over multiple
providers (local LLM, OpenRouter cloud, remote Ollama). The AI Gateway provides
a single API for all AI operations regardless of the underlying provider,
enabling seamless switching between modes and automatic fallback behavior.

## What Changes

- Define AiService abstract interface with generateCommand method
- Create AiServiceFactory that instantiates the correct service based on config
- Implement provider-specific services:
  - LocalAiService (flutter_llama)
  - CloudAiService (OpenRouter API)
  - RemoteAiService (Ollama via SSH)
  - MockAiService (existing, for testing/fallback)
- Implement automatic fallback chain (configured → mock)
- Create prompt template system optimized for command generation
- Add streaming support for real-time token output

## Capabilities

### New Capabilities

- `ai-service-interface`: Abstract interface all providers implement
- `ai-service-factory`: Creates correct service based on AiConfig
- `prompt-templates`: System/user prompt templates for command generation
- `ai-fallback`: Graceful degradation when provider unavailable

### Modified Capabilities

- `ai-suggestion-provider`: Use AiServiceFactory instead of MockAiService

## Interface

```dart
/// Abstract interface for AI command generation services.
abstract class AiService {
  /// Generate a command suggestion from natural language.
  Future<AiSuggestion> generateCommand(String prompt);
  
  /// Generate with streaming (for real-time display).
  Stream<String> generateCommandStream(String prompt);
  
  /// Check if the service is currently available.
  Future<bool> isAvailable();
  
  /// Get the privacy mode indicator for this service.
  AiPrivacyMode get privacyMode;
}

/// Factory for creating AI services based on configuration.
class AiServiceFactory {
  AiService createService(AiConfig config, {SshConnection? sshConnection});
}
```

## Impact

- **Dependencies**: Requires ai-setup-flow for configuration
- **Architecture**: Central abstraction for all AI features
- **Testing**: MockAiService enables testing without real AI

## Phase

**Phase 2 - Intelligence** (Months 5-7)

## Priority

**P0 - Must Have** - Foundation for all AI features
