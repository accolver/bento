# Proposal: Cloud AI Providers

## Why

While local AI handles simple tasks privately, complex commands benefit from
more capable cloud models. Rather than integrating multiple provider SDKs
(OpenAI, Anthropic, Google), we use **OpenRouter** - a unified API that provides
access to 500+ models through a single endpoint and API key.

Benefits of OpenRouter:

- **Single Integration**: One API for Claude, GPT-4, Gemini, Llama, and more
- **User Choice**: Users pick their preferred model
- **Fallback**: Auto-failover if a model is unavailable
- **Cost Transparency**: Per-request pricing visible to users
- **No Vendor Lock-in**: Switch models without code changes

## What Changes

- Implement CloudAiService using OpenRouter API
- Add secure API key storage (using existing credential vault)
- Implement privacy consent flow with clear data transmission warnings
- Support streaming responses for real-time feedback
- Handle rate limits, errors, and model availability gracefully
- Allow users to select preferred model from available options

## Technical Details

### OpenRouter API

**Endpoint**: `https://openrouter.ai/api/v1/chat/completions`

**Format**: OpenAI-compatible chat completion API

```bash
curl https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "anthropic/claude-3.5-sonnet",
    "messages": [
      {"role": "system", "content": "You are a terminal command assistant..."},
      {"role": "user", "content": "list all docker containers"}
    ],
    "max_tokens": 256,
    "temperature": 0.3
  }'
```

### Recommended Models

| Model                         | Cost (input/output) | Best For       |
| ----------------------------- | ------------------- | -------------- |
| `anthropic/claude-3.5-sonnet` | $3/$15 per 1M       | Best reasoning |
| `openai/gpt-4o-mini`          | $0.15/$0.60 per 1M  | Fast & cheap   |
| `google/gemini-2.0-flash`     | $0.10/$0.40 per 1M  | Very fast      |
| `meta-llama/llama-3.1-70b`    | Free tier available | Budget option  |

Default: `openai/gpt-4o-mini` (best balance of speed, quality, cost)

### Privacy Considerations

- **Explicit Consent**: Users must acknowledge data transmission
- **Visible Indicator**: UI shows when cloud AI is active
- **No Context by Default**: Only send user prompt, not terminal history
- **Optional Context**: User can enable sending recent commands for better
  suggestions

## Capabilities

### New Capabilities

- `cloud-inference`: OpenRouter API integration
- `model-selection`: User picks preferred cloud model
- `api-key-management`: Secure storage of OpenRouter key
- `usage-tracking`: Track token usage and estimated costs

### Modified Capabilities

- `ai-service`: CloudAiService implements AiService interface
- `privacy-consent`: Consent flow before enabling cloud AI

## Dependencies

- Requires: `ai-gateway` (for AiService interface)
- Requires: `credential-storage` (for API key storage)
- Required by: `ai-setup-flow` (configuration wizard)

## Phase

**Phase 2 - Intelligence** (Months 5-7)

## Priority

**P1 - Should Have**

Cloud AI is opt-in for users who want better suggestions and accept data
transmission. Local AI remains the privacy-first default.
