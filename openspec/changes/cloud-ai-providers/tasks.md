# Tasks: Cloud AI Providers

## Prerequisites

- [ ] `ai-gateway` change must be completed (AiService interface)
- [ ] `credential-storage` change must be completed (for API key storage)
- [ ] `ai-setup-flow` change should be in progress (for testing integration)

---

## Task Group 1: Domain Entities

### 1.1 Create CloudModel entity

- [ ] Create `lib/features/ai/domain/entities/cloud_model.dart`
- [ ] Define CloudModel class with all fields (id, displayName, provider, costs,
      etc.)
- [ ] Add static list of recommendedModels
- [ ] Write unit tests

### 1.2 Create CloudAiConfig entity

- [ ] Create `lib/features/ai/domain/entities/cloud_ai_config.dart`
- [ ] Define config class (selectedModelId, maxTokens, temperature,
      consentGiven)
- [ ] Add copyWith method
- [ ] Write unit tests

### 1.3 Create UsageStats entity

- [ ] Create `lib/features/ai/domain/entities/usage_stats.dart`
- [ ] Define stats class (requests, tokens, estimated cost)
- [ ] Add calculation methods
- [ ] Write unit tests

---

## Task Group 2: CloudAiService Implementation

### 2.1 Create CloudAiService class

- [ ] Create `lib/features/ai/data/services/cloud_ai_service.dart`
- [ ] Implement AiService interface
- [ ] Add constructor with HttpClient, CredentialVault dependencies
- [ ] Add privacyMode getter returning AiPrivacyMode.cloud

### 2.2 Implement API key management

- [ ] Implement `setApiKey(String key)` - validate and store
- [ ] Implement `clearApiKey()` - remove from vault
- [ ] Implement `hasApiKey()` - check if configured
- [ ] Use credential vault for secure storage
- [ ] Write unit tests with mocked vault

### 2.3 Implement model selection

- [ ] Implement `getAvailableModels()` - return curated + fetched list
- [ ] Implement `selectModel(String modelId)` - update config
- [ ] Add `selectedModel` getter
- [ ] Write unit tests

### 2.4 Implement command generation

- [ ] Implement `generateCommand(AiPrompt prompt)`
- [ ] Build request body with messages
- [ ] Send to OpenRouter API
- [ ] Parse response into AiSuggestion
- [ ] Update usage stats
- [ ] Write unit tests with mocked HTTP

### 2.5 Implement streaming generation

- [ ] Implement `generateCommandStream(AiPrompt prompt)`
- [ ] Open SSE connection to OpenRouter
- [ ] Parse `data: {...}` chunks
- [ ] Yield AiStreamEvent for each token
- [ ] Handle `[DONE]` marker
- [ ] Write unit tests

### 2.6 Implement availability check

- [ ] Implement `isAvailable()` - check API key exists and valid
- [ ] Cache validation result (re-validate on error)
- [ ] Write unit tests

---

## Task Group 3: Error Handling

### 3.1 Define exceptions

- [ ] Create `ApiKeyInvalidException`
- [ ] Create `RateLimitException` with retryAfter
- [ ] Create `ModelUnavailableException`
- [ ] Create `NetworkException`
- [ ] Create `CloudAiException` (generic)

### 3.2 Implement error recovery

- [ ] Handle 401 → prompt to re-enter key
- [ ] Handle 429 → parse retry-after, inform user
- [ ] Handle 503 → try fallback model
- [ ] Handle network errors → retry with backoff
- [ ] Write tests for each error path

### 3.3 Implement model fallback

- [ ] Define fallback model (gpt-4o-mini)
- [ ] Implement `_generateWithFallback()` method
- [ ] Track when fallback was used
- [ ] Notify user of fallback
- [ ] Write unit tests

---

## Task Group 4: Privacy & Consent

### 4.1 Implement consent flow

- [ ] Add `consentGiven` to CloudAiConfig
- [ ] Implement `ensureConsentBeforeRequest()` method
- [ ] Call consent callback if not yet given
- [ ] Block request if consent declined
- [ ] Write unit tests

### 4.2 Create consent dialog content

- [ ] Define consent message explaining data transmission
- [ ] List what IS sent (prompts, basic context)
- [ ] List what is NOT sent (history, outputs, files)
- [ ] Add link to OpenRouter privacy policy

---

## Task Group 5: Usage Tracking

### 5.1 Implement usage tracking

- [ ] Parse token counts from OpenRouter response
- [ ] Calculate estimated cost based on model pricing
- [ ] Store usage stats in local database
- [ ] Implement `getUsageStats()` method

### 5.2 Create usage display

- [ ] Create `lib/features/ai/presentation/widgets/usage_stats_widget.dart`
- [ ] Show requests, tokens, estimated cost
- [ ] Show period (daily/weekly/monthly)
- [ ] Write widget tests

---

## Task Group 6: API Key Input Widget

### 6.1 Create API key input field

- [ ] Create `lib/features/ai/presentation/widgets/api_key_input.dart`
- [ ] Secure text field (obscured by default)
- [ ] Toggle visibility button
- [ ] Validate key format (starts with sk-)
- [ ] Show validation progress
- [ ] Write widget tests

### 6.2 Add key instructions

- [ ] Add link to OpenRouter key creation page
- [ ] Add inline instructions for getting a key
- [ ] Handle paste from clipboard

---

## Task Group 7: Model Selector Widget

### 7.1 Create model picker

- [ ] Create `lib/features/ai/presentation/widgets/model_selector.dart`
- [ ] Dropdown with recommended models
- [ ] Show model name, provider, cost indicator
- [ ] Indicate current selection
- [ ] Write widget tests

### 7.2 Add model details

- [ ] Show cost per request estimate
- [ ] Show context length
- [ ] Show provider logo/icon
- [ ] Add "More models" option for power users

---

## Task Group 8: Provider Integration

### 8.1 Create Riverpod providers

- [ ] Create `cloudAiServiceProvider`
- [ ] Create `cloudAiConfigProvider` (persisted)
- [ ] Create `availableModelsProvider`
- [ ] Create `usageStatsProvider`

### 8.2 Update AiServiceFactory

- [ ] Add case for AiMode.cloud
- [ ] Return CloudAiService instance
- [ ] Inject HttpClient and CredentialVault

---

## Task Group 9: Testing

### 9.1 Unit tests

- [ ] CloudModel entity tests
- [ ] CloudAiConfig entity tests
- [ ] UsageStats entity tests
- [ ] CloudAiService tests (mocked HTTP)
- [ ] Error handling tests

### 9.2 Integration tests

- [ ] API key validation with real OpenRouter (skip in CI)
- [ ] Command generation end-to-end
- [ ] Streaming generation
- [ ] Rate limit handling

### 9.3 Widget tests

- [ ] ApiKeyInput widget
- [ ] ModelSelector widget
- [ ] UsageStats widget

---

## Task Group 10: Documentation

### 10.1 Code documentation

- [ ] Add dartdoc to all public APIs
- [ ] Document OpenRouter requirements
- [ ] Document error conditions

### 10.2 User documentation

- [ ] Document how to get OpenRouter API key
- [ ] Document model selection guidance
- [ ] Document privacy implications
- [ ] Add FAQ section

---

## Completion Criteria

- [ ] All unit tests pass
- [ ] Integration tests pass (can skip real API calls in CI)
- [ ] CloudAiService passes AiService contract tests
- [ ] API key stored securely in credential vault
- [ ] Consent flow blocks requests until acknowledged
- [ ] Streaming displays tokens in real-time
- [ ] Error states handled gracefully with user feedback
- [ ] Usage tracking shows accurate cost estimates
