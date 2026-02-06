# L2 Contract: RemoteAiService

## Purpose

Implements the AiService interface using Ollama running on an SSH-connected
server. Provides server-side inference through the existing SSH connection
without exposing data to third-party cloud providers.

## Parent

- L3: `ai-setup-flow` (user selects remote AI mode)
- L2: `ai-gateway/ai-service-interface` (implements AiService)
- L2: `ssh-connectivity/ssh-client` (uses SSH for tunnel/exec)

## Interface

```dart
/// Remote AI service using Ollama via SSH
class RemoteAiService implements AiService {
  RemoteAiService({
    required SshSession sshSession,
    required RemoteAiConfig config,
  });

  /// Probe for Ollama on the connected server
  /// Returns list of available models if found, null if not
  static Future<List<OllamaModel>?> detectOllama(SshSession session);
  
  /// Get list of models installed on server
  Future<List<OllamaModel>> getAvailableModels();
  
  /// Current selected model
  OllamaModel get selectedModel;
  
  /// Change selected model
  void selectModel(String modelName);
  
  /// Whether this service is bound to an SSH session
  bool get isConnected;
  
  /// Handle SSH disconnection
  void onDisconnected();
  
  // Inherited from AiService:
  // - Future<AiSuggestion> generateCommand(AiPrompt prompt)
  // - Stream<AiStreamEvent> generateCommandStream(AiPrompt prompt)
  // - Future<bool> isAvailable()
  // - AiPrivacyMode get privacyMode => AiPrivacyMode.remote
}
```

## Data Types

```dart
/// Ollama model metadata (from /api/tags response)
class OllamaModel {
  final String name;            // e.g., 'llama3:8b'
  final String? digest;         // Model hash
  final int sizeBytes;          // Model size on disk
  final DateTime modifiedAt;    // Last modified
  final Map<String, dynamic>? details;  // Extra metadata
  
  /// Pretty name for display
  String get displayName => name.split(':').first.capitalize();
  
  /// Size formatted for display
  String get formattedSize => '${(sizeBytes / 1e9).toStringAsFixed(1)} GB';
}

/// Remote AI configuration
class RemoteAiConfig {
  final String hostId;          // Which SSH host this is for
  final String selectedModel;   // Currently selected model name
  final int port;               // Ollama port (default: 11434)
}
```

## Behavior

### Detection Flow

```
GIVEN user connects to SSH host
WHEN connection is established
THEN probe localhost:11434/api/tags via SSH exec
AND wait up to 2 seconds for response

GIVEN Ollama responds with model list
WHEN detection completes
THEN store list of available models
AND emit OllamaDetectedEvent

GIVEN Ollama is not running or unreachable
WHEN probe times out or fails
THEN mark host as "no Ollama"
AND do not emit event (silent failure)
```

### Command Generation

```
GIVEN Ollama is detected and model selected
WHEN generateCommand() is called
THEN execute curl request via SSH
AND parse JSON response
AND return AiSuggestion

GIVEN SSH connection is lost
WHEN generateCommand() is called
THEN throw RemoteDisconnectedException
AND mark service as unavailable
```

### Model Selection

```
GIVEN multiple models are available
WHEN user selects a model
THEN selectedModel is updated
AND preference is saved per-host

GIVEN only one model is available
WHEN user configures remote AI
THEN that model is auto-selected
```

## SSH Execution Strategy

### Option A: curl via SSH exec (Simpler)

```dart
Future<AiSuggestion> generateCommand(AiPrompt prompt) async {
  final requestBody = jsonEncode({
    'model': _config.selectedModel,
    'messages': _buildMessages(prompt),
    'stream': false,
  });
  
  // Escape for shell
  final escapedBody = requestBody.replaceAll("'", "'\\''");
  
  final result = await _sshSession.execute('''
    curl -s localhost:${_config.port}/v1/chat/completions \\
      -H "Content-Type: application/json" \\
      -d '$escapedBody'
  ''');
  
  if (result.exitCode != 0) {
    throw RemoteExecutionException(result.stderr);
  }
  
  final json = jsonDecode(result.stdout);
  return _parseResponse(json);
}
```

### Option B: SSH Port Forward (Lower Latency)

```dart
// In SSH connection setup:
await _sshSession.forwardLocalPort(
  localPort: _localPort,
  remoteHost: 'localhost',
  remotePort: 11434,
);

// Then use regular HTTP:
final response = await _httpClient.post(
  Uri.parse('http://localhost:$_localPort/v1/chat/completions'),
  body: ...,
);
```

**Decision**: Start with Option A (simpler), move to Option B if latency is an
issue.

## Detection Implementation

```dart
static Future<List<OllamaModel>?> detectOllama(SshSession session) async {
  try {
    final result = await session.execute(
      'curl -s --connect-timeout 2 localhost:11434/api/tags',
    ).timeout(Duration(seconds: 3));
    
    if (result.exitCode != 0) return null;
    
    final json = jsonDecode(result.stdout);
    final models = (json['models'] as List)
        .map((m) => OllamaModel.fromJson(m))
        .toList();
    
    return models.isEmpty ? null : models;
  } catch (e) {
    return null;  // Silent failure - Ollama not available
  }
}
```

## Connection Lifecycle

```dart
class RemoteAiService {
  bool _connected = true;
  
  void onDisconnected() {
    _connected = false;
    // Notify listeners that remote AI is no longer available
    _controller.add(RemoteAiStatusEvent.disconnected);
  }
  
  void onReconnected(SshSession newSession) {
    _sshSession = newSession;
    _connected = true;
    // Re-probe for Ollama (models may have changed)
    _refreshModels();
  }
  
  @override
  Future<bool> isAvailable() async {
    return _connected && _models.isNotEmpty;
  }
}
```

## Error Handling

| Error                    | Recovery                                  |
| ------------------------ | ----------------------------------------- |
| curl not found on server | Inform user, suggest installing curl      |
| Ollama not responding    | Mark unavailable, suggest checking server |
| SSH disconnected         | Mark unavailable, re-probe on reconnect   |
| Model not found          | Fall back to first available model        |
| Generation timeout       | Cancel and return timeout error           |

## Prompt Engineering

Same system prompt as LocalAiService, but can include:

```
Environment:
- OS: {remotePlatform}  # Detected from SSH
- Shell: {remoteShell}  # e.g., bash, zsh
- User: {remoteUser}
- Host: {hostname}
```

## Dependencies

- Requires active SSH session (from `ssh-connectivity`)
- Requires curl on remote server (standard on most systems)
