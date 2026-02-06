# AI Gateway - Implementation Tasks

## 1. Domain Layer - Interface

- [x] 1.1 Create AiService abstract class with generateCommand method
- [x] 1.2 Add generateCommandStream for streaming support
- [x] 1.3 Add isAvailable, privacyMode, serviceName properties
- [x] 1.4 Add dispose method for resource cleanup
- [x] 1.5 Create AiStreamEvent sealed class hierarchy
- [x] 1.6 Create AiServiceException class

## 2. Domain Layer - Factory

- [x] 2.1 Create AiServiceFactory class
- [x] 2.2 Implement createService with config-based routing
- [x] 2.3 Implement createLocalService, createCloudService, createRemoteService
- [x] 2.4 Implement createMockService wrapper
- [x] 2.5 Add fallback logic for unavailable services

## 3. Update Mock Service

- [x] 3.1 Make MockAiService implement AiService interface
- [x] 3.2 Add generateCommandStream with simulated streaming
- [x] 3.3 Add isAvailable (always true)
- [x] 3.4 Add serviceName ("Mock AI")
- [x] 3.5 Add dispose (no-op)

## 4. Prompt Templates

- [x] 4.1 Create prompt_templates.dart with system/user prompts
- [x] 4.2 Add command generation prompt
- [x] 4.3 Add error healing prompt (for future use)
- [x] 4.4 Add summarization prompt (for future use)

## 5. Providers

- [x] 5.1 Create aiServiceFactoryProvider
- [x] 5.2 Create aiServiceControllerProvider (AsyncNotifier)
- [x] 5.3 Update aiSuggestionControllerProvider to use service provider
- [x] 5.4 Handle service recreation on config change

## 6. Integration

- [x] 6.1 Wire AiGhostwriterPanel to use new provider structure
- [x] 6.2 Update privacy indicator to read from service.privacyMode
- [x] 6.3 Handle loading states during service initialization
- [x] 6.4 Handle error states with retry option

## 7. Testing

- [x] 7.1 Unit tests for AiServiceFactory
- [x] 7.2 Unit tests for MockAiService (interface compliance)
- [x] 7.3 Integration test for config → service creation flow
- [x] 7.4 Widget test for provider integration

## 8. Documentation

- [x] 8.1 Document AiService interface contract
- [x] 8.2 Document prompt template usage
- [x] 8.3 Add implementation guide for new providers
