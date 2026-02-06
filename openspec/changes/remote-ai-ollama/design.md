# Design: Remote AI (Ollama via SSH)

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    SSH Connection                            │
│              (user connects to server)                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    OllamaDetector                            │
│         (auto-probes for Ollama after connect)               │
├─────────────────────────────────────────────────────────────┤
│  - Listens for SshConnectedEvent                            │
│  - Executes: curl localhost:11434/api/tags                  │
│  - Emits OllamaDetectedEvent with model list                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    AI Setup Wizard                           │
│         (shows "Remote AI" option if detected)               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    RemoteAiService                           │
│                  (implements AiService)                      │
├─────────────────────────────────────────────────────────────┤
│  - generateCommand() → executes curl via SSH                │
│  - generateCommandStream() → streaming via SSH              │
│  - Bound to specific SSH session                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│               SSH Session (exec channel)                     │
│                                                              │
│  curl -s localhost:11434/v1/chat/completions \              │
│    -H "Content-Type: application/json" \                    │
│    -d '{"model": "llama3:8b", ...}'                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Ollama Server                             │
│              (running on remote host)                        │
├─────────────────────────────────────────────────────────────┤
│  localhost:11434                                            │
│  - GET  /api/tags         → list models                     │
│  - POST /v1/chat/completions → generate (OpenAI-compat)     │
└─────────────────────────────────────────────────────────────┘
```

## File Structure

```
lib/features/ai/
├── domain/
│   └── entities/
│       ├── ollama_model.dart          # Model metadata
│       ├── remote_ai_config.dart      # Remote-specific config
│       └── ollama_detection.dart      # Detection result/events
├── data/
│   └── services/
│       ├── remote_ai_service.dart     # Ollama via SSH
│       └── ollama_detector.dart       # Auto-detection
└── presentation/
    └── widgets/
        └── remote_model_selector.dart # Model picker for Ollama
```

## Communication Flow

### Detection (on SSH connect)

```
┌──────────┐     SshConnectedEvent     ┌────────────────┐
│  SSH     │ ────────────────────────▶ │ OllamaDetector │
│  Manager │                           └────────────────┘
└──────────┘                                   │
                                               │ 1. Wait 1s
                                               │ 2. Execute probe
                                               ▼
┌──────────┐     "curl localhost:11434..."   ┌────────────────┐
│  SSH     │ ◀──────────────────────────────│ OllamaDetector │
│  Session │                                 └────────────────┘
└──────────┘                                   
      │                                        
      │ JSON response                          
      ▼                                        
┌────────────────┐     OllamaDetectedEvent   ┌────────────────┐
│ OllamaDetector │ ────────────────────────▶ │ AI Setup/UI    │
└────────────────┘                           └────────────────┘
```

### Command Generation

```
┌──────────┐     generateCommand()     ┌──────────────────┐
│  AI FAB  │ ────────────────────────▶ │ RemoteAiService  │
│  Panel   │                           └──────────────────┘
└──────────┘                                   │
                                               │ Build curl command
                                               ▼
┌──────────┐     sshSession.execute()  ┌──────────────────┐
│  SSH     │ ◀─────────────────────────│ RemoteAiService  │
│  Session │                           └──────────────────┘
└──────────┘                                   
      │                                        
      │ stdout: JSON response                  
      ▼                                        
┌──────────────────┐     AiSuggestion        ┌──────────┐
│ RemoteAiService  │ ──────────────────────▶ │  AI FAB  │
└──────────────────┘                         │  Panel   │
                                             └──────────┘
```

## Ollama API Reference

### List Models

```bash
curl localhost:11434/api/tags
```

Response:

```json
{
  "models": [
    {
      "name": "llama3:8b",
      "model": "llama3:8b",
      "modified_at": "2024-01-15T10:30:00Z",
      "size": 4661224676,
      "digest": "sha256:abc123...",
      "details": {
        "parent_model": "",
        "format": "gguf",
        "family": "llama",
        "families": ["llama"],
        "parameter_size": "8B",
        "quantization_level": "Q4_0"
      }
    }
  ]
}
```

### Chat Completion (OpenAI-compatible)

```bash
curl localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3:8b",
    "messages": [
      {"role": "system", "content": "You are a terminal assistant..."},
      {"role": "user", "content": "list docker containers"}
    ],
    "max_tokens": 256,
    "temperature": 0.3,
    "stream": false
  }'
```

Response:

```json
{
  "id": "chatcmpl-123",
  "object": "chat.completion",
  "created": 1705312200,
  "model": "llama3:8b",
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": "docker ps -a"
    },
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 42,
    "completion_tokens": 5,
    "total_tokens": 47
  }
}
```

## SSH Exec Implementation

```dart
class RemoteAiService implements AiService {
  final SshSession _sshSession;
  
  Future<AiSuggestion> generateCommand(AiPrompt prompt) async {
    // Build the request JSON
    final requestBody = {
      'model': _config.selectedModel,
      'messages': [
        {'role': 'system', 'content': _buildSystemPrompt(prompt.context)},
        {'role': 'user', 'content': prompt.text},
      ],
      'max_tokens': 256,
      'temperature': 0.3,
      'stream': false,
    };
    
    // Escape for shell (handle quotes)
    final jsonStr = jsonEncode(requestBody);
    final escaped = jsonStr.replaceAll("'", "'\"'\"'");  // Shell escape
    
    // Execute via SSH
    final result = await _sshSession.execute('''
curl -s localhost:${_config.port}/v1/chat/completions \\
  -H "Content-Type: application/json" \\
  -d '$escaped'
''');
    
    if (result.exitCode != 0) {
      throw RemoteExecutionException(
        'curl failed: ${result.stderr}',
        exitCode: result.exitCode,
      );
    }
    
    // Parse response
    try {
      final json = jsonDecode(result.stdout);
      final content = json['choices'][0]['message']['content'] as String;
      return AiSuggestion(
        command: content.trim(),
        confidence: 0.8,  // No confidence from Ollama, use default
      );
    } catch (e) {
      throw RemoteParseException('Invalid Ollama response: $e');
    }
  }
}
```

## Streaming Implementation

For streaming, we pipe curl's output through the SSH channel:

```dart
Stream<AiStreamEvent> generateCommandStream(AiPrompt prompt) async* {
  final requestBody = jsonEncode({
    'model': _config.selectedModel,
    'messages': [...],
    'stream': true,
  });
  
  final escaped = _escapeForShell(requestBody);
  
  // Start streaming exec
  final stream = _sshSession.executeStream('''
curl -sN localhost:${_config.port}/v1/chat/completions \\
  -H "Content-Type: application/json" \\
  -d '$escaped'
''');
  
  final buffer = StringBuffer();
  
  await for (final chunk in stream) {
    // Parse SSE format from curl output
    for (final line in chunk.split('\n')) {
      if (line.startsWith('data: ') && !line.contains('[DONE]')) {
        try {
          final json = jsonDecode(line.substring(6));
          final delta = json['choices']?[0]?['delta']?['content'];
          if (delta != null) {
            buffer.write(delta);
            yield AiStreamEvent.token(delta);
          }
        } catch (e) {
          // Skip malformed chunks
        }
      }
    }
  }
  
  yield AiStreamEvent.complete(
    AiSuggestion(command: buffer.toString().trim()),
  );
}
```

## Decisions

### D1: SSH Exec vs Port Forward

**Decision**: Use SSH exec with curl (not port forwarding)

**Rationale**:

- Simpler implementation (no local port management)
- Works through any SSH connection (including jumpboxes)
- No firewall issues with local port binding
- Latency difference is negligible for our use case (~100ms)

### D2: Silent Detection

**Decision**: Detect Ollama silently, don't prompt if not found

**Rationale**:

- Most servers won't have Ollama - don't annoy users
- Users who have Ollama will see it appear as an option
- Avoids "failed to detect" noise in logs/UI
- Can add "Check for Ollama" manual option later if needed

### D3: Per-Host Model Selection

**Decision**: Remember model selection per SSH host

**Rationale**:

- Different servers may have different models
- User might prefer different models for different workloads
- Selection is stored with hostId as key
- Falls back to first available if stored model is gone

### D4: Connection Lifecycle

**Decision**: RemoteAiService is bound to SSH session lifecycle

**Rationale**:

- Service becomes invalid when SSH disconnects
- Must be recreated on reconnect (models may have changed)
- Prevents stale connection attempts
- Clean separation of concerns

### D5: curl Dependency

**Decision**: Require curl on remote server

**Rationale**:

- curl is available on virtually all Unix servers
- Alternative (netcat/socat) less reliable
- Can detect absence and inform user
- Avoids complex HTTP implementation over SSH channel
