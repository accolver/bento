# AI Setup Flow - Implementation Tasks

## 1. Domain Entities

- [x] 1.1 Create AiMode enum (unconfigured, local, cloud, remote) - done in
      ai-gateway
- [x] 1.2 Create CloudAiProvider enum with OpenRouter model IDs - done in
      ai-gateway
- [x] 1.3 Create LocalAiModel freezed entity with HuggingFace URLs
- [x] 1.4 Create AiConfig freezed entity with all configuration fields - done in
      ai-gateway
- [x] 1.5 Define availableLocalModels constant list

## 2. Database Schema

- [x] 2.1 Using SharedPreferences instead of Drift for simpler config storage
- [x] 2.2 API keys stored in flutter_secure_storage
- [N/A] 2.3 No migration needed - using SharedPreferences

## 3. Data Layer

- [x] 3.1 Create AiConfigRepository with load/save/clear methods
- [x] 3.2 Implement secure storage for API keys (reuse credential vault pattern)
- [x] 3.3 Create ModelDownloadService with Dio
- [x] 3.4 Implement download with progress stream
- [x] 3.5 Implement download cancellation and cleanup
- [x] 3.6 Add HuggingFace URL builder utility (in LocalAiModel)

## 4. Providers

- [x] 4.1 Create aiConfigProvider (AsyncNotifier) - updated existing
- [x] 4.2 Create aiSetupStepProvider for wizard state - in wizard state
- [x] 4.3 Create modelDownloadProgressProvider - in wizard state
- [ ] 4.4 Create apiKeyValidationProvider - TODO: real validation

## 5. Wizard UI - Structure

- [x] 5.1 Create AiSetupWizard shell with step navigation
- [x] 5.2 Implement back/forward navigation logic
- [x] 5.3 Add swipe-to-dismiss with confirmation for in-progress steps
- [x] 5.4 Create shared step layout component

## 6. Wizard UI - Steps

- [x] 6.1 Create ModeSelectionStep with three option cards
- [x] 6.2 Create LocalModelSelectStep with model cards
- [x] 6.3 Create LocalDownloadStep with progress indicator
- [x] 6.4 Create CloudProviderStep with provider cards
- [x] 6.5 Create CloudApiKeyStep with secure text field
- [x] 6.6 Create RemoteDetectStep with toggle and explanation
- [x] 6.7 Create CompleteStep with success animation

## 7. Wizard UI - Components

- [x] 7.1 Create ModelCard widget (name, size, stars, recommended badge)
- [x] 7.2 Create ProviderCard widget (name, description, icon)
- [x] 7.3 Create SecureTextField with show/hide toggle
- [x] 7.4 Create DownloadProgressIndicator component

## 8. FAB Integration

- [x] 8.1 Modify AiFab/panel to check configuration status
- [x] 8.2 Show wizard on FAB tap if unconfigured
- [x] 8.3 Show normal panel if configured

## 9. Settings Integration

- [ ] 9.1 Create AiSettingsScreen for post-setup modification
- [ ] 9.2 Add AI Settings entry to main settings screen
- [ ] 9.3 Implement "Change AI Mode" flow
- [ ] 9.4 Implement "Delete Downloaded Model" action
- [ ] 9.5 Implement "Clear API Key" action

## 10. API Key Validation

- [x] 10.1 Implement OpenRouter key validation API call (basic format check)
- [x] 10.2 Show loading state during validation
- [x] 10.3 Show success/error feedback
- [x] 10.4 Handle network errors gracefully
- [ ] TODO: Real API validation with OpenRouter /auth/key endpoint

## 11. Testing

- [ ] 11.1 Unit tests for AiConfigRepository
- [ ] 11.2 Unit tests for ModelDownloadService (mocked)
- [ ] 11.3 Widget tests for each wizard step
- [ ] 11.4 Integration test for complete setup flow

## 12. Accessibility

- [x] 12.1 Add semantic labels to all interactive elements
- [x] 12.2 Ensure keyboard navigation works
- [ ] 12.3 Test with screen reader
- [x] 12.4 Ensure sufficient color contrast
