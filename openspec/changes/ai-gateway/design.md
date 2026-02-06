# Design: AI Gateway (Service Abstraction)

## Technical Decisions

### TD-1: Interface vs Abstract Class

**Decision**: Use abstract class with default implementations where sensible

**Rationale**:

- Abstract class allows shared code (e.g., prompt formatting)
- Services can override specific methods
- Dart doesn't have true interfaces, abstract class is idiomatic

### TD-2: Streaming Support

**Decision**: All services must support streaming, even if simulated

**Rationale**:

- UI can always show streaming animation
- Local services naturally stream tokens
- Cloud/remote services stream from API
- Mock service simulates with character-by-character output

### TD-3: Provider Lifecycle

**Decision**: Factory creates services, caller manages lifecycle

**Rationale**:

- Services may hold expensive resources (loaded model, connections)
- Caller (provider) knows when to dispose
- Factory is stateless, easy to test

### TD-4: Error Handling Strategy

**Decision**: Throw AiServiceException, let UI handle gracefully

**Rationale**:

- Consistent exception type across all providers
- UI can show appropriate retry/fallback options
- Original error preserved for debugging

### TD-5: Riverpod Integration

**Decision**: aiServiceProvider as AsyncNotifier that recreates on config change

**Rationale**:

- Service may need async initialization (model loading)
- Automatically recreates when aiConfigProvider changes
- Can expose loading/error states to UI

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
├─────────────────────────────────────────────────────────────┤
│  AiGhostwriterPanel                                         │
│    │                                                        │
│    └─► aiSuggestionControllerProvider                      │
│          │                                                  │
│          └─► aiServiceProvider (provides AiService)         │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Domain Layer                              │
├─────────────────────────────────────────────────────────────┤
│  AiService (abstract)                                       │
│    ├─► LocalAiService                                       │
│    ├─► CloudAiService                                       │
│    ├─► RemoteAiService                                      │
│    └─► MockAiService                                        │
│                                                             │
│  AiServiceFactory                                           │
│    └─► createService(config) → AiService                   │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Data Layer                                │
├─────────────────────────────────────────────────────────────┤
│  flutter_llama (local inference)                            │
│  http/dio (OpenRouter API)                                  │
│  SSH forwarding (remote Ollama)                             │
└─────────────────────────────────────────────────────────────┘
```

## Provider Structure

```dart
/// Provides the current AI service based on configuration.
@riverpod
class AiServiceController extends _$AiServiceController {
  @override
  Future<AiService> build() async {
    final config = await ref.watch(aiConfigProvider.future);
    final factory = ref.watch(aiServiceFactoryProvider);
    final sshConnection = ref.watch(currentSshConnectionProvider);
    
    final service = await factory.createService(
      sshConnection: sshConnection,
    );
    
    // Dispose service when provider is disposed
    ref.onDispose(() => service.dispose());
    
    return service;
  }
}

/// Updated suggestion controller using real AI service.
@riverpod
class AiSuggestionController extends _$AiSuggestionController {
  @override
  Future<AiSuggestion?> build() async => null;

  Future<void> generateFromInput(String input) async {
    if (input.trim().length < 3) {
      state = const AsyncData(null);
      return;
    }

    state = const AsyncLoading();
    
    try {
      final service = await ref.read(aiServiceControllerProvider.future);
      final suggestion = await service.generateCommand(input);
      state = AsyncData(suggestion);
    } on AiServiceException catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}
```

## File Structure

```
lib/features/ai/
├── domain/
│   ├── entities/
│   │   ├── ai_suggestion.dart       # Existing
│   │   ├── ai_privacy_mode.dart     # Existing
│   │   └── ai_config.dart           # From ai-setup-flow
│   └── services/
│       ├── ai_service.dart          # Abstract interface
│       └── ai_service_factory.dart  # Factory implementation
├── data/
│   └── services/
│       ├── local_ai_service.dart    # flutter_llama wrapper
│       ├── cloud_ai_service.dart    # OpenRouter client
│       ├── remote_ai_service.dart   # Ollama via SSH
│       └── mock_ai_service.dart     # Existing, updated
└── presentation/
    └── providers/
        ├── ai_service_provider.dart # New, replaces direct mock usage
        └── ai_providers.dart        # Updated to use service provider
```

## Dependencies

- **flutter_llama**: For local AI (added by local-ai-integration change)
- **dio**: For OpenRouter HTTP calls (may already be in project)
- **Existing SSH infrastructure**: For remote Ollama communication
