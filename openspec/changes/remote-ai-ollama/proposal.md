# Proposal: Remote AI (Ollama + Cloud Providers via SSH)

## Why

When users SSH into a machine, that machine often already has AI infrastructure
configured — whether it's Ollama running locally, or environment variables like
`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GROQ_API_KEY` pointing to cloud
providers. Today, Bento ignores all of this and requires users to set up AI
separately on their mobile device.

This is a missed opportunity:

- **Zero-Config AI**: Many developer machines already have AI keys configured
  for tools like Claude Code, Cursor, aider, Copilot CLI, etc.
- **Leverage Existing Infrastructure**: Users pay for API access — Bento should
  let them use it from their phone.
- **Privacy on User's Terms**: Data routes through user's own machine rather
  than Bento managing third-party API calls.
- **Server-Side Inference**: Ollama users get GPU-powered local models without
  cloud costs.

The vision: SSH into a machine, Bento detects what AI is available, and offers
it with one tap. Your existing AI setup, from your phone.

## What Changes

### Ollama Detection (existing scope)

- Detect Ollama running on SSH-connected servers
- Implement RemoteAiService for Ollama's OpenAI-compatible API
- Support model selection from server's installed models
- Execute inference via `curl` over SSH

### Cloud Provider Detection (new scope)

- Detect common AI provider environment variables on SSH hosts
- Support a curated list of providers: Anthropic, OpenAI, Groq, Google Gemini,
  Mistral, OpenRouter, xAI, Deepseek, Fireworks, Together AI, Cohere
- Proxy API calls through SSH — keys never leave the remote machine
- Auto-rank detected providers by model quality
- Allow users to select their preferred provider when multiple are detected

### Unified Detection Framework

- Single detection pass after SSH connection establishes
- Opt-in with notification: "AI providers detected on remote host"
- Per-host provider memory — remember user's preference
- Handle SSH lifecycle: detect on connect, invalidate on disconnect

### Security Model

- **Keys never transit**: Run `test -n "$VAR_NAME"` to check existence, not
  value. API calls execute as `curl` on the remote machine itself.
- **No env dumping**: Only check a curated list of known variable names.
- **User consent**: Never auto-switch AI mode. Show detection results and let
  user choose.

## Technical Details

### Known Provider Environment Variables

| Variable                  | Provider          | API Base URL                                   | Default Model                            |
| ------------------------- | ----------------- | ---------------------------------------------- | ---------------------------------------- |
| `ANTHROPIC_API_KEY`       | Anthropic         | `https://api.anthropic.com`                    | claude-sonnet-4-20250514                 |
| `OPENAI_API_KEY`          | OpenAI            | `https://api.openai.com/v1`                    | gpt-4o                                   |
| `GROQ_API_KEY`            | Groq              | `https://api.groq.com/openai/v1`               | llama-3.3-70b                            |
| `GOOGLE_API_KEY`          | Google            | `https://generativelanguage.googleapis.com/v1` | gemini-2.0-flash                         |
| `GEMINI_API_KEY`          | Google            | (alias for GOOGLE_API_KEY)                     | gemini-2.0-flash                         |
| `MISTRAL_API_KEY`         | Mistral           | `https://api.mistral.ai/v1`                    | mistral-large-latest                     |
| `OPENROUTER_API_KEY`      | OpenRouter        | `https://openrouter.ai/api/v1`                 | anthropic/claude-sonnet-4-20250514       |
| `XAI_API_KEY`             | xAI               | `https://api.x.ai/v1`                          | grok-3                                   |
| `DEEPSEEK_API_KEY`        | DeepSeek          | `https://api.deepseek.com/v1`                  | deepseek-chat                            |
| `FIREWORKS_API_KEY`       | Fireworks         | `https://api.fireworks.ai/inference/v1`        | accounts/fireworks/models/llama-v3p1-70b |
| `TOGETHER_API_KEY`        | Together AI       | `https://api.together.xyz/v1`                  | meta-llama/Llama-3.3-70B-Instruct        |
| `COHERE_API_KEY`          | Cohere            | `https://api.cohere.com/v2`                    | command-r-plus                           |
| `CLAUDE_CODE_OAUTH_TOKEN` | Anthropic (OAuth) | `https://api.anthropic.com`                    | claude-sonnet-4-20250514                 |

### Detection Strategy

```
1. SSH connection established
2. Wait 1 second for connection to settle
3. Probe Ollama: curl -s --connect-timeout 2 localhost:11434/api/tags
4. Probe env vars: test -n "$ANTHROPIC_API_KEY" && echo "ANTHROPIC_API_KEY"
   (batched into a single SSH exec for all known vars)
5. Combine results → RemoteAiDetectionResult
6. Show non-intrusive notification if anything detected
7. User taps notification → choose provider
```

### Provider Ranking (when multiple detected)

Priority order for auto-recommendation:

1. Anthropic (Claude) — best reasoning for terminal commands
2. OpenAI — strong general purpose
3. OpenRouter — unified gateway, likely has good models
4. Groq — very fast inference
5. Google Gemini — good and free tier available
6. Ollama — local, no API costs
7. Others — alphabetical

### SSH Proxy Execution

All API calls are proxied through the SSH connection:

```bash
# Cloud provider call (proxied through SSH)
curl -s https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d '{"model": "claude-sonnet-4-20250514", "max_tokens": 256, ...}'

# Ollama call (local to the remote host)
curl -s localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "llama3:8b", ...}'
```

The key insight: `$ANTHROPIC_API_KEY` is expanded by the remote shell, so Bento
never sees the actual value. The `curl` runs on the remote machine with its own
network and credentials.

## Capabilities

### New Capabilities

- `remote-env-detection`: Detect AI provider env vars on SSH hosts
- `remote-provider-ranking`: Auto-rank detected providers by quality
- `remote-cloud-proxy`: Proxy cloud API calls through SSH
- `remote-provider-selection`: UI for choosing among detected providers

### Existing Capabilities (from original scope)

- `ollama-detection`: Auto-detect Ollama on SSH hosts
- `remote-inference`: Use server-side Ollama for AI
- `remote-model-selection`: Pick from server's installed models

### Modified Capabilities

- `ai-service`: RemoteAiService implements AiService for both Ollama and cloud
  proxy modes
- `ssh-session`: Adds AI detection probing after connection
- `ai-setup-flow`: Shows "Remote AI" option when providers detected

## Dependencies

- Requires: `ai-gateway` (for AiService interface) ✅ Completed
- Requires: `ssh-connectivity` (for SSH tunnel/exec) ✅ Completed
- Requires: `ai-setup-flow` (for setup wizard integration) ✅ Completed
- Required by: nothing (self-contained feature)

## Phase

**Phase 2 - Intelligence** (Months 5-7)

## Priority

**P0 - Must Have**

Remote AI via environment variable detection provides the most seamless
onboarding experience. Most developers already have AI API keys configured on
their machines. This is the fastest path from "install Bento" to "working AI
suggestions" without any manual configuration.
