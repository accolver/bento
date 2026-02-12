# Design: Remote AI (Ollama + Cloud Providers via SSH)

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    SSH Connection                            │
│              (user connects to server)                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              RemoteAiDetector (unified)                      │
│     Orchestrates detection of all remote AI capabilities     │
├─────────────────────────────────────────────────────────────┤
│  1. OllamaDetector: curl localhost:11434/api/tags           │
│  2. EnvProviderDetector: test -n "$ANTHROPIC_API_KEY" ...   │
│  3. Combines → RemoteAiDetectionResult                      │
│  4. Emits → RemoteAiDetectedEvent                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Detection Notification                          │
│   "AI providers detected on remote host" (non-intrusive)     │
│   User taps → Provider selection UI                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              RemoteAiService (implements AiService)           │
│   Routes to correct backend based on selected provider       │
├─────────────────────────────────────────────────────────────┤
│  Mode A: OllamaBackend                                       │
│    - curl localhost:11434/v1/chat/completions                │
│    - OpenAI-compatible format                                │
│    - Model selection from server's installed models          │
│                                                              │
│  Mode B: CloudProxyBackend                                   │
│    - curl https://api.anthropic.com/... with $API_KEY        │
│    - Provider-specific request formatting                    │
│    - Key expanded by remote shell, never seen by Bento       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│               SSH Session (exec channel)                     │
│                                                              │
│  curl -s <endpoint> \                                        │
│    -H "Authorization: Bearer $API_KEY" \                     │
│    -H "Content-Type: application/json" \                     │
│    -d '{"model": "...", "messages": [...]}'                  │
└─────────────────────────────────────────────────────────────┘
```

## File Structure

```
lib/features/ai/
├── domain/
│   └── entities/
│       ├── ollama_model.dart              # Ollama model metadata
│       ├── remote_ai_provider.dart        # Provider registry + metadata
│       ├── remote_ai_detection.dart       # Unified detection result
│       └── remote_ai_config.dart          # Per-host remote AI config
├── data/
│   └── services/
│       ├── remote_ai_service.dart         # AiService impl (routes to backend)
│       ├── ollama_backend.dart            # Ollama-specific curl logic
│       ├── cloud_proxy_backend.dart       # Cloud provider curl logic
│       ├── ollama_detector.dart           # Probes for Ollama
│       ├── env_provider_detector.dart     # Probes for env var API keys
│       └── remote_ai_detector.dart        # Orchestrates both detectors
└── presentation/
    ├── widgets/
    │   ├── remote_provider_selector.dart  # Provider picker (Ollama + cloud)
    │   ├── remote_model_selector.dart     # Model picker for Ollama
    │   └── remote_ai_notification.dart    # Detection notification banner
    └── providers/
        └── remote_ai_providers.dart       # Riverpod providers
```

## Communication Flow

### Detection (on SSH connect)

```
┌──────────┐     SshConnectedEvent     ┌────────────────────┐
│  SSH     │ ────────────────────────▶ │ RemoteAiDetector   │
│  Manager │                           └────────────────────┘
└──────────┘                                   │
                                               │ 1. Wait 1s
                                               │ 2. Run parallel
                                               ▼
                               ┌───────────────────────────┐
                               │  Single SSH exec command   │
                               │                           │
                               │  # Ollama probe            │
                               │  curl -s --connect-timeout │
                               │    2 localhost:11434/...   │
                               │                           │
                               │  # Env var probe           │
                               │  test -n "$ANTHROPIC_API_  │
                               │    KEY" && echo ANTHROPIC  │
                               │  test -n "$OPENAI_API_KEY" │
                               │    && echo OPENAI          │
                               │  ... (all known vars)      │
                               └───────────────────────────┘
                                               │
                                               ▼
                               ┌───────────────────────────┐
                               │  RemoteAiDetectionResult   │
                               │  - ollamaModels: [...]     │
                               │  - cloudProviders: [       │
                               │      anthropic, openai     │
                               │    ]                       │
                               └───────────────────────────┘
                                               │
                                               ▼
┌──────────┐     Show notification      ┌────────────────────┐
│  User    │ ◀──────────────────────── │ RemoteAiNotification│
│          │                           │ "3 AI providers      │
│          │     Tap to configure       │  found on remote"   │
│          │ ────────────────────────▶ └────────────────────┘
└──────────┘                                   │
                                               ▼
                               ┌───────────────────────────┐
                               │  RemoteProviderSelector    │
                               │  ┌─────────────────────┐  │
                               │  │ ★ Claude (Anthropic) │  │
                               │  │   Best for commands  │  │
                               │  ├─────────────────────┤  │
                               │  │   GPT-4o (OpenAI)   │  │
                               │  ├─────────────────────┤  │
                               │  │   Ollama (llama3:8b) │  │
                               │  │   Local, no API cost │  │
                               │  └─────────────────────┘  │
                               └───────────────────────────┘
```

### Command Generation (cloud proxy path)

```
┌──────────┐     generateCommand()     ┌──────────────────┐
│  AI FAB  │ ────────────────────────▶ │ RemoteAiService  │
│  Panel   │                           └──────────────────┘
└──────────┘                                   │
                                               │ Select backend
                                               ▼
                               ┌───────────────────────────┐
                               │   CloudProxyBackend        │
                               │   - Builds provider-       │
                               │     specific curl command  │
                               │   - Uses $ENV_VAR for key  │
                               │   - Formats request body   │
                               └───────────────────────────┘
                                               │
                                               ▼
┌──────────┐     sshSession.execute()   ┌──────────────────┐
│  SSH     │ ◀──────────────────────── │ CloudProxyBackend │
│  Session │                           └──────────────────┘
└──────────┘
      │  curl -s https://api.anthropic.com/v1/messages \
      │    -H "x-api-key: $ANTHROPIC_API_KEY" \
      │    -H "anthropic-version: 2023-06-01" \
      │    -d '{"model":"claude-sonnet-4-20250514",...}'
      │
      │ stdout: JSON response
      ▼
┌──────────────────┐     AiSuggestion        ┌──────────┐
│ CloudProxyBackend│ ──────────────────────▶ │  AI FAB  │
└──────────────────┘                         │  Panel   │
                                             └──────────┘
```

## Provider Registry

Central registry of known AI providers with their API formats:

```dart
/// Known AI providers detectable via environment variables
enum RemoteCloudProvider {
  anthropic,
  openai,
  groq,
  google,
  mistral,
  openRouter,
  xai,
  deepseek,
  fireworks,
  togetherAi,
  cohere,
}
```

Each provider has:

```dart
class RemoteProviderConfig {
  final RemoteCloudProvider provider;
  final String envVar;           // e.g., 'ANTHROPIC_API_KEY'
  final String apiBaseUrl;       // e.g., 'https://api.anthropic.com'
  final String defaultModel;     // e.g., 'claude-sonnet-4-20250514'
  final ApiFormat apiFormat;     // openai | anthropic
  final String authHeaderName;   // e.g., 'x-api-key' or 'Authorization'
  final String authHeaderFormat; // e.g., 'Bearer $KEY' or '$KEY'
  final int qualityRank;         // 1 = best, used for auto-recommendation
  final Map<String, String> extraHeaders; // e.g., {'anthropic-version': '2023-06-01'}
}
```

### API Format Abstraction

Most providers use OpenAI-compatible chat completion format. Anthropic is the
main exception. We abstract this into two formats:

```dart
enum ApiFormat {
  /// OpenAI chat completion format
  /// POST /v1/chat/completions
  /// { "model": "...", "messages": [...], "stream": bool }
  openaiCompatible,

  /// Anthropic Messages API format
  /// POST /v1/messages
  /// { "model": "...", "messages": [...], "max_tokens": int }
  anthropicMessages,
}
```

### Provider-Specific Curl Templates

```dart
// OpenAI-compatible (OpenAI, Groq, Mistral, xAI, Deepseek, etc.)
String buildOpenAiCurl(String prompt, RemoteProviderConfig config) => '''
curl -s ${config.apiBaseUrl}/chat/completions \\
  -H "Authorization: Bearer \$${config.envVar}" \\
  -H "Content-Type: application/json" \\
  -d '$escapedBody'
''';

// Anthropic format
String buildAnthropicCurl(String prompt, RemoteProviderConfig config) => '''
curl -s ${config.apiBaseUrl}/v1/messages \\
  -H "x-api-key: \$${config.envVar}" \\
  -H "anthropic-version: 2023-06-01" \\
  -H "Content-Type: application/json" \\
  -d '$escapedBody'
''';
```

## Environment Variable Detection

### Detection Command

All env var checks are batched into a single SSH exec to minimize round trips:

```bash
# Single command that checks all known vars
# Uses test -n to check existence without printing the value
(test -n "$ANTHROPIC_API_KEY" && echo "ANTHROPIC_API_KEY") 2>/dev/null
(test -n "$OPENAI_API_KEY" && echo "OPENAI_API_KEY") 2>/dev/null
(test -n "$GROQ_API_KEY" && echo "GROQ_API_KEY") 2>/dev/null
(test -n "$GOOGLE_API_KEY" && echo "GOOGLE_API_KEY") 2>/dev/null
(test -n "$GEMINI_API_KEY" && echo "GEMINI_API_KEY") 2>/dev/null
(test -n "$MISTRAL_API_KEY" && echo "MISTRAL_API_KEY") 2>/dev/null
(test -n "$OPENROUTER_API_KEY" && echo "OPENROUTER_API_KEY") 2>/dev/null
(test -n "$XAI_API_KEY" && echo "XAI_API_KEY") 2>/dev/null
(test -n "$DEEPSEEK_API_KEY" && echo "DEEPSEEK_API_KEY") 2>/dev/null
(test -n "$FIREWORKS_API_KEY" && echo "FIREWORKS_API_KEY") 2>/dev/null
(test -n "$TOGETHER_API_KEY" && echo "TOGETHER_API_KEY") 2>/dev/null
(test -n "$COHERE_API_KEY" && echo "COHERE_API_KEY") 2>/dev/null
(test -n "$CLAUDE_CODE_OAUTH_TOKEN" && echo "CLAUDE_CODE_OAUTH_TOKEN") 2>/dev/null
echo "---ENV_CHECK_DONE---"
```

Output is a newline-separated list of variable names that exist. Parse to
determine available providers.

### Shell Compatibility

The detection command must work across common shells:

- bash, zsh, sh, dash, fish (via `test` which is POSIX)
- Handles non-interactive login shells where env vars may be set in `.bashrc`,
  `.zshrc`, `.profile`, or `.env`
- `2>/dev/null` suppresses any error output
- Sentinel `---ENV_CHECK_DONE---` confirms command completed

### Important: Login Shell Env Vars

Some env vars are only set in login shells. The SSH exec may not load
`.bashrc`/`.zshrc`. We handle this by:

1. First trying the direct `test -n` approach
2. If no vars found, try `bash -l -c '...'` to invoke a login shell
3. Cache the shell invocation strategy per host

## Ollama API Reference

(Unchanged from original design — see Ollama detection section)

### List Models

```bash
curl -s localhost:11434/api/tags
```

### Chat Completion (OpenAI-compatible)

```bash
curl -s localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "llama3:8b", "messages": [...], "stream": false}'
```

## Streaming Implementation

### Ollama Streaming

Same as original design — pipe `curl -sN` output through SSH channel and parse
SSE format.

### Cloud Provider Streaming

Cloud providers also support SSE streaming via the OpenAI-compatible format:

```bash
# Streaming via SSH proxy
curl -sN https://api.groq.com/openai/v1/chat/completions \
  -H "Authorization: Bearer $GROQ_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "llama-3.3-70b", "messages": [...], "stream": true}'
```

For Anthropic streaming (different SSE format):

```bash
curl -sN https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d '{"model": "claude-sonnet-4-20250514", "messages": [...], "stream": true}'
```

Both formats yield `data: {...}` lines that we parse incrementally.

## Connection Lifecycle

```dart
class RemoteAiService {
  bool _connected = true;
  RemoteBackend _backend; // OllamaBackend or CloudProxyBackend

  void onDisconnected() {
    _connected = false;
    _controller.add(RemoteAiStatusEvent.disconnected);
  }

  void onReconnected(SshSession newSession) {
    _sshSession = newSession;
    _connected = true;
    // Re-detect — models or env vars may have changed
    _redetect();
  }

  @override
  Future<bool> isAvailable() async {
    return _connected && _backend.isConfigured;
  }
}
```

## Decisions

### D1: SSH Exec vs Port Forward

**Decision**: Use SSH exec with curl (not port forwarding)

**Rationale**:

- Simpler implementation (no local port management)
- Works for both Ollama (local) and cloud providers (outbound)
- Works through jumpboxes
- No firewall issues with local port binding

### D2: Silent Detection, Opt-in Usage

**Decision**: Detect silently, show notification, let user choose

**Rationale**:

- Probing for env vars is lightweight (single `test` command)
- Users shouldn't be surprised by AI switching modes
- Non-intrusive notification respects user attention
- "One tap to enable" is still very low friction

### D3: Per-Host Provider Memory

**Decision**: Remember provider selection per SSH host

**Rationale**:

- Different machines have different providers configured
- User might prefer Claude on their dev machine but Groq on CI servers
- Selection stored with hostId as key in SharedPreferences

### D4: Key-Opaque Architecture

**Decision**: Never read API key values, only check existence

**Rationale**:

- Maximum security — keys never transit the SSH channel as values
- `test -n "$VAR"` only checks if non-empty
- `curl` uses shell expansion `$VAR` so the key never appears in Bento
- No need to store remote API keys on device

### D5: Curated Provider List

**Decision**: Only check a fixed list of known provider env vars

**Rationale**:

- No `env | grep` — avoids reading arbitrary env vars
- Users can predict exactly what Bento checks for
- New providers added via app updates
- Avoids false positives from unrelated `_API_KEY` vars

### D6: Provider API Format

**Decision**: Two API format abstractions (OpenAI-compatible and Anthropic)

**Rationale**:

- Most providers (OpenAI, Groq, Mistral, xAI, Deepseek, Fireworks, Together,
  OpenRouter) all use the OpenAI chat completion format
- Only Anthropic uses a unique format (Messages API)
- Google Gemini has its own format but also supports an OpenAI-compatible
  endpoint via their newer API
- Two formats cover all providers with minimal abstraction

### D7: Parallel Detection

**Decision**: Run Ollama probe and env var check in parallel

**Rationale**:

- Both are independent SSH exec commands
- Combined adds ~0 latency vs sequential ~3s extra
- Can be batched into a single exec if needed (Ollama check + env check in one
  shell script)

## Error Handling

| Error                         | Recovery                                     |
| ----------------------------- | -------------------------------------------- |
| curl not found on server      | Inform user, suggest installing curl         |
| Ollama not responding         | Mark unavailable, only show cloud providers  |
| SSH disconnected              | Mark all unavailable, re-detect on reconnect |
| Env var check fails           | Silent — treat as no providers detected      |
| API call via proxy fails      | Show error from remote curl, suggest retry   |
| Model not found (Ollama)      | Fall back to first available model           |
| Rate limited (cloud provider) | Show rate limit message, suggest waiting     |
| Login shell needed            | Retry with `bash -l -c` wrapper              |
| Generation timeout            | Cancel and return timeout error              |
