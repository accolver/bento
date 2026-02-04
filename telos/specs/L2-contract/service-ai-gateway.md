<!-- telos-metadata
id: L2:contract:service-ai-gateway
level: 2
title: AI Gateway Service
parent: L3:experience:ai-command-assistance
children:
  - L1:function:lib/features/ai/domain/usecases:generateCommand
  - L1:function:lib/features/ai/domain/usecases:healError
-->

# L2: AI Gateway Service

## Overview

The AI Gateway provides a unified interface for all AI operations including
command generation (Ghostwriter), error healing, and output summarization. It
abstracts local and cloud LLM providers behind a common interface.

## Interface

### AIGateway

```dart
abstract class AIGateway {
  /// Generate a CLI command from natural language
  Future<Either<AIFailure, CommandSuggestion>> generateCommand({
    required String naturalLanguage,
    required ShellContext context,
  });
  
  /// Suggest a fix for a failed command
  Future<Either<AIFailure, CommandFix>> healError({
    required String command,
    required String stderr,
    required int exitCode,
    ShellContext? context,
  });
  
  /// Summarize command output
  Future<Either<AIFailure, String>> summarizeOutput({
    required String output,
    int maxLength = 100,
  });
  
  /// Explain what a command does
  Future<Either<AIFailure, String>> explainCommand({
    required String command,
  });
  
  /// Get current AI provider status
  AIProviderStatus get status;
  
  /// Check if local model is loaded
  bool get isLocalModelReady;
  
  /// Initialize local model (call on app start)
  Future<void> initializeLocalModel();
}
```

### Data Models

```dart
@freezed
class CommandSuggestion with _$CommandSuggestion {
  const factory CommandSuggestion({
    required String command,
    required String explanation,
    required double confidence,  // 0.0 - 1.0
    required AIProvider provider,
    List<String>? alternatives,
  }) = _CommandSuggestion;
}

@freezed
class CommandFix with _$CommandFix {
  const factory CommandFix({
    required String originalCommand,
    required String fixedCommand,
    required String explanation,
    required FixType fixType,
    required AIProvider provider,
    bool requiresConfirmation = false,  // True for dangerous fixes
  }) = _CommandFix;
}

enum FixType {
  addSudo,
  installPackage,
  fixSyntax,
  changePermissions,
  createDirectory,
  fixPath,
  fixArguments,
  other,
}

@freezed
class ShellContext with _$ShellContext {
  const factory ShellContext({
    required String shell,  // bash, zsh, fish
    required String os,     // linux, darwin
    String? cwd,
    List<String>? availableCommands,
    List<String>? recentCommands,
  }) = _ShellContext;
}

enum AIProvider { local, openai, anthropic, google }

@freezed
class AIProviderStatus with _$AIProviderStatus {
  const factory AIProviderStatus({
    required bool localAvailable,
    required bool cloudAvailable,
    required AIProvider activeProvider,
    String? cloudProviderName,
  }) = _AIProviderStatus;
}

@freezed
class AIFailure with _$AIFailure {
  const factory AIFailure.modelNotLoaded() = _ModelNotLoaded;
  const factory AIFailure.inferenceError(String message) = _InferenceError;
  const factory AIFailure.networkError(String message) = _NetworkError;
  const factory AIFailure.rateLimited() = _RateLimited;
  const factory AIFailure.invalidInput(String message) = _InvalidInput;
  const factory AIFailure.providerUnavailable() = _ProviderUnavailable;
}
```

## Behavior

### Provider Selection (Model Router)

1. Check user preferences (force local, prefer cloud, etc.)
2. Check network connectivity
3. Route based on task complexity:
   - Simple summarization → Local
   - Command generation → Based on complexity score
   - Error healing → Local (privacy: errors may contain sensitive data)
   - Explanation → User preference

### Privacy Controls

- **Local only mode**: All AI processed on-device
- **Cloud with consent**: Ask before each cloud request
- **Always cloud**: Use cloud without asking (faster, more accurate)

### Local Model

- Model: Qwen 0.5B quantized (Q4) in GGUF format
- Context size: 2048 tokens
- Inference target: < 500ms on mid-range device
- Loaded lazily on first AI request

### Cloud Providers

- Support multiple providers via adapter pattern
- User provides own API keys (stored securely)
- No server-side proxy (direct API calls)

## Error Handling

| Error                 | Behavior                                        |
| --------------------- | ----------------------------------------------- |
| Model not loaded      | Attempt to load, return failure if unsuccessful |
| Network error (cloud) | Fall back to local if available                 |
| Rate limited          | Return failure, suggest waiting                 |
| Invalid input         | Return failure with validation message          |

## Related Specs

- L3: [AI Command Assistance](../L3-experience/ai-command-assistance.md)
- L3: [Error Recovery](../L3-experience/error-recovery.md)
- L3: [Mobile Vibe Coding](../L3-experience/mobile-vibe-coding.md)
- L1: [To be defined - generateCommand function]
- L1: [To be defined - healError function]
- L1: [To be defined - Local LLM wrapper]
