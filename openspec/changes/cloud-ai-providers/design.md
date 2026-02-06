# Design: Cloud AI Providers

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      AI Setup Wizard                         │
│                 (selects Cloud AI mode)                      │
│               (collects OpenRouter API key)                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      AiServiceFactory                        │
│          (creates CloudAiService when mode=cloud)            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      CloudAiService                          │
│                  (implements AiService)                      │
├─────────────────────────────────────────────────────────────┤
│  - generateCommand(prompt) → AiSuggestion                   │
│  - generateCommandStream(prompt) → Stream<AiStreamEvent>    │
│  - setApiKey() / clearApiKey()                              │
│  - selectModel() / getAvailableModels()                     │
│  - isAvailable() → checks API key configured                │
└─────────────────────────────────────────────────────────────┘
          │                                       │
          ▼                                       ▼
┌──────────────────────┐            ┌──────────────────────────┐
│  CredentialVault     │            │    OpenRouter API        │
│  (from credential-   │            │                          │
│   storage change)    │            │ /v1/chat/completions     │
├──────────────────────┤            │ (OpenAI-compatible)      │
│ - storeApiKey()      │            └──────────────────────────┘
│ - getApiKey()        │                       │
│ - deleteApiKey()     │                       ▼
└──────────────────────┘            ┌──────────────────────────┐
                                    │   Multiple Providers     │
                                    ├──────────────────────────┤
                                    │ - Anthropic (Claude)     │
                                    │ - OpenAI (GPT-4)         │
                                    │ - Google (Gemini)        │
                                    │ - Meta (Llama)           │
                                    │ - 500+ more...           │
                                    └──────────────────────────┘
```

## File Structure

```
lib/features/ai/
├── domain/
│   └── entities/
│       ├── cloud_model.dart          # Model metadata
│       ├── cloud_ai_config.dart      # Cloud-specific config
│       └── usage_stats.dart          # Token/cost tracking
├── data/
│   └── services/
│       └── cloud_ai_service.dart     # OpenRouter implementation
└── presentation/
    └── widgets/
        ├── api_key_input.dart        # Secure key entry field
        └── model_selector.dart       # Model picker dropdown
```

## OpenRouter Integration

### Why OpenRouter?

1. **Single API Key**: Users only need one key for all providers
2. **Unified Format**: OpenAI-compatible API works consistently
3. **Automatic Routing**: OpenRouter handles provider-specific quirks
4. **Cost Visibility**: Clear per-request pricing
5. **No SDK Bloat**: Simple HTTP, no provider SDKs needed

### API Key Flow

```dart
// User gets key from: https://openrouter.ai/keys

// 1. Validate key
Future<bool> validateApiKey(String key) async {
  final response = await http.get(
    Uri.parse('https://openrouter.ai/api/v1/models'),
    headers: {'Authorization': 'Bearer $key'},
  );
  return response.statusCode == 200;
}

// 2. Store securely
await credentialVault.store(
  key: 'openrouter_api_key',
  value: apiKey,
  biometricProtected: true,
);

// 3. Use for requests
final apiKey = await credentialVault.retrieve('openrouter_api_key');
```

### Model Selection Strategy

```dart
// Curated list shown to users (not all 500+ models)
final recommendedModels = [
  // Default: Best balance of speed/quality/cost
  CloudModel(id: 'openai/gpt-4o-mini', ...),
  
  // Premium: Best quality
  CloudModel(id: 'anthropic/claude-3.5-sonnet', ...),
  
  // Budget: Cheapest good option
  CloudModel(id: 'google/gemini-2.0-flash', ...),
  
  // Open source: For users who prefer
  CloudModel(id: 'meta-llama/llama-3.1-70b-instruct', ...),
];

// Can fetch full list for power users
Future<List<CloudModel>> getAllModels() async {
  final response = await http.get(
    Uri.parse('https://openrouter.ai/api/v1/models'),
    headers: {'Authorization': 'Bearer $_apiKey'},
  );
  // Parse and return all available models
}
```

## Streaming Implementation

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
    'HTTP-Referer': 'https://bento.app',
    'X-Title': 'Bento Terminal',
  });
  
  request.body = jsonEncode({
    'model': _config.selectedModelId,
    'messages': _buildMessages(prompt),
    'max_tokens': _config.maxTokens,
    'temperature': _config.temperature,
    'stream': true,
  });
  
  final client = http.Client();
  try {
    final response = await client.send(request);
    
    if (response.statusCode != 200) {
      yield AiStreamEvent.error(_parseError(response));
      return;
    }
    
    final buffer = StringBuffer();
    
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      for (final line in chunk.split('\n')) {
        if (line.startsWith('data: ') && line != 'data: [DONE]') {
          try {
            final json = jsonDecode(line.substring(6));
            final delta = json['choices']?[0]?['delta']?['content'];
            if (delta != null && delta.isNotEmpty) {
              buffer.write(delta);
              yield AiStreamEvent.token(delta);
            }
          } catch (e) {
            // Skip malformed chunks
          }
        }
      }
    }
    
    yield AiStreamEvent.complete(
      AiSuggestion(command: buffer.toString().trim()),
    );
  } finally {
    client.close();
  }
}
```

## Error Handling

```dart
Future<AiSuggestion> generateCommand(AiPrompt prompt) async {
  try {
    final response = await _makeRequest(prompt);
    
    switch (response.statusCode) {
      case 200:
        return _parseSuccess(response);
        
      case 401:
        throw ApiKeyInvalidException('Invalid or expired API key');
        
      case 429:
        final retryAfter = response.headers['retry-after'];
        throw RateLimitException(
          'Rate limited',
          retryAfterSeconds: int.tryParse(retryAfter ?? '60'),
        );
        
      case 503:
        // Model unavailable - try fallback
        if (_config.selectedModelId != _fallbackModelId) {
          _logger.warning('Model unavailable, trying fallback');
          return _generateWithFallback(prompt);
        }
        throw ModelUnavailableException('Model temporarily unavailable');
        
      default:
        throw CloudAiException('Unexpected error: ${response.statusCode}');
    }
  } on SocketException {
    throw NetworkException('No internet connection');
  } on TimeoutException {
    throw NetworkException('Request timed out');
  }
}
```

## Privacy Consent Flow

```dart
class CloudAiService {
  Future<void> ensureConsentBeforeRequest() async {
    if (_config.consentGiven) return;
    
    final consented = await _consentCallback?.call(
      ConsentRequest(
        title: 'Enable Cloud AI?',
        message: '''
Your prompts will be sent to OpenRouter's servers to generate suggestions.

What's sent:
• Your typed request (e.g., "list files")
• Basic context (OS, shell type)

What's NOT sent:
• Your terminal history
• Command outputs
• File contents

You can disable this anytime in Settings.
        ''',
        actions: ['Cancel', 'Enable Cloud AI'],
      ),
    );
    
    if (consented != true) {
      throw ConsentDeclinedException();
    }
    
    await _saveConfig(_config.copyWith(consentGiven: true));
  }
}
```

## Decisions

### D1: Single Provider (OpenRouter) vs Multiple SDKs

**Decision**: Use OpenRouter as the sole cloud provider

**Rationale**:

- One API key instead of 3-4
- One integration to maintain
- Users can still choose Claude/GPT/Gemini
- Fallback between models is seamless
- Simpler onboarding UX

### D2: Curated Model List vs Full Catalog

**Decision**: Show curated list by default, full list in advanced settings

**Rationale**:

- 500+ models is overwhelming
- Most users want "best" or "cheapest"
- Power users can access full list
- Easier to maintain recommendations

### D3: Default Model Choice

**Decision**: Default to `openai/gpt-4o-mini`

**Rationale**:

- Best quality-to-cost ratio
- Fast response times
- Reliable availability
- Good instruction following
- Users can upgrade to Claude/GPT-4 if needed

### D4: Streaming Default

**Decision**: Use streaming for all requests

**Rationale**:

- Better perceived performance
- Can show partial results
- User can cancel early
- Same API cost as non-streaming
