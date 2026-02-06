# Proposal: Remote AI (Ollama via SSH)

## Why

Many developers and sysadmins run Ollama on their servers for AI inference. When
Bento connects to a server via SSH, we can automatically detect if Ollama is
running and offer to use it for AI suggestions. This provides:

- **Server-Side Inference**: Use powerful server GPUs for better/faster models
- **Privacy**: Data stays on user's own infrastructure
- **No Extra Setup**: Auto-detect, no manual configuration needed
- **Free**: No API costs, uses existing Ollama installation

This bridges local privacy with cloud capability - your models, your servers.

## What Changes

- Detect Ollama running on SSH-connected servers
- Implement RemoteAiService using Ollama's OpenAI-compatible API
- Support port forwarding through existing SSH connection
- Allow users to select from server's available models
- Handle connection lifecycle (reconnect on SSH reconnect)

## Technical Details

### Detection Flow

When SSH connection is established:

```
1. Probe localhost:11434/api/tags via SSH tunnel
2. If responds → Ollama detected, get model list
3. If no response → No Ollama, skip remote option
4. Store detection result per host
```

### Ollama API

Ollama exposes an OpenAI-compatible API:

**List models**: `GET localhost:11434/api/tags`

```json
{
  "models": [
    {"name": "llama3:8b", "size": 4661224676, ...},
    {"name": "codellama:7b", "size": 3825820160, ...}
  ]
}
```

**Chat completion**: `POST localhost:11434/v1/chat/completions`

```json
{
  "model": "llama3:8b",
  "messages": [
    { "role": "system", "content": "..." },
    { "role": "user", "content": "list docker containers" }
  ],
  "stream": true
}
```

### SSH Tunnel Strategy

Rather than opening a separate tunnel, use the existing SSH channel:

```dart
// Execute HTTP request via SSH exec
final result = await sshClient.execute('''
  curl -s localhost:11434/v1/chat/completions \\
    -H "Content-Type: application/json" \\
    -d '{"model": "llama3:8b", "messages": [...], "stream": false}'
''');
```

For streaming, we could either:

1. Use `curl` with stream output over SSH
2. Set up local port forward (more complex but lower latency)

## Capabilities

### New Capabilities

- `ollama-detection`: Auto-detect Ollama on SSH hosts
- `remote-inference`: Use server-side Ollama for AI
- `remote-model-selection`: Pick from server's installed models

### Modified Capabilities

- `ai-service`: RemoteAiService implements AiService interface
- `ssh-session`: Adds Ollama probing after connection

## Dependencies

- Requires: `ai-gateway` (for AiService interface)
- Requires: `ssh-connectivity` (for SSH tunnel/exec)
- Required by: `ai-setup-flow` (shows remote option when available)

## Phase

**Phase 2 - Intelligence** (Months 5-7)

## Priority

**P1 - Should Have**

Remote AI is a great option for power users with their own infrastructure. Not
blocking for MVP since it requires SSH and Ollama setup.
