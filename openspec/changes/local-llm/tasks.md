# Tasks: Local LLM

## Prerequisites

- [ ] `ai-gateway` change must be completed (AiService interface)
- [ ] `ai-setup-flow` change should be in progress (for testing integration)

---

## Task Group 1: Package Integration

### 1.1 Add flutter_llama dependency

- [ ] Add `flutter_llama: ^1.1.2` to pubspec.yaml
- [ ] Run `flutter pub get`
- [ ] Verify package resolves correctly for iOS and Android

### 1.2 Platform configuration

- [ ] iOS: Ensure minimum deployment target meets flutter_llama requirements
- [ ] Android: Verify NDK and CMake configuration
- [ ] Test basic import compiles on both platforms

---

## Task Group 2: Domain Entities

### 2.1 Create LocalAiModel entity

- [ ] Create `lib/features/ai/domain/entities/local_ai_model.dart`
- [ ] Define LocalAiModel class with all fields
- [ ] Define ModelTier enum (tiny, small, medium)
- [ ] Add static list of availableModels
- [ ] Write unit tests

### 2.2 Create DownloadProgress entity

- [ ] Create `lib/features/ai/domain/entities/download_progress.dart`
- [ ] Define DownloadProgress class
- [ ] Define DownloadState enum
- [ ] Add progress percentage getter
- [ ] Write unit tests

---

## Task Group 3: Model Manager

### 3.1 Create ModelManager class

- [ ] Create `lib/features/ai/data/repositories/model_repository.dart`
- [ ] Implement `getDownloadedModels()` - scan storage directory
- [ ] Implement `isModelDownloaded()` - check file exists
- [ ] Implement `getModelPath()` - return full path
- [ ] Implement `getTotalStorageUsed()` - sum file sizes
- [ ] Write unit tests with mocked file system

### 3.2 Implement model download

- [ ] Implement `downloadModel()` stream
- [ ] Add HTTP client with Range header support (resume)
- [ ] Save to .partial file during download
- [ ] Rename on completion
- [ ] Implement `cancelDownload()` - abort stream
- [ ] Write unit tests with mocked HTTP client

### 3.3 Implement model deletion

- [ ] Implement `deleteModel()` - remove file
- [ ] Handle file not found gracefully
- [ ] Write unit tests

---

## Task Group 4: LocalAiService Implementation

### 4.1 Create LocalAiService class

- [ ] Create `lib/features/ai/data/services/local_ai_service.dart`
- [ ] Implement AiService interface
- [ ] Add constructor with ModelManager dependency
- [ ] Add privacyMode getter returning AiPrivacyMode.local

### 4.2 Implement model loading

- [ ] Implement `loadModel(String path)`
- [ ] Use flutter_llama's LlamaModel.load()
- [ ] Configure context size, GPU layers
- [ ] Implement `unloadModel()`
- [ ] Add `isModelLoaded` getter
- [ ] Write unit tests with mocked flutter_llama

### 4.3 Implement command generation

- [ ] Implement `generateCommand(AiPrompt prompt)`
- [ ] Build system prompt with context
- [ ] Call flutter_llama generateCompletion()
- [ ] Parse result into AiSuggestion
- [ ] Handle timeout (30s max)
- [ ] Write unit tests

### 4.4 Implement streaming generation

- [ ] Implement `generateCommandStream(AiPrompt prompt)`
- [ ] Yield AiStreamEvent for each token
- [ ] Handle cancellation
- [ ] Write unit tests

### 4.5 Implement availability check

- [ ] Implement `isAvailable()` - checks model loaded
- [ ] Return false if no model downloaded
- [ ] Write unit tests

---

## Task Group 5: Memory Management

### 5.1 Implement auto-unload timer

- [ ] Add 5-minute inactivity timer
- [ ] Cancel timer on generation start
- [ ] Restart timer on generation complete
- [ ] Unload model when timer fires
- [ ] Write unit tests

### 5.2 Implement app lifecycle handling

- [ ] Add WidgetsBindingObserver
- [ ] Unload model on app pause
- [ ] Do NOT auto-load on resume (load on demand)
- [ ] Write integration tests

---

## Task Group 6: Prompt Engineering

### 6.1 Create prompt builder

- [ ] Create `lib/features/ai/data/services/prompt_builder.dart`
- [ ] Implement system prompt template
- [ ] Include platform, shell, cwd from context
- [ ] Include recent commands if available
- [ ] Write unit tests for various contexts

### 6.2 Optimize for small models

- [ ] Test prompts with TinyLlama
- [ ] Adjust template for best results
- [ ] Add stop sequences to prevent rambling
- [ ] Document working prompt patterns

---

## Task Group 7: Error Handling

### 7.1 Define exceptions

- [ ] Create `ModelNotLoadedException`
- [ ] Create `ModelLoadException`
- [ ] Create `InferenceTimeoutException`
- [ ] Create `InsufficientMemoryException`

### 7.2 Implement error recovery

- [ ] Handle GPU initialization failure → fall back to CPU
- [ ] Handle model load failure → clear and re-download
- [ ] Handle inference timeout → cancel and report
- [ ] Write tests for each error path

---

## Task Group 8: Provider Integration

### 8.1 Create Riverpod providers

- [ ] Create `localAiServiceProvider`
- [ ] Create `modelManagerProvider`
- [ ] Create `downloadProgressProvider` (family by modelId)
- [ ] Wire up to existing `aiServiceProvider`

### 8.2 Update AiServiceFactory

- [ ] Add case for AiMode.local
- [ ] Return LocalAiService instance
- [ ] Inject ModelManager dependency

---

## Task Group 9: Testing

### 9.1 Unit tests

- [ ] LocalAiModel entity tests
- [ ] DownloadProgress entity tests
- [ ] ModelManager tests (mocked FS)
- [ ] LocalAiService tests (mocked flutter_llama)
- [ ] PromptBuilder tests

### 9.2 Integration tests

- [ ] Model download with real HuggingFace (skip in CI)
- [ ] Model load/unload lifecycle
- [ ] Command generation end-to-end
- [ ] Memory management under pressure

---

## Task Group 10: Documentation

### 10.1 Code documentation

- [ ] Add dartdoc to all public APIs
- [ ] Document model requirements
- [ ] Document error conditions

### 10.2 User documentation

- [ ] Document storage requirements
- [ ] Document model capabilities/tradeoffs
- [ ] Add troubleshooting section

---

## Completion Criteria

- [ ] All unit tests pass
- [ ] Integration tests pass (can skip real download in CI)
- [ ] LocalAiService passes AiService contract tests
- [ ] Model downloads resume correctly after interruption
- [ ] Memory is released when app backgrounds
- [ ] Works on both iOS and Android
