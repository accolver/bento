# Design: AI Setup Flow

## Technical Decisions

### TD-1: Wizard as Modal vs Route

**Decision**: Use full-screen modal bottom sheet

**Rationale**:

- Maintains context of where user came from
- Can be dismissed by swiping (with confirmation if in-progress)
- Works well on mobile form factors
- Consistent with iOS/Android patterns for setup flows

### TD-2: Configuration Storage

**Decision**: Split storage between database and secure storage

**Rationale**:

- Non-sensitive config (mode, model ID, flags) → SQLite database
- Sensitive data (API keys) → flutter_secure_storage
- Already have secure storage infrastructure for credentials
- Allows querying config without security overhead

**Schema**:

```sql
CREATE TABLE ai_config (
  id INTEGER PRIMARY KEY DEFAULT 1, -- singleton
  mode TEXT NOT NULL DEFAULT 'unconfigured',
  local_model_id TEXT,
  local_model_path TEXT,
  cloud_provider TEXT,
  remote_auto_detect INTEGER DEFAULT 1,
  show_privacy_indicator INTEGER DEFAULT 1,
  configured_at TEXT,
  last_used_at TEXT
);
```

### TD-3: Model Download Strategy

**Decision**: Stream download with resume capability

**Rationale**:

- Models are large (88MB - 2GB)
- Users may have spotty connections
- Resume prevents wasted bandwidth
- Use Dio with download progress callbacks

**Implementation**:

```dart
final dio = Dio();
await dio.download(
  getHuggingFaceUrl(repo: model.huggingFaceRepo, file: model.huggingFaceFile),
  localPath,
  onReceiveProgress: (received, total) {
    final progress = received / total;
    progressNotifier.value = progress;
  },
  deleteOnError: false, // Enable resume
);
```

### TD-4: API Key Validation

**Decision**: Validate with lightweight OpenRouter API call

**Rationale**:

- Don't want to waste tokens on validation
- OpenRouter has `/api/v1/auth/key` endpoint for key info
- Returns key metadata without making a completion request

### TD-5: First-Use Detection

**Decision**: Check config on FAB tap, not app launch

**Rationale**:

- Don't interrupt users who don't want AI
- Lazy initialization pattern
- FAB tap is natural entry point for AI features

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
├─────────────────────────────────────────────────────────────┤
│  AiSetupWizard ─┬─► ModeSelectionStep                       │
│                 ├─► LocalModelSelectStep                    │
│                 ├─► LocalDownloadStep                       │
│                 ├─► CloudProviderStep                       │
│                 ├─► CloudApiKeyStep                         │
│                 ├─► RemoteDetectStep                        │
│                 └─► CompleteStep                            │
│                                                             │
│  AiSettingsScreen (for later modification)                  │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Provider Layer                            │
├─────────────────────────────────────────────────────────────┤
│  aiConfigProvider         - Current AI configuration        │
│  aiSetupStepProvider      - Current wizard step             │
│  modelDownloadProvider    - Download progress state         │
│  apiKeyValidationProvider - Key validation state            │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Data Layer                                │
├─────────────────────────────────────────────────────────────┤
│  AiConfigRepository                                         │
│  - loadConfig()                                             │
│  - saveConfig(AiConfig)                                     │
│  - saveApiKey(String key)                                   │
│  - getApiKey() → String?                                    │
│  - clearConfig()                                            │
│                                                             │
│  ModelDownloadService                                       │
│  - downloadModel(LocalAiModel) → Stream<double>            │
│  - cancelDownload()                                         │
│  - deleteModel(String modelId)                              │
│  - getModelPath(String modelId) → String?                   │
└─────────────────────────────────────────────────────────────┘
```

## File Structure

```
lib/features/ai/
├── domain/
│   └── entities/
│       ├── ai_config.dart          # AiConfig, AiMode, etc.
│       └── local_ai_model.dart     # LocalAiModel + available models
├── data/
│   ├── repositories/
│   │   └── ai_config_repository.dart
│   └── services/
│       └── model_download_service.dart
└── presentation/
    ├── providers/
    │   ├── ai_config_provider.dart
    │   └── model_download_provider.dart
    ├── screens/
    │   ├── ai_setup_wizard.dart
    │   └── ai_settings_screen.dart
    └── widgets/
        ├── setup_steps/
        │   ├── mode_selection_step.dart
        │   ├── local_model_select_step.dart
        │   ├── local_download_step.dart
        │   ├── cloud_provider_step.dart
        │   ├── cloud_api_key_step.dart
        │   ├── remote_detect_step.dart
        │   └── complete_step.dart
        ├── model_card.dart
        └── provider_card.dart
```

## Dependencies

- **flutter_secure_storage**: Already in project, for API keys
- **dio**: For model downloads with progress (add to pubspec)
- **drift**: Already in project, for config persistence
