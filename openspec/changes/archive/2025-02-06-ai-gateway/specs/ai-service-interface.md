# Spec: AI Service Interface

**ID**: `L2:contract:lib/features/ai/domain/services:ai_service` **Type**:
Interface **Parent**: `L3:experience:ai-command-generation`

## Purpose

Define the abstract interface that all AI service providers must implement,
ensuring consistent behavior regardless of whether AI runs locally, in the
cloud, or on a remote server.

## Interface

```dart
/// Abstract interface for AI command generation services.
///
/// All AI providers (local, cloud, remote) implement this interface,
/// allowing the application to use any provider interchangeably.
abstract class AiService {
  /// Generate a command suggestion from natural language input.
  ///
  /// [prompt] - The user's natural language description of what they want.
  /// Returns an [AiSuggestion] with the command, explanation, and confidence.
  /// Throws [AiServiceException] if generation fails.
  Future<AiSuggestion> generateCommand(String prompt);
  
  /// Generate with streaming for real-time token display.
  ///
  /// Yields partial results as tokens are generated.
  /// The final yield contains the complete suggestion.
  Stream<AiStreamEvent> generateCommandStream(String prompt);
  
  /// Check if the service is currently available and ready.
  ///
  /// For local: model is loaded
  /// For cloud: network available and API key valid
  /// For remote: SSH connected and Ollama responding
  Future<bool> isAvailable();
  
  /// Get the privacy mode indicator for UI display.
  AiPrivacyMode get privacyMode;
  
  /// Human-readable name for this service (for settings/debug).
  String get serviceName;
  
  /// Dispose of resources (unload model, close connections).
  Future<void> dispose();
}

/// Events emitted during streaming generation.
sealed class AiStreamEvent {}

/// A partial token was generated.
class AiStreamToken extends AiStreamEvent {
  final String token;
  AiStreamToken(this.token);
}

/// Generation completed successfully.
class AiStreamComplete extends AiStreamEvent {
  final AiSuggestion suggestion;
  AiStreamComplete(this.suggestion);
}

/// An error occurred during generation.
class AiStreamError extends AiStreamEvent {
  final String message;
  AiStreamError(this.message);
}

/// Exception thrown by AI services.
class AiServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  AiServiceException(this.message, {this.code, this.originalError});
  
  @override
  String toString() => 'AiServiceException: $message';
}
```

## Prompt Template

All services should use a consistent system prompt for command generation:

```dart
const commandGenerationSystemPrompt = '''
You are an expert terminal command assistant. Given a natural language description,
generate the most appropriate shell command.

Rules:
1. Output ONLY the command, nothing else
2. Use common Unix/Linux commands that work on most systems
3. Prefer safe commands (use -i for interactive prompts when deleting)
4. If multiple commands needed, chain with && or use subshells
5. Include common flags that improve output (e.g., -h for human-readable)

Context:
- The user is connected to a remote server via SSH
- Common tools available: bash, coreutils, git, docker, kubectl
- Prefer portable POSIX-compliant syntax when possible
''';

const commandGenerationUserPrompt = '''
Generate a command for: {input}

Command:
''';
```

## Scenarios

### Scenario: Successful Generation

```gherkin
Given an AI service is available
When generateCommand is called with "list all files"
Then an AiSuggestion is returned
And the command field is non-empty
And the confidence is between 0 and 1
```

### Scenario: Service Unavailable

```gherkin
Given an AI service is not available
When generateCommand is called
Then AiServiceException is thrown
And the exception message indicates the unavailability reason
```

### Scenario: Streaming Generation

```gherkin
Given an AI service supports streaming
When generateCommandStream is called
Then AiStreamToken events are yielded as generation progresses
And AiStreamComplete is yielded when done
And the final suggestion matches non-streaming result
```

### Scenario: Privacy Mode Indicator

```gherkin
Given a local AI service
Then privacyMode is AiPrivacyMode.local

Given a cloud AI service
Then privacyMode is AiPrivacyMode.cloud

Given a remote AI service on user's server
Then privacyMode is AiPrivacyMode.local
```
