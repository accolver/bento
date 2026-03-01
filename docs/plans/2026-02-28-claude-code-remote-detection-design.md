# Claude Code Remote AI Detection

**Date**: 2026-02-28 **Status**: Approved **Approach**: A (New provider in
existing registry)

## Summary

Add Claude Code as a detectable remote AI provider. When a user SSHs into a
remote host that has Claude Code installed, Bento detects it and uses its OAuth
credentials to make Anthropic API calls -- without ever reading the token values
on the mobile device (key-opaque architecture).

## Context

Bento's Remote AI Detection (`RemoteAiDetector`) currently runs two detectors in
parallel:

- `OllamaDetector` -- probes `localhost:11434/api/tags` for Ollama
- `EnvProviderDetector` -- checks env vars for 11 cloud providers (Anthropic,
  OpenAI, etc.)

Claude Code authenticates differently from a raw `ANTHROPIC_API_KEY`. It uses
OAuth tokens stored in `~/.claude/.credentials` on the remote host, with
`Authorization: Bearer` headers instead of `x-api-key`. A user could have Claude
Code installed with a Max subscription but no `ANTHROPIC_API_KEY` set.

## Design

### 1. Detection (`ClaudeCodeDetector`)

New detector class following the same SSH exec pattern as `EnvProviderDetector`.

**Detection command** (via SSH):

```bash
test -d ~/.claude && test -f ~/.claude/.credentials && echo "CLAUDE_CODE_FOUND"
```

**Optional version probe**:

```bash
claude --version 2>/dev/null || echo "unknown"
```

Uses the multi-shell fallback chain (direct -> bash -l -> zsh -l -> bash -li ->
zsh -li) to handle different shell configurations.

### 2. Provider Registration

Add `claudeCode` to `RemoteCloudProvider` enum and `RemoteProviderRegistry`:

| Field         | Value                                     |
| ------------- | ----------------------------------------- |
| Provider      | `RemoteCloudProvider.claudeCode`          |
| Display name  | "Claude Code"                             |
| Env vars      | `[]` (file-based detection, not env vars) |
| API base URL  | `https://api.anthropic.com`               |
| API format    | `ApiFormat.anthropicMessages`             |
| Default model | `claude-sonnet-4-5-20250514`              |
| Auth header   | `Authorization`                           |
| Auth format   | `Bearer $KEY`                             |
| Quality rank  | `0` (highest, above Anthropic's rank 1)   |

### 3. Token Extraction (Key-Opaque)

Token is extracted entirely on the remote host via shell expansion. Bento never
sees the value.

**Primary method** (python3):

```bash
$(python3 -c "import json; print(json.load(open('$HOME/.claude/.credentials'))['claudeApiKey'])" 2>/dev/null)
```

**Fallback** (grep/cut, no python3):

```bash
$(cat ~/.claude/.credentials | grep -o '"claudeApiKey":"[^"]*"' | cut -d'"' -f4)
```

The exact JSON field name (`claudeApiKey`, `oauthToken`, `accessToken`) will be
confirmed during implementation and made configurable.

### 4. Token Refresh (Full Lifecycle)

On 401 response:

1. Run `claude --print-access-token 2>/dev/null` on remote via SSH exec
2. If that fails, surface error: "Claude Code session expired on [host]. SSH in
   and run `claude` to re-authenticate."
3. Retry original request after successful refresh

All refresh happens on the remote machine -- key-opaque is maintained.

### 5. Integration into `RemoteAiDetector`

```dart
Future<RemoteAiDetectionResult> detect(SshClient client) async {
  final results = await Future.wait([
    _ollamaDetector.detect(client),
    _envProviderDetector.detect(client),
    _claudeCodeDetector.detect(client),  // NEW
  ]);
  // Merge results; Claude Code gets rank 0 (highest priority)
}
```

`RemoteAiDetectionResult` gains:

- `bool claudeCodeDetected`
- `String? claudeCodeVersion`

### 6. CloudProxyBackend Changes

New code path for Claude Code auth:

- Uses `Authorization: Bearer $(...)` instead of `x-api-key: \$$envVarName`
- Token extraction via shell expansion (section 3 above)
- Same Anthropic Messages API format otherwise

### 7. UI Changes

- **AI Setup Wizard** (`RemoteDetectStep`): Claude Code appears as top option
  with distinct icon when detected
- **RemoteAiStatus** widget: Shows Claude Code indicator
- **RemoteProviderSelector**: Claude Code listed first

## Security

- **Key-opaque maintained**: Token values never leave the remote machine
- **No env var dependency**: Detection is file-based
- **Bearer auth**: OAuth tokens use `Authorization: Bearer` (not `x-api-key`)
- **Refresh on remote**: Token refresh runs entirely on the remote host
- **File permissions**: `~/.claude/.credentials` is typically `600`; SSH user
  must own the file

## Files to Create/Modify

### New Files

- `lib/features/ai/data/services/claude_code_detector.dart`

### Modified Files

- `lib/features/ai/domain/entities/remote_ai_provider.dart` (enum + registry)
- `lib/features/ai/domain/entities/remote_ai_detection.dart` (result model)
- `lib/features/ai/data/services/remote_ai_detector.dart` (orchestrator)
- `lib/features/ai/data/services/cloud_proxy_backend.dart` (Bearer auth path)
- `lib/features/ai/presentation/widgets/setup/remote_detect_step.dart` (UI)
- `lib/features/ai/presentation/widgets/remote_provider_selector.dart` (UI)
- `lib/features/ai/presentation/widgets/remote_ai_status.dart` (UI)

### New Test Files

- `test/features/ai/data/services/claude_code_detector_test.dart`
- Tests added to existing test files for modified code
