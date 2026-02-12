# L2 Contract: OllamaDetector

## Purpose

Automatically detects Ollama instances running on SSH-connected servers. Runs as
a background probe after SSH connection establishment to discover available AI
capabilities without user intervention.

This is one of two detection strategies used by the parent `RemoteAiDetector`.
The other is `EnvProviderDetector` for cloud API keys.

## Parent

- L2: `ssh-connectivity/ssh-client` (hooks into connection events)
- L2: `remote-ai-ollama/remote-ai-service` (provides detection results)

## Interface

```dart
/// Detects Ollama on SSH-connected servers
class OllamaDetector {
  const OllamaDetector();

  /// Probe an SSH session for Ollama.
  ///
  /// Executes `curl localhost:11434/api/tags` via SSH exec.
  /// Returns list of available models if Ollama is found, null if not.
  Future<List<OllamaModel>?> detect(SshSession session);
}
```

## Behavior

### Detection

```
GIVEN SSH session is available
WHEN detect() is called
THEN execute curl command to localhost:11434/api/tags via SSH exec
AND wait up to 3 seconds for response (2s connect timeout + 1s buffer)

GIVEN Ollama responds with model list
WHEN response is parsed successfully
THEN return list of OllamaModel objects
AND include name, size, digest, details for each

GIVEN Ollama responds with empty model list
WHEN models array is empty
THEN return null (treat as not detected — no usable models)

GIVEN Ollama is not running or unreachable
WHEN curl times out or returns non-zero
THEN return null (silent failure)

GIVEN curl is not installed on remote host
WHEN command fails with "command not found"
THEN return null (silent failure)
```

## Implementation

```dart
class OllamaDetector {
  const OllamaDetector();

  Future<List<OllamaModel>?> detect(SshSession session) async {
    try {
      final result = await session.execute(
        'curl -s --connect-timeout 2 localhost:11434/api/tags',
      ).timeout(const Duration(seconds: 3));

      if (result.exitCode != 0) return null;

      final json = jsonDecode(result.stdout) as Map<String, dynamic>;
      final models = _parseModels(json);

      return models.isEmpty ? null : models;
    } on TimeoutException {
      return null;
    } catch (e) {
      return null;
    }
  }

  List<OllamaModel> _parseModels(Map<String, dynamic> json) {
    final modelsList = json['models'] as List? ?? [];
    return modelsList
        .map((m) => OllamaModel(
              name: m['name'] as String,
              digest: m['digest'] as String?,
              sizeBytes: m['size'] as int? ?? 0,
              modifiedAt:
                  DateTime.tryParse(m['modified_at'] ?? '') ?? DateTime.now(),
              details: m['details'] as Map<String, dynamic>?,
            ))
        .toList();
  }
}
```

## Error Handling

| Error                 | Behavior                          |
| --------------------- | --------------------------------- |
| curl not found        | Return null (silent)              |
| Connection refused    | Return null (silent)              |
| Invalid JSON response | Return null (silent, log warning) |
| SSH channel error     | Return null (silent)              |
| Timeout               | Return null (silent)              |

## Performance Considerations

- 3-second timeout prevents hanging on slow servers
- Single SSH exec command — minimal overhead
- Results cached by parent `RemoteAiDetector`
