# Proposal: AI Setup Flow

## Why

Users need a clear, guided way to configure AI assistance when they first use
Bento's AI features. The setup must present options transparently (local vs
cloud vs remote), explain tradeoffs, and collect necessary configuration (API
keys, model downloads) without overwhelming the user. A well-designed onboarding
reduces friction and increases AI feature adoption.

## What Changes

- Add first-use detection that triggers AI setup wizard on first FAB tap
- Create multi-step setup wizard with three main paths:
  - Local AI: Model selection and download with progress
  - Cloud AI (OpenRouter): Provider/model selection and API key entry
  - Remote AI: Auto-detection of Ollama on SSH connections
- Implement AI Settings screen accessible from app settings
- Store AI configuration securely (API keys in flutter_secure_storage)
- Add "Skip for now" option that falls back to keyword matching
- Show privacy indicators throughout setup explaining data handling

## Capabilities

### New Capabilities

- `ai-setup-wizard`: Multi-step onboarding flow for AI configuration
- `ai-settings-screen`: Settings page for changing AI configuration
- `model-download-manager`: Download GGUF models with progress tracking
- `api-key-manager`: Secure storage and validation of API keys
- `ai-config-provider`: Riverpod provider for AI configuration state

### Modified Capabilities

- `ai-fab`: Check configuration status, trigger setup if unconfigured
- `settings-screen`: Add AI Settings entry point

## Impact

- **Dependencies**: Requires ai-service-abstraction for provider interface
- **Storage**: New database table for AI config, secure storage for API keys
- **UX**: New wizard flow, settings integration
- **Privacy**: Must clearly communicate data handling for each option

## Phase

**Phase 2 - Intelligence** (Months 5-7)

## Priority

**P0 - Must Have** - Required before real AI can be used
