# L2 Contract: ModelManager

## Purpose

Manages downloading, storage, and lifecycle of local LLM models. Handles
HuggingFace downloads with progress tracking and resume capability.

## Parent

- L3: `ai-setup-flow` (wizard triggers model download)

## Interface

```dart
/// Manages local LLM model files
class ModelManager {
  ModelManager({
    required FileSystem fileSystem,
    required HttpClient httpClient,
  });
  
  /// List all available models (downloadable)
  List<LocalAiModel> get availableModels;
  
  /// List downloaded models on device
  Future<List<LocalAiModel>> getDownloadedModels();
  
  /// Check if a specific model is downloaded
  Future<bool> isModelDownloaded(String modelId);
  
  /// Get path to downloaded model file
  Future<String?> getModelPath(String modelId);
  
  /// Download a model with progress
  Stream<DownloadProgress> downloadModel(String modelId);
  
  /// Cancel in-progress download
  Future<void> cancelDownload(String modelId);
  
  /// Delete a downloaded model
  Future<void> deleteModel(String modelId);
  
  /// Get total storage used by models
  Future<int> getTotalStorageUsed();
}
```

## Data Types

```dart
/// Model metadata
class LocalAiModel {
  final String id;              // e.g., 'tinyllama-1.1b-q4'
  final String displayName;     // e.g., 'TinyLlama 1.1B'
  final String description;
  final int sizeBytes;          // Download size
  final int ramRequired;        // Minimum RAM needed
  final String huggingFaceRepo; // e.g., 'TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF'
  final String fileName;        // e.g., 'tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf'
  final ModelTier tier;
  final bool supportsGpu;
}

enum ModelTier {
  tiny,   // <100MB, basic capability
  small,  // 100-500MB, good balance
  medium, // 500MB-2GB, best quality
}

/// Download progress events
class DownloadProgress {
  final String modelId;
  final int bytesDownloaded;
  final int totalBytes;
  final DownloadState state;
  final String? error;
  
  double get progress => bytesDownloaded / totalBytes;
}

enum DownloadState {
  queued,
  downloading,
  verifying,
  completed,
  failed,
  cancelled,
}
```

## Available Models (Curated List)

```dart
static const availableModels = [
  LocalAiModel(
    id: 'tinyllama-1.1b-q4',
    displayName: 'TinyLlama 1.1B',
    description: 'Fastest, works on all devices. Good for simple commands.',
    sizeBytes: 88 * 1024 * 1024,  // 88 MB
    ramRequired: 600 * 1024 * 1024,
    huggingFaceRepo: 'TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF',
    fileName: 'tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
    tier: ModelTier.tiny,
    supportsGpu: true,
  ),
  LocalAiModel(
    id: 'phi-3-mini-q4',
    displayName: 'Phi-3 Mini',
    description: 'Best reasoning for size. Recommended for most users.',
    sizeBytes: 800 * 1024 * 1024,  // 800 MB
    ramRequired: 2 * 1024 * 1024 * 1024,
    huggingFaceRepo: 'microsoft/Phi-3-mini-4k-instruct-gguf',
    fileName: 'Phi-3-mini-4k-instruct-q4.gguf',
    tier: ModelTier.small,
    supportsGpu: true,
  ),
  LocalAiModel(
    id: 'llama-3.2-1b-q4',
    displayName: 'Llama 3.2 1B',
    description: 'Meta\'s latest small model. Good instruction following.',
    sizeBytes: 600 * 1024 * 1024,  // 600 MB
    ramRequired: 1500 * 1024 * 1024,
    huggingFaceRepo: 'hugging-quants/Llama-3.2-1B-Instruct-Q4_K_M-GGUF',
    fileName: 'llama-3.2-1b-instruct-q4_k_m.gguf',
    tier: ModelTier.small,
    supportsGpu: true,
  ),
];
```

## Behavior

### Download Flow

```
GIVEN user selects a model to download
WHEN downloadModel() is called
THEN download starts from HuggingFace CDN
AND progress events stream to UI
AND partial file is saved with .partial extension

GIVEN download completes
WHEN file hash is verified
THEN .partial extension is removed
AND model becomes available for loading

GIVEN download is interrupted (app killed, network loss)
WHEN downloadModel() is called again for same model
THEN download resumes from last byte (HTTP Range header)
```

### Storage Management

```
GIVEN user wants to delete a model
WHEN deleteModel() is called
THEN model file is removed from disk
AND cached model metadata is cleared

GIVEN device storage is low (<500MB free)
WHEN user tries to download a model
THEN warning is shown with space needed
AND download is blocked if insufficient
```

## Download URLs

Base URL pattern:

```
https://huggingface.co/{repo}/resolve/main/{fileName}
```

Example:

```
https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
```

## Storage Location

```
iOS: App Documents/models/{modelId}.gguf
Android: App Internal Storage/models/{modelId}.gguf
```

Files in Documents are:

- Excluded from iCloud backup (via .nosync or resource fork)
- Visible in Files app on iOS for manual management
- Preserved across app updates

## Error Handling

| Error           | Recovery                                   |
| --------------- | ------------------------------------------ |
| Network timeout | Retry with exponential backoff             |
| Hash mismatch   | Delete partial, re-download                |
| Disk full       | Show error, suggest deleting old models    |
| 404 Not Found   | Model removed from HuggingFace, update app |
