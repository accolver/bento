# AI Setup Flow - Implementation Tasks

## 1. Domain Entities

- [ ] 1.1 Create AiMode enum (unconfigured, local, cloud, remote)
- [ ] 1.2 Create CloudAiProvider enum with OpenRouter model IDs
- [ ] 1.3 Create LocalAiModel freezed entity with HuggingFace URLs
- [ ] 1.4 Create AiConfig freezed entity with all configuration fields
- [ ] 1.5 Define availableLocalModels constant list

## 2. Database Schema

- [ ] 2.1 Add ai_config table to Drift schema
- [ ] 2.2 Generate Drift code with build_runner
- [ ] 2.3 Add migration for new table

## 3. Data Layer

- [ ] 3.1 Create AiConfigRepository with load/save/clear methods
- [ ] 3.2 Implement secure storage for API keys (reuse credential vault pattern)
- [ ] 3.3 Create ModelDownloadService with Dio
- [ ] 3.4 Implement download with progress stream
- [ ] 3.5 Implement download cancellation and cleanup
- [ ] 3.6 Add HuggingFace URL builder utility

## 4. Providers

- [ ] 4.1 Create aiConfigProvider (AsyncNotifier)
- [ ] 4.2 Create aiSetupStepProvider for wizard state
- [ ] 4.3 Create modelDownloadProgressProvider
- [ ] 4.4 Create apiKeyValidationProvider

## 5. Wizard UI - Structure

- [ ] 5.1 Create AiSetupWizard shell with step navigation
- [ ] 5.2 Implement back/forward navigation logic
- [ ] 5.3 Add swipe-to-dismiss with confirmation for in-progress steps
- [ ] 5.4 Create shared step layout component

## 6. Wizard UI - Steps

- [ ] 6.1 Create ModeSelectionStep with three option cards
- [ ] 6.2 Create LocalModelSelectStep with model cards
- [ ] 6.3 Create LocalDownloadStep with progress indicator
- [ ] 6.4 Create CloudProviderStep with provider cards
- [ ] 6.5 Create CloudApiKeyStep with secure text field
- [ ] 6.6 Create RemoteDetectStep with toggle and explanation
- [ ] 6.7 Create CompleteStep with success animation

## 7. Wizard UI - Components

- [ ] 7.1 Create ModelCard widget (name, size, stars, recommended badge)
- [ ] 7.2 Create ProviderCard widget (name, description, icon)
- [ ] 7.3 Create SecureTextField with show/hide toggle
- [ ] 7.4 Create DownloadProgressIndicator component

## 8. FAB Integration

- [ ] 8.1 Modify AiFab/panel to check configuration status
- [ ] 8.2 Show wizard on FAB tap if unconfigured
- [ ] 8.3 Show normal panel if configured

## 9. Settings Integration

- [ ] 9.1 Create AiSettingsScreen for post-setup modification
- [ ] 9.2 Add AI Settings entry to main settings screen
- [ ] 9.3 Implement "Change AI Mode" flow
- [ ] 9.4 Implement "Delete Downloaded Model" action
- [ ] 9.5 Implement "Clear API Key" action

## 10. API Key Validation

- [ ] 10.1 Implement OpenRouter key validation API call
- [ ] 10.2 Show loading state during validation
- [ ] 10.3 Show success/error feedback
- [ ] 10.4 Handle network errors gracefully

## 11. Testing

- [ ] 11.1 Unit tests for AiConfigRepository
- [ ] 11.2 Unit tests for ModelDownloadService (mocked)
- [ ] 11.3 Widget tests for each wizard step
- [ ] 11.4 Integration test for complete setup flow

## 12. Accessibility

- [ ] 12.1 Add semantic labels to all interactive elements
- [ ] 12.2 Ensure keyboard navigation works
- [ ] 12.3 Test with screen reader
- [ ] 12.4 Ensure sufficient color contrast
