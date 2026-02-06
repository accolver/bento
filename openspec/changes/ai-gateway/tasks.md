# AI Gateway - Implementation Tasks

## 1. Domain Layer - Interface

- [ ] 1.1 Create AiService abstract class with generateCommand method
- [ ] 1.2 Add generateCommandStream for streaming support
- [ ] 1.3 Add isAvailable, privacyMode, serviceName properties
- [ ] 1.4 Add dispose method for resource cleanup
- [ ] 1.5 Create AiStreamEvent sealed class hierarchy
- [ ] 1.6 Create AiServiceException class

## 2. Domain Layer - Factory

- [ ] 2.1 Create AiServiceFactory class
- [ ] 2.2 Implement createService with config-based routing
- [ ] 2.3 Implement createLocalService, createCloudService, createRemoteService
- [ ] 2.4 Implement createMockService wrapper
- [ ] 2.5 Add fallback logic for unavailable services

## 3. Update Mock Service

- [ ] 3.1 Make MockAiService implement AiService interface
- [ ] 3.2 Add generateCommandStream with simulated streaming
- [ ] 3.3 Add isAvailable (always true)
- [ ] 3.4 Add serviceName ("Mock AI")
- [ ] 3.5 Add dispose (no-op)

## 4. Prompt Templates

- [ ] 4.1 Create prompt_templates.dart with system/user prompts
- [ ] 4.2 Add command generation prompt
- [ ] 4.3 Add error healing prompt (for future use)
- [ ] 4.4 Add summarization prompt (for future use)

## 5. Providers

- [ ] 5.1 Create aiServiceFactoryProvider
- [ ] 5.2 Create aiServiceControllerProvider (AsyncNotifier)
- [ ] 5.3 Update aiSuggestionControllerProvider to use service provider
- [ ] 5.4 Handle service recreation on config change

## 6. Integration

- [ ] 6.1 Wire AiGhostwriterPanel to use new provider structure
- [ ] 6.2 Update privacy indicator to read from service.privacyMode
- [ ] 6.3 Handle loading states during service initialization
- [ ] 6.4 Handle error states with retry option

## 7. Testing

- [ ] 7.1 Unit tests for AiServiceFactory
- [ ] 7.2 Unit tests for MockAiService (interface compliance)
- [ ] 7.3 Integration test for config → service creation flow
- [ ] 7.4 Widget test for provider integration

## 8. Documentation

- [ ] 8.1 Document AiService interface contract
- [ ] 8.2 Document prompt template usage
- [ ] 8.3 Add implementation guide for new providers
