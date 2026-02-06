# L2 Contract: LocalAiService

## Purpose

Implements the AiService interface using flutter_llama for on-device inference.
Provides command generation without network dependency or data transmission.

## Parent

- L3: `ai-setup-flow` (user selects local AI mode)
- L2: `ai-gateway/ai-service-interface` (implements AiService)

## Interface

```dart
/// On-device AI service using flutter_llama
class LocalAiService implements AiService {
  LocalAiService({
    required ModelManager modelManager,
    required LocalAiConfig config,
  });

  /// Load model into memory (call before generating)
  Future<void> loadModel(String modelPath);
  
  /// Unload model to free memory
  Future<void> unloadModel();
  
  /// Whether a model is currently loaded
  bool get isModelLoaded;
  
  /// Current model info (null if not loaded)
  LocalAiModel? get currentModel;
  
  // Inherited from AiService:
  // - Future<AiSuggestion> generateCommand(AiPrompt prompt)
  // - Stream<AiStreamEvent> generateCommandStream(AiPrompt prompt)
  // - Future<bool> isAvailable()
  // - AiPrivacyMode get privacyMode => AiPrivacyMode.local
}
```

## Behavior

### Model Loading

```
GIVEN no model is loaded
WHEN loadModel() is called with valid path
THEN model file is memory-mapped
AND inference engine initializes
AND isModelLoaded becomes true

GIVEN model load fails (corrupted/incompatible)
WHEN loadModel() completes
THEN ModelLoadException is thrown
AND isModelLoaded remains false
```

### Command Generation

```
GIVEN model is loaded
WHEN generateCommand() is called
THEN prompt is formatted for chat completion
AND inference runs on device
AND result is parsed into AiSuggestion

GIVEN model is NOT loaded
WHEN generateCommand() is called  
THEN ModelNotLoadedException is thrown
```

### Memory Management

```
GIVEN model is loaded
AND app goes to background for >30 seconds
WHEN memory pressure is detected
THEN model is automatically unloaded
AND can be reloaded on next request

GIVEN model uses >75% available RAM
WHEN loading completes
THEN warning is logged
AND smaller model is suggested
```

## Prompt Engineering

System prompt for command generation:

```
You are a terminal command assistant. Given the user's description,
output ONLY the shell command(s) needed. No explanation, no markdown,
just the raw command(s).

Context:
- Shell: {shellType}
- OS: {platform}
- Current directory: {cwd}

User request: {userPrompt}

Command:
```

## Configuration

```dart
class LocalAiConfig {
  final String modelPath;
  final int contextLength;     // Default: 2048
  final int maxTokens;         // Default: 256
  final double temperature;    // Default: 0.3 (low for commands)
  final int threadCount;       // Default: Platform.numberOfProcessors ~/ 2
  final bool useGpu;           // Default: true
}
```

## Error Handling

| Error                     | Recovery                |
| ------------------------- | ----------------------- |
| Model file not found      | Prompt user to download |
| Insufficient memory       | Suggest smaller model   |
| Inference timeout (30s)   | Cancel and return error |
| GPU initialization failed | Fall back to CPU        |

## Performance Targets

| Metric              | Target               |
| ------------------- | -------------------- |
| Model load time     | <3s (SSD), <8s (HDD) |
| First token latency | <500ms               |
| Token generation    | >20 tokens/sec (GPU) |
| Memory overhead     | Model size + 200MB   |

## Dependencies

- `flutter_llama: ^1.1.2`
- Requires downloaded GGUF model file
