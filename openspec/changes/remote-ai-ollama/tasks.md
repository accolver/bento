# Tasks: Remote AI (Ollama via SSH)

## Prerequisites

- [ ] `ai-gateway` change must be completed (AiService interface)
- [ ] `ssh-connectivity` change must be completed (SSH session/exec)
- [ ] `ai-setup-flow` change should be in progress (for testing integration)

---

## Task Group 1: Domain Entities

### 1.1 Create OllamaModel entity

- [ ] Create `lib/features/ai/domain/entities/ollama_model.dart`
- [ ] Define OllamaModel class with fields from /api/tags response
- [ ] Add displayName getter (formatted name)
- [ ] Add formattedSize getter (human-readable size)
- [ ] Implement fromJson factory
- [ ] Write unit tests

### 1.2 Create RemoteAiConfig entity

- [ ] Create `lib/features/ai/domain/entities/remote_ai_config.dart`
- [ ] Define config class (hostId, selectedModel, port)
- [ ] Add copyWith method
- [ ] Write unit tests

### 1.3 Create detection events

- [ ] Create `lib/features/ai/domain/entities/ollama_detection.dart`
- [ ] Define OllamaDetectionResult class
- [ ] Define sealed OllamaDetectionEvent class
- [ ] Define OllamaDetectedEvent and OllamaNotFoundEvent
- [ ] Write unit tests

---

## Task Group 2: OllamaDetector Implementation

### 2.1 Create OllamaDetector class

- [ ] Create `lib/features/ai/data/services/ollama_detector.dart`
- [ ] Add constructor with SshConnectionManager dependency
- [ ] Implement detectionEvents stream
- [ ] Add cache map for results

### 2.2 Implement automatic detection

- [ ] Listen for SshConnectedEvent
- [ ] Delay probe by 1 second after connect
- [ ] Execute curl command via SSH exec
- [ ] Parse response and extract models
- [ ] Emit appropriate detection event

### 2.3 Implement caching

- [ ] Cache results by hostId
- [ ] Implement getCachedResult()
- [ ] Implement clearCache()
- [ ] Expire cache after 5 minutes
- [ ] Write unit tests with mocked SSH

### 2.4 Implement manual detection

- [ ] Implement detectForSession()
- [ ] Bypass cache and probe immediately
- [ ] Update cache with new result
- [ ] Write unit tests

---

## Task Group 3: RemoteAiService Implementation

### 3.1 Create RemoteAiService class

- [ ] Create `lib/features/ai/data/services/remote_ai_service.dart`
- [ ] Implement AiService interface
- [ ] Add constructor with SshSession, RemoteAiConfig dependencies
- [ ] Add privacyMode getter returning AiPrivacyMode.remote

### 3.2 Implement model management

- [ ] Implement `getAvailableModels()` - call /api/tags
- [ ] Implement `selectModel(String modelName)` - update config
- [ ] Add `selectedModel` getter
- [ ] Save selection per-host
- [ ] Write unit tests

### 3.3 Implement command generation

- [ ] Implement `generateCommand(AiPrompt prompt)`
- [ ] Build request JSON with messages
- [ ] Escape JSON for shell command
- [ ] Execute curl via SSH session
- [ ] Parse JSON response into AiSuggestion
- [ ] Write unit tests with mocked SSH

### 3.4 Implement streaming generation

- [ ] Implement `generateCommandStream(AiPrompt prompt)`
- [ ] Use SSH executeStream for streaming output
- [ ] Parse SSE format from curl -N output
- [ ] Yield AiStreamEvent for each token
- [ ] Handle stream completion
- [ ] Write unit tests

### 3.5 Implement availability check

- [ ] Implement `isAvailable()` - check SSH connected and models exist
- [ ] Track connection state
- [ ] Write unit tests

### 3.6 Implement connection lifecycle

- [ ] Add `isConnected` getter
- [ ] Implement `onDisconnected()` handler
- [ ] Implement `onReconnected(SshSession)` handler
- [ ] Emit status events on state change
- [ ] Write unit tests

---

## Task Group 4: Shell Escaping

### 4.1 Implement JSON shell escaping

- [ ] Create shell escape utility function
- [ ] Handle single quotes properly
- [ ] Handle special characters
- [ ] Handle unicode
- [ ] Write comprehensive tests with edge cases

### 4.2 Test with various prompts

- [ ] Test prompts with quotes
- [ ] Test prompts with newlines
- [ ] Test prompts with special characters
- [ ] Test prompts with unicode/emoji

---

## Task Group 5: Error Handling

### 5.1 Define exceptions

- [ ] Create `RemoteDisconnectedException`
- [ ] Create `RemoteExecutionException`
- [ ] Create `RemoteParseException`
- [ ] Create `OllamaNotFoundOnHostException`
- [ ] Create `CurlNotFoundException`

### 5.2 Implement error recovery

- [ ] Handle SSH disconnect → mark unavailable
- [ ] Handle curl failure → report error
- [ ] Handle invalid JSON → report parse error
- [ ] Handle model not found → fall back to first model
- [ ] Handle timeout → cancel and report
- [ ] Write tests for each error path

### 5.3 Detect missing curl

- [ ] Check for curl availability on first use
- [ ] Cache curl availability per host
- [ ] Show user-friendly error if curl missing
- [ ] Write tests

---

## Task Group 6: Provider Integration

### 6.1 Create Riverpod providers

- [ ] Create `ollamaDetectorProvider`
- [ ] Create `remoteAiServiceProvider` (family by hostId)
- [ ] Create `remoteAiConfigProvider` (persisted per host)
- [ ] Create `ollamaModelsProvider` (family by hostId)

### 6.2 Integrate with SSH events

- [ ] Wire OllamaDetector to SshConnectionManager
- [ ] Start detection on SSH connect
- [ ] Clean up on SSH disconnect

### 6.3 Update AiServiceFactory

- [ ] Add case for AiMode.remote
- [ ] Return RemoteAiService instance
- [ ] Inject SshSession dependency

---

## Task Group 7: UI Components

### 7.1 Create model selector widget

- [ ] Create `lib/features/ai/presentation/widgets/remote_model_selector.dart`
- [ ] Dropdown showing available Ollama models
- [ ] Show model name and size
- [ ] Indicate current selection
- [ ] Write widget tests

### 7.2 Create connection status indicator

- [ ] Show "Connected to Ollama on {host}" when available
- [ ] Show "Disconnected" when SSH drops
- [ ] Animate reconnection attempts
- [ ] Write widget tests

---

## Task Group 8: AI Setup Wizard Integration

### 8.1 Add remote option to wizard

- [ ] Show "Use server's Ollama" when detected
- [ ] Display available models
- [ ] Allow model selection
- [ ] Save configuration

### 8.2 Handle dynamic availability

- [ ] Update wizard if Ollama detected while open
- [ ] Gray out remote option if SSH disconnects
- [ ] Re-enable when reconnected

---

## Task Group 9: Testing

### 9.1 Unit tests

- [ ] OllamaModel entity tests
- [ ] RemoteAiConfig entity tests
- [ ] OllamaDetector tests (mocked SSH)
- [ ] RemoteAiService tests (mocked SSH)
- [ ] Shell escaping tests

### 9.2 Integration tests

- [ ] Detection with real SSH + Ollama (skip in CI)
- [ ] Command generation end-to-end
- [ ] Streaming generation
- [ ] Disconnect/reconnect handling

### 9.3 Widget tests

- [ ] RemoteModelSelector widget
- [ ] Connection status indicator

---

## Task Group 10: Documentation

### 10.1 Code documentation

- [ ] Add dartdoc to all public APIs
- [ ] Document SSH requirements
- [ ] Document Ollama version requirements

### 10.2 User documentation

- [ ] Document how to install Ollama on server
- [ ] Document which models work best
- [ ] Document troubleshooting (curl not found, etc.)
- [ ] Add FAQ section

---

## Completion Criteria

- [ ] All unit tests pass
- [ ] Integration tests pass (can skip real SSH in CI)
- [ ] RemoteAiService passes AiService contract tests
- [ ] Ollama detected automatically on SSH connect
- [ ] Model selection persists per-host
- [ ] Service handles disconnect/reconnect gracefully
- [ ] Shell escaping handles all edge cases
- [ ] Works with common Ollama models (llama3, codellama, mistral)
