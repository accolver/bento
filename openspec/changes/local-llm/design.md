# Design: Local LLM

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      AI Setup Wizard                         │
│                  (selects Local AI mode)                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      AiServiceFactory                        │
│           (creates LocalAiService when mode=local)           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      LocalAiService                          │
│                  (implements AiService)                      │
├─────────────────────────────────────────────────────────────┤
│  - generateCommand(prompt) → AiSuggestion                   │
│  - generateCommandStream(prompt) → Stream<AiStreamEvent>    │
│  - loadModel() / unloadModel()                              │
│  - isAvailable() → checks if model loaded                   │
└─────────────────────────────────────────────────────────────┘
          │                                       │
          ▼                                       ▼
┌──────────────────────┐            ┌──────────────────────────┐
│    ModelManager      │            │     flutter_llama        │
│                      │            │      (package)           │
├──────────────────────┤            ├──────────────────────────┤
│ - downloadModel()    │            │ - LlamaModel.load()      │
│ - getDownloadedModels│            │ - generateCompletion()   │
│ - deleteModel()      │            │ - GPU acceleration       │
└──────────────────────┘            └──────────────────────────┘
          │
          ▼
┌──────────────────────┐
│   HuggingFace CDN    │
│  (model downloads)   │
└──────────────────────┘
```

## File Structure

```
lib/features/ai/
├── domain/
│   ├── entities/
│   │   ├── local_ai_model.dart       # Model metadata
│   │   └── download_progress.dart    # Download state
│   └── services/
│       └── ai_service.dart           # Abstract interface (from ai-gateway)
├── data/
│   ├── services/
│   │   └── local_ai_service.dart     # flutter_llama implementation
│   └── repositories/
│       └── model_repository.dart     # Model file management
└── presentation/
    └── widgets/
        └── model_download_progress.dart  # Progress UI
```

## flutter_llama Integration

### Package Setup

```yaml
# pubspec.yaml
dependencies:
  flutter_llama: ^1.1.2
```

### Basic Usage

```dart
import 'package:flutter_llama/flutter_llama.dart';

class LocalAiService implements AiService {
  LlamaModel? _model;
  
  Future<void> loadModel(String modelPath) async {
    _model = await LlamaModel.load(
      modelPath,
      contextSize: 2048,
      gpuLayers: 32,  // Use GPU if available
    );
  }
  
  Future<AiSuggestion> generateCommand(AiPrompt prompt) async {
    if (_model == null) throw ModelNotLoadedException();
    
    final systemPrompt = _buildSystemPrompt(prompt.context);
    final fullPrompt = '$systemPrompt\n\nUser: ${prompt.text}\n\nCommand:';
    
    final result = await _model!.generateCompletion(
      fullPrompt,
      maxTokens: 256,
      temperature: 0.3,
      stopSequences: ['\n\n', 'User:'],
    );
    
    return AiSuggestion(
      command: result.text.trim(),
      confidence: _estimateConfidence(result),
      explanation: null,  // Local models don't explain well
    );
  }
}
```

## Model Download Strategy

### Download Flow

```dart
Stream<DownloadProgress> downloadModel(String modelId) async* {
  final model = availableModels.firstWhere((m) => m.id == modelId);
  final url = 'https://huggingface.co/${model.huggingFaceRepo}/resolve/main/${model.fileName}';
  final targetPath = await _getModelPath(modelId);
  final partialPath = '$targetPath.partial';
  
  // Check for partial download (resume support)
  int startByte = 0;
  if (await File(partialPath).exists()) {
    startByte = await File(partialPath).length();
  }
  
  yield DownloadProgress(
    modelId: modelId,
    bytesDownloaded: startByte,
    totalBytes: model.sizeBytes,
    state: DownloadState.downloading,
  );
  
  // HTTP request with Range header for resume
  final request = http.Request('GET', Uri.parse(url));
  if (startByte > 0) {
    request.headers['Range'] = 'bytes=$startByte-';
  }
  
  final response = await http.Client().send(request);
  final file = File(partialPath).openWrite(mode: FileMode.append);
  
  int downloaded = startByte;
  await for (final chunk in response.stream) {
    file.add(chunk);
    downloaded += chunk.length;
    
    yield DownloadProgress(
      modelId: modelId,
      bytesDownloaded: downloaded,
      totalBytes: model.sizeBytes,
      state: DownloadState.downloading,
    );
  }
  
  await file.close();
  
  // Verify and rename
  yield DownloadProgress(..., state: DownloadState.verifying);
  await File(partialPath).rename(targetPath);
  
  yield DownloadProgress(..., state: DownloadState.completed);
}
```

## Memory Management

### Lifecycle

```dart
class LocalAiService {
  Timer? _unloadTimer;
  
  void _scheduleUnload() {
    _unloadTimer?.cancel();
    _unloadTimer = Timer(Duration(minutes: 5), () {
      if (_model != null && !_isGenerating) {
        unloadModel();
      }
    });
  }
  
  Future<AiSuggestion> generateCommand(AiPrompt prompt) async {
    _unloadTimer?.cancel();
    
    // Ensure model loaded
    if (_model == null) {
      await loadModel(await _getPreferredModelPath());
    }
    
    try {
      _isGenerating = true;
      return await _generate(prompt);
    } finally {
      _isGenerating = false;
      _scheduleUnload();
    }
  }
}
```

### App Lifecycle

```dart
// In main.dart or app initialization
WidgetsBinding.instance.addObserver(
  LifecycleEventHandler(
    onPaused: () => localAiService.unloadModel(),
    onResumed: () {}, // Reload on demand
  ),
);
```

## Prompt Engineering

### System Prompt Template

```dart
String _buildSystemPrompt(AiContext context) {
  return '''
You are a terminal command assistant. Output ONLY the command needed.
No explanations. No markdown. Just the raw command.

Environment:
- OS: ${context.platform}
- Shell: ${context.shell}
- Directory: ${context.workingDirectory}
${context.recentCommands.isNotEmpty ? '- Recent commands: ${context.recentCommands.take(3).join(", ")}' : ''}

Rules:
1. Output a single command unless user asks for multiple
2. Use common utilities available on ${context.platform}
3. Prefer safe commands (avoid rm -rf, etc. unless explicit)
''';
}
```

## Decisions

### D1: Model Storage Location

**Decision**: Store in app Documents directory, not bundled

**Rationale**:

- Keeps app download size small (~50MB vs 150MB+)
- Users can manage storage (delete unused models)
- Supports multiple model sizes
- Can update models without app update

### D2: Default Model

**Decision**: TinyLlama 1.1B Q4 (88MB)

**Rationale**:

- Works on all devices (low RAM requirement)
- Fast inference even on CPU
- Downloads quickly
- Good enough for simple command generation
- Users can upgrade to larger models if needed

### D3: GPU Acceleration

**Decision**: Enable by default, graceful fallback to CPU

**Rationale**:

- Significant speedup on supported devices (3-5x)
- flutter_llama handles detection automatically
- No user configuration needed
- CPU fallback ensures universal compatibility

### D4: Auto-unload Timer

**Decision**: Unload model after 5 minutes of inactivity

**Rationale**:

- Balances memory vs reload latency
- 5 minutes covers typical session gaps
- User likely moved to other app after longer
- Can be made configurable in settings later
