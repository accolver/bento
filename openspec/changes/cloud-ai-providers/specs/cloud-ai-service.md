# L2 Contract: CloudAiService

## Purpose

Implements the AiService interface using OpenRouter API for cloud-based
inference. Provides access to state-of-the-art models (Claude, GPT-4, Gemini)
through a unified API.

## Parent

- L3: `ai-setup-flow` (user selects cloud AI mode)
- L2: `ai-gateway/ai-service-interface` (implements AiService)

## Interface

```dart
/// Cloud AI service using OpenRouter API
class CloudAiService implements AiService {
  CloudAiService({
    required HttpClient httpClient,
    required CredentialVault credentialVault,
    required CloudAiConfig config,
  });

  /// Set the API key (called during setup)
  Future<void> setApiKey(String apiKey);
  
  /// Clear stored API key
  Future<void> clearApiKey();
  
  /// Check if API key is configured
  Future<bool> hasApiKey();
  
  /// Get list of available models
  Future<List<CloudModel>> getAvailableModels();
  
  /// Get current selected model
  CloudModel get selectedModel;
  
  /// Change selected model
  void selectModel(String modelId);
  
  /// Get usage statistics
  Future<UsageStats> getUsageStats();
  
  // Inherited from AiService:
  // - Future<AiSuggestion> generateCommand(AiPrompt prompt)
  // - Stream<AiStreamEvent> generateCommandStream(AiPrompt prompt)
  // - Future<bool> isAvailable()
  // - AiPrivacyMode get privacyMode => AiPrivacyMode.cloud
}
```

## Data Types

```dart
/// Cloud model metadata
class CloudModel {
  final String id;              // e.g., 'anthropic/claude-3.5-sonnet'
  final String displayName;     // e.g., 'Claude 3.5 Sonnet'
  final String provider;        // e.g., 'Anthropic'
  final int contextLength;      // Max tokens
  final double inputCostPer1M;  // $ per 1M input tokens
  final double outputCostPer1M; // $ per 1M output tokens
  final bool supportsStreaming;
}

/// Usage tracking
class UsageStats {
  final int totalRequests;
  final int inputTokensUsed;
  final int outputTokensUsed;
  final double estimatedCost;
  final DateTime periodStart;
}

/// Cloud AI configuration
class CloudAiConfig {
  final String selectedModelId;
  final int maxTokens;          // Default: 256
  final double temperature;     // Default: 0.3
  final bool sendContext;       // Send recent commands for better suggestions
  final bool consentGiven;      // User acknowledged data transmission
}
```

## Behavior

### API Key Management

```
GIVEN no API key is configured
WHEN user enters API key in setup
THEN key is validated against OpenRouter
AND stored securely in credential vault
AND hasApiKey() returns true

GIVEN invalid API key is entered
WHEN validation request fails
THEN ApiKeyInvalidException is thrown
AND key is NOT stored
```

### Command Generation

```
GIVEN valid API key is configured
WHEN generateCommand() is called
THEN request is sent to OpenRouter API
AND response is parsed into AiSuggestion
AND usage stats are updated

GIVEN network error occurs
WHEN API request fails
THEN NetworkException is thrown
AND cached fallback response is returned if available

GIVEN rate limit is hit
WHEN API returns 429
THEN RateLimitException is thrown
AND retry-after header is parsed
AND user is informed of wait time
```

### Streaming Generation

```
GIVEN streaming is supported by model
WHEN generateCommandStream() is called
THEN SSE stream is opened to OpenRouter
AND tokens are yielded as AiStreamEvent
AND final event contains complete suggestion

GIVEN stream is cancelled
WHEN user dismisses panel
THEN HTTP connection is closed
AND partial result is discarded
```

## API Integration

### Request Format

```dart
Future<AiSuggestion> generateCommand(AiPrompt prompt) async {
  final response = await _httpClient.post(
    Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
    headers: {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://bento.app',  // Required by OpenRouter
      'X-Title': 'Bento Terminal',
    },
    body: jsonEncode({
      'model': _config.selectedModelId,
      'messages': [
        {'role': 'system', 'content': _buildSystemPrompt(prompt.context)},
        {'role': 'user', 'content': prompt.text},
      ],
      'max_tokens': _config.maxTokens,
      'temperature': _config.temperature,
      'stream': false,
    }),
  );
  
  // Parse response...
}
```

### Streaming Request

```dart
Stream<AiStreamEvent> generateCommandStream(AiPrompt prompt) async* {
  final request = http.Request(
    'POST',
    Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
  );
  request.headers.addAll({
    'Authorization': 'Bearer $_apiKey',
    'Content-Type': 'application/json',
    'Accept': 'text/event-stream',
  });
  request.body = jsonEncode({
    'model': _config.selectedModelId,
    'messages': [...],
    'stream': true,
  });
  
  final response = await _httpClient.send(request);
  
  await for (final chunk in response.stream.transform(utf8.decoder)) {
    // Parse SSE format: data: {...}
    for (final line in chunk.split('\n')) {
      if (line.startsWith('data: ')) {
        final json = jsonDecode(line.substring(6));
        final delta = json['choices'][0]['delta']['content'];
        if (delta != null) {
          yield AiStreamEvent.token(delta);
        }
      }
    }
  }
  
  yield AiStreamEvent.complete(fullText);
}
```

## Available Models (Curated List)

```dart
static const recommendedModels = [
  CloudModel(
    id: 'openai/gpt-4o-mini',
    displayName: 'GPT-4o Mini',
    provider: 'OpenAI',
    contextLength: 128000,
    inputCostPer1M: 0.15,
    outputCostPer1M: 0.60,
    supportsStreaming: true,
  ),
  CloudModel(
    id: 'anthropic/claude-3.5-sonnet',
    displayName: 'Claude 3.5 Sonnet',
    provider: 'Anthropic',
    contextLength: 200000,
    inputCostPer1M: 3.00,
    outputCostPer1M: 15.00,
    supportsStreaming: true,
  ),
  CloudModel(
    id: 'google/gemini-2.0-flash',
    displayName: 'Gemini 2.0 Flash',
    provider: 'Google',
    contextLength: 1000000,
    inputCostPer1M: 0.10,
    outputCostPer1M: 0.40,
    supportsStreaming: true,
  ),
  CloudModel(
    id: 'meta-llama/llama-3.1-70b-instruct',
    displayName: 'Llama 3.1 70B',
    provider: 'Meta',
    contextLength: 131072,
    inputCostPer1M: 0.35,
    outputCostPer1M: 0.40,
    supportsStreaming: true,
  ),
];
```

## Error Handling

| Error             | HTTP Code | Recovery                          |
| ----------------- | --------- | --------------------------------- |
| Invalid API key   | 401       | Prompt to re-enter key            |
| Rate limited      | 429       | Show retry-after time             |
| Model unavailable | 503       | Fall back to alternative model    |
| Network error     | -         | Retry with backoff, then fail     |
| Invalid response  | -         | Log error, return generic failure |

## Privacy & Consent

Before first cloud request:

```dart
Future<bool> ensureConsent() async {
  if (_config.consentGiven) return true;
  
  // Show consent dialog:
  // "Cloud AI will send your prompts to OpenRouter servers.
  //  Your terminal history is NOT sent unless you enable context sharing.
  //  OpenRouter may log requests per their privacy policy."
  
  final consented = await _showConsentDialog();
  if (consented) {
    await _saveConfig(_config.copyWith(consentGiven: true));
  }
  return consented;
}
```

## Dependencies

- `http: ^1.0.0` (or `dio` for advanced features)
- Requires: `credential-storage` for API key
