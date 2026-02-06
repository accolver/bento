# Spec: AI Setup Wizard

**ID**: `L2:contract:lib/features/ai/presentation/screens:ai_setup_wizard`
**Type**: Screen/Flow **Parent**: `L3:experience:ai-onboarding`

## Purpose

Guide users through AI configuration on first use, presenting clear options for
local, cloud, or remote AI with appropriate setup steps for each path.

## Interface

```dart
/// Entry point for AI setup flow.
/// Shows as a full-screen modal or pushed route.
class AiSetupWizard extends ConsumerStatefulWidget {
  /// Called when setup completes successfully.
  final VoidCallback? onComplete;
  
  /// Called when user skips setup.
  final VoidCallback? onSkip;
}

/// Wizard steps
enum AiSetupStep {
  modeSelection,     // Choose local/cloud/remote/skip
  localModelSelect,  // Choose which model to download
  localDownload,     // Download progress
  cloudProvider,     // Choose OpenRouter model
  cloudApiKey,       // Enter API key
  remoteDetect,      // Auto-detect Ollama
  complete,          // Success confirmation
}
```

## Behavior

### Step: Mode Selection

**Display**:

- Title: "Set up AI Assistant"
- Subtitle: "Bento can help you write commands using AI"
- Three main options as cards:
  1. Local AI (Private) - icon: shield/lock
  2. Cloud AI (Powerful) - icon: cloud
  3. Remote AI (On your server) - icon: server/desktop
- "Skip for now" link at bottom

**Actions**:

- Tap Local → navigate to localModelSelect
- Tap Cloud → navigate to cloudProvider
- Tap Remote → navigate to remoteDetect
- Tap Skip → call onSkip, close wizard

### Step: Local Model Select

**Display**:

- Back button to return to mode selection
- Title: "Choose a Model"
- Subtitle: "Select based on your device capabilities"
- Model cards with:
  - Name and size badge (e.g., "600 MB")
  - Description of best use case
  - Quality stars (1-5)
  - "Recommended" badge on Phi-3 Mini

**Models** (from flutter_llama recommendations):

1. TinyLlama (600 MB) - "Fastest, works on any device" - 3 stars
2. Phi-3 Mini (2.0 GB) - "Best balance" - 5 stars - RECOMMENDED
3. Gemma 2B (1.2 GB) - "Good for multiple languages" - 4 stars
4. Braindler (88 MB) - "Ultra-compact" - 3 stars

**Actions**:

- Tap model → navigate to localDownload with selected model

### Step: Local Download

**Display**:

- Title: "Downloading {modelName}"
- Circular or linear progress indicator
- Progress text: "1.34 GB / 2.0 GB"
- Time remaining estimate
- Cancel button

**Behavior**:

- Download from HuggingFace URL
- Store in app documents directory
- On complete → navigate to complete
- On cancel → return to localModelSelect
- On error → show retry option

### Step: Cloud Provider

**Display**:

- Back button
- Title: "Choose AI Provider"
- Subtitle: "All providers use OpenRouter for unified access"
- Provider cards:
  1. Claude (Anthropic) - "Best reasoning" - RECOMMENDED
  2. GPT-4o-mini (OpenAI) - "Fast and affordable"
  3. Llama 3 (Meta) - "Open source, free tier"
  4. Gemini (Google) - "Good all-rounder"

**Actions**:

- Tap provider → navigate to cloudApiKey with selected provider/model

### Step: Cloud API Key

**Display**:

- Back button
- Title: "Enter Your API Key"
- Subtitle: "Get a key from openrouter.ai"
- Text field with:
  - Placeholder: "sk-or-v1-..."
  - Obscured text with show/hide toggle
  - Paste button
- Privacy notice: "Your API key is stored securely on this device only."
- Link: "Get an API key →" (opens openrouter.ai)
- "Test Connection" button (secondary)
- "Save" button (primary, disabled until key entered)

**Behavior**:

- Test Connection: validate key with OpenRouter API
- Show success/error feedback
- Save: store in flutter_secure_storage, navigate to complete

### Step: Remote Detect

**Display**:

- Back button
- Title: "Remote AI Detection"
- Explanation: "Bento can use Ollama running on servers you connect to via SSH"
- Toggle: "Auto-detect Ollama on SSH connections" (default: on)
- Info card explaining:
  - "When you connect to a server, Bento will check if Ollama is running"
  - "Your prompts stay on that server - nothing sent to external services"
- "Done" button

**Behavior**:

- Save preference to config
- Navigate to complete

### Step: Complete

**Display**:

- Success icon/animation
- Title: "AI is Ready!"
- Summary of configuration
- "Start Using AI" button

**Actions**:

- Tap button → call onComplete, close wizard

## Scenarios

### Scenario: First FAB Tap - Unconfigured

```gherkin
Given AI has not been configured
When user taps the AI FAB
Then the AI Setup Wizard is shown
And mode selection step is displayed
```

### Scenario: Complete Local Setup

```gherkin
Given user is on mode selection
When user selects "Local AI"
And user selects "Phi-3 Mini" model
And download completes successfully
Then AI configuration is saved with mode "local"
And selected model path is stored
And wizard completes
```

### Scenario: Complete Cloud Setup

```gherkin
Given user is on mode selection
When user selects "Cloud AI"
And user selects "Claude" provider
And user enters valid API key
And user taps "Save"
Then API key is stored in secure storage
And AI configuration is saved with mode "cloud"
And wizard completes
```

### Scenario: Skip Setup

```gherkin
Given user is on mode selection
When user taps "Skip for now"
Then wizard closes
And AI FAB remains visible
And next FAB tap shows wizard again
```

### Scenario: Download Cancellation

```gherkin
Given user is downloading a model
When user taps "Cancel"
Then download is aborted
And partial file is deleted
And user returns to model selection
```

### Scenario: Invalid API Key

```gherkin
Given user has entered an API key
When user taps "Test Connection"
And the API key is invalid
Then error message is shown
And user can correct the key
```
