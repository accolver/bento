# Tasks: Remote AI (Ollama + Cloud Providers via SSH)

## Prerequisites

- [x] `ai-gateway` change must be completed (AiService interface)
- [x] `ssh-connectivity` change must be completed (SSH session/exec)
- [x] `ai-setup-flow` change must be completed (setup wizard)

---

## Task Group 1: Provider Registry & Domain Entities

### 1.1 Create RemoteCloudProvider enum and RemoteProviderConfig

- [x] Create `lib/features/ai/domain/entities/remote_ai_provider.dart`
- [x] Define `RemoteCloudProvider` enum (anthropic, openai, groq, google,
      mistral, openRouter, xai, deepseek, fireworks, togetherAi, cohere)
- [x] Define `ApiFormat` enum (openaiCompatible, anthropicMessages)
- [x] Define `RemoteProviderConfig` class with envVars, apiBaseUrl,
      defaultModel, apiFormat, authHeaderName, authHeaderFormat, qualityRank,
      extraHeaders
- [x] Define `RemoteProviderRegistry` with static provider list and lookup
      methods
- [x] Write unit tests for registry lookups and env var name collection

### 1.2 Create OllamaModel entity

- [x] Create `lib/features/ai/domain/entities/ollama_model.dart`
- [x] Define freezed OllamaModel class (name, digest, sizeBytes, modifiedAt,
      details)
- [x] Add `displayName` getter (formatted name)
- [x] Add `formattedSize` getter (human-readable size)
- [x] Implement fromJson factory
- [x] Write unit tests

### 1.3 Create RemoteAiConfig entity

- [x] Create `lib/features/ai/domain/entities/remote_ai_config.dart`
- [x] Define freezed config class (hostId, backendType, ollamaModel,
      cloudProvider, envVarName, ollamaPort)
- [x] Define `RemoteBackendType` enum (ollama, cloudProxy)
- [x] Write unit tests

### 1.4 Create unified detection result entities

- [x] Create `lib/features/ai/domain/entities/remote_ai_detection.dart`
- [x] Define `DetectedCloudProvider` class (provider, envVarName, displayName,
      defaultModel, qualityRank)
- [x] Define `RemoteAiDetectionResult` class (hostId, ollamaModels,
      cloudProviders, checkedAt, detectionMethod)
- [x] Define sealed `RemoteAiDetectionEvent` class
- [x] Define `RemoteAiDetectedEvent` and `RemoteAiNotFoundEvent`
- [x] Add `hasAnyProvider` getter, `bestProvider` getter
- [x] Write unit tests

---

## Task Group 2: Shell Escaping Utility

### 2.1 Implement JSON shell escaping

- [x] Create `lib/features/ai/data/utils/shell_escape.dart`
- [x] Implement `ShellEscape.escape()` — single-quote safe escaping
- [x] Handle single quotes, double quotes, backticks, dollar signs
- [x] Handle unicode and emoji
- [x] Handle newlines within JSON
- [x] Write comprehensive unit tests with edge cases

---

## Task Group 3: OllamaDetector Implementation

### 3.1 Create OllamaDetector class

- [x] Create `lib/features/ai/data/services/ollama_detector.dart`
- [x] Implement `detect(SshSession)` method
- [x] Execute `curl -s --connect-timeout 2 localhost:11434/api/tags` via SSH
- [x] Parse JSON response into List<OllamaModel>
- [x] Return null on any failure (silent detection)
- [x] 3-second timeout on SSH exec
- [x] Write unit tests with mocked SSH session

---

## Task Group 4: EnvProviderDetector Implementation

### 4.1 Create EnvProviderDetector class

- [x] Create `lib/features/ai/data/services/env_provider_detector.dart`
- [x] Implement `detect(SshSession)` method
- [x] Build batched `test -n "$VAR"` command from RemoteProviderRegistry
- [x] Execute via SSH exec
- [x] Parse newline-separated output to determine detected providers
- [x] Sort results by qualityRank
- [x] 5-second timeout

### 4.2 Implement login shell fallback

- [x] If initial detection returns no providers, retry with `bash -l -c`
- [x] If bash fails, try `zsh -l -c`
- [x] Cache which shell strategy works per host
- [x] Write unit tests for fallback logic

### 4.3 Handle duplicate env vars for same provider

- [x] When both GOOGLE_API_KEY and GEMINI_API_KEY are found, include Google once
- [x] When both ANTHROPIC_API_KEY and CLAUDE_CODE_OAUTH_TOKEN are found, prefer
      ANTHROPIC_API_KEY
- [x] Write unit tests for deduplication

---

## Task Group 5: Unified RemoteAiDetector

### 5.1 Create RemoteAiDetector orchestrator

- [x] Create `lib/features/ai/data/services/remote_ai_detector.dart`
- [x] Compose OllamaDetector and EnvProviderDetector
- [x] Run both detections in parallel after SSH connect
- [x] Combine results into RemoteAiDetectionResult
- [x] Emit RemoteAiDetectionEvent

### 5.2 Implement caching

- [x] Cache detection results by hostId
- [x] Implement `getCachedResult(String hostId)`
- [x] Implement `clearCache(String hostId)`
- [x] Expire cache after 5 minutes
- [x] Write unit tests

### 5.3 Implement SSH lifecycle integration

- [x] Listen for SSH connection events
- [x] Delay detection by 1 second after connect (let connection settle)
- [x] Clear cache on disconnect
- [x] Re-detect on reconnect
- [x] Write unit tests

---

## Task Group 6: Backend Implementations

### 6.1 Create RemoteBackend abstract class

- [x] Create `lib/features/ai/data/services/remote_backend.dart`
- [x] Define abstract methods: generateCommand, generateCommandStream,
      summarizeOutput
- [x] Define isConfigured, displayName, privacyDescription getters

### 6.2 Implement OllamaBackend

- [x] Create `lib/features/ai/data/services/ollama_backend.dart`
- [x] Implement command generation via curl to localhost:11434
- [x] Build OpenAI-compatible request body with model, messages, temperature
- [x] Parse OpenAI-compatible response format
- [x] Implement streaming via curl -sN and SSE parsing
- [x] Implement summarizeOutput
- [x] Write unit tests with mocked SSH session

### 6.3 Implement CloudProxyBackend

- [x] Create `lib/features/ai/data/services/cloud_proxy_backend.dart`
- [x] Implement OpenAI-compatible curl builder (for OpenAI, Groq, Mistral, xAI,
      etc.)
- [x] Implement Anthropic Messages API curl builder
- [x] Use `$ENV_VAR` shell expansion in auth headers (key-opaque)
- [x] Add provider-specific extra headers (e.g., anthropic-version)
- [x] Parse both OpenAI and Anthropic response formats
- [x] Implement streaming for both formats
- [x] Implement summarizeOutput
- [x] Write unit tests for each provider format

### 6.4 Test curl commands for each provider

- [x] Verify Anthropic curl template produces correct request
- [x] Verify OpenAI curl template produces correct request
- [x] Verify Groq curl template produces correct request
- [x] Verify Google Gemini curl template produces correct request
- [x] Verify OpenRouter curl template produces correct request
- [x] Verify remaining providers (Mistral, xAI, DeepSeek, Fireworks, Together,
      Cohere)

---

## Task Group 7: RemoteAiService Implementation

### 7.1 Create RemoteAiService class

- [x] Create `lib/features/ai/data/services/remote_ai_service.dart`
- [x] Implement AiService interface
- [x] Delegate to active RemoteBackend (OllamaBackend or CloudProxyBackend)
- [x] Add privacyMode getter returning AiPrivacyMode.remote

### 7.2 Implement backend switching

- [x] Implement `switchBackend(RemoteBackend)` method
- [x] Update active backend
- [x] Persist selection per-host in RemoteAiConfig via SharedPreferences

### 7.3 Implement connection lifecycle

- [x] Track connection state (isConnected)
- [x] Implement onDisconnected() — mark unavailable, emit event
- [x] Implement onReconnected(SshSession) — update session, trigger re-detect
- [x] Implement isAvailable() — check connected + backend configured
- [x] Implement dispose() — clean up streams
- [x] Write unit tests for lifecycle state machine

---

## Task Group 8: Error Handling

### 8.1 Define exception classes

- [x] Create `RemoteDisconnectedException`
- [x] Create `RemoteExecutionException` (with exitCode and stderr)
- [x] Create `RemoteParseException` (with raw response)
- [x] Create `RemoteApiException` (with provider name and API error)
- [x] Create `CurlNotFoundException`
- [x] Create `RateLimitException` (with retry-after)

### 8.2 Implement error recovery

- [x] SSH disconnect → mark unavailable, await reconnect
- [x] curl not found → exit code 127 throws CurlNotFoundException
- [x] curl exec failure → surface stderr in RemoteExecutionException
- [x] Invalid JSON → RemoteParseException with raw response snippet
- [x] API error responses → parse error messages from provider-specific formats
- [x] Rate limiting → extract retry-after from message, RateLimitException
- [x] Timeout → cancel and allow retry (via AiServiceException.isRetryable)
- [x] Write tests for each error path

---

## Task Group 9: Riverpod Provider Integration

### 9.1 Create Riverpod providers

- [x] Create `lib/features/ai/presentation/providers/remote_ai_providers.dart`
- [x] Create `remoteAiDetectorProvider` (keepAlive, listens to SSH events)
- [x] Create `remoteAiDetectionResultProvider` (family by hostId)
- [x] Create `remoteAiServiceProvider` (family by hostId)
- [x] Create `remoteAiConfigProvider` (persisted per host via SharedPreferences)
- [x] Create `ollamaModelsProvider` (family by hostId)
- [x] Create `detectedCloudProvidersProvider` (family by hostId)

### 9.2 Update AiServiceFactory

- [x] Update `createRemoteService()` to return actual RemoteAiService
- [x] Accept detection result to determine which backend to use
- [x] Create correct backend (OllamaBackend or CloudProxyBackend) based on
      user's saved RemoteAiConfig
- [x] Fall back to best detected provider if no saved preference

### 9.3 Wire into SSH connection lifecycle

- [x] Start RemoteAiDetector when SSH connects (1s delay)
- [x] Pass detection results to AI service layer (auto-initialize)
- [x] Clean up on SSH disconnect (clear cache, notify service)
- [x] Re-detect on reconnect (via cache clear + re-trigger)

---

## Task Group 10: UI Components

### 10.1 Create detection notification widget

- [x] Create `lib/features/ai/presentation/widgets/remote_ai_notification.dart`
- [x] Non-intrusive banner/snackbar: "AI providers detected on [hostname]"
- [x] Show count of detected providers (e.g., "3 AI providers found")
- [x] Tap → opens provider selector
- [x] Dismiss → remembers dismissal per host
- [x] Write widget tests

### 10.2 Create provider selector widget

- [x] Create
      `lib/features/ai/presentation/widgets/remote_provider_selector.dart`
- [x] Show both Ollama models and cloud providers in ranked list
- [x] Highlight recommended provider (top qualityRank)
- [x] Show provider name, icon/badge, and description
- [x] For Ollama: show model name and size
- [x] For cloud: show provider name and "Keys on remote host"
- [x] Privacy badges: "Local inference" vs "Cloud via remote"
- [x] Write widget tests

### 10.3 Create connection status indicator

- [x] Show "Remote AI: [provider] on [host]" when active
- [x] Show "Disconnected" state when SSH drops
- [x] Animate reconnection state
- [x] Tap → opens provider selector to change
- [x] Write widget tests

### 10.4 Update RemoteDetectStep in setup wizard

- [x] Expand beyond just Ollama toggle
- [x] Show detected providers from current SSH session (if any)
- [x] Allow enabling/disabling auto-detection
- [x] Show privacy explanation for both Ollama and cloud proxy modes
- [x] Update "How it works" section for cloud proxy

---

## Task Group 11: AI Setup Wizard Integration

### 11.1 Integrate detection into wizard flow

- [x] Show "Remote AI" option in mode selection when SSH connected
- [x] If providers already detected, show them in wizard
- [x] If not detected yet, show "Detecting..." with spinner
- [x] If nothing detected, show "No AI found on remote host" with explanation

### 11.2 Handle dynamic availability

- [x] Update wizard if detection completes while wizard is open
- [x] Gray out remote option if SSH disconnects during wizard
- [x] Re-enable when reconnected
- [x] Remember selection and skip detection on next wizard visit for same host

---

## Task Group 12: Testing

### 12.1 Unit tests

- [x] RemoteProviderRegistry — all providers, lookup, env var collection
- [x] OllamaModel entity — displayName, formattedSize, fromJson
- [x] RemoteAiConfig entity — copyWith, defaults
- [x] RemoteAiDetectionResult — hasAnyProvider, bestProvider
- [x] OllamaDetector — success, failure, timeout (mocked SSH)
- [x] EnvProviderDetector — success, partial, none, login shell fallback
- [x] RemoteAiDetector — combined detection, caching, lifecycle
- [x] OllamaBackend — command generation, streaming, response parsing
- [x] CloudProxyBackend — all provider formats, curl building, response parsing
- [x] RemoteAiService — backend switching, lifecycle, delegation
- [x] ShellEscape — all edge cases

### 12.2 Integration tests

- [x] Full detection flow with mocked SSH (Ollama + env vars)
- [x] Command generation end-to-end through RemoteAiService
- [x] Streaming generation end-to-end
- [x] Disconnect/reconnect cycle
- [x] Provider switching
- [x] Setup wizard flow with detection

### 12.3 Widget tests

- [x] RemoteAiNotification — display, tap, dismiss
- [x] RemoteProviderSelector — provider list, selection, ranking
- [x] Connection status indicator — states, animation
- [x] Updated RemoteDetectStep — expanded UI

---

## Task Group 13: Documentation

### 13.1 Code documentation

- [x] Add dartdoc to all public APIs
- [x] Document security model (key-opaque architecture)
- [x] Document SSH requirements and curl dependency
- [x] Document provider-specific API format differences

### 13.2 User-facing documentation

- [x] Document supported AI providers and their env vars
- [x] Document how detection works (what Bento checks, what it doesn't)
- [x] Document troubleshooting (curl missing, env vars not detected, login shell
      issues)
- [x] Document Ollama setup on server
- [x] Add FAQ: "Does Bento see my API keys?" → No

---

## Completion Criteria

- [x] All unit tests pass
- [x] Integration tests pass (mocked SSH in CI)
- [x] RemoteAiService passes AiService contract tests
- [x] Ollama detected automatically on SSH connect
- [x] Cloud providers detected via env var check on SSH connect
- [x] Detection notification shown to user (opt-in)
- [x] Provider selection UI works with ranked list
- [x] Model selection persists per-host
- [x] Service handles disconnect/reconnect gracefully
- [x] Shell escaping handles all edge cases
- [x] Cloud proxy calls work for Anthropic (Messages API format)
- [x] Cloud proxy calls work for OpenAI-compatible providers
- [x] Streaming works for both Ollama and cloud proxy
- [x] API keys never leave the remote machine (verified in tests)
- [x] `flutter analyze` passes with no errors
- [x] `flutter test` passes with no failures
