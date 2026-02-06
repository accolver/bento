# L2 Contract: OllamaDetector

## Purpose

Automatically detects Ollama instances running on SSH-connected servers. Runs as
a background probe after SSH connection establishment to discover available AI
capabilities without user intervention.

## Parent

- L2: `ssh-connectivity/ssh-client` (hooks into connection events)
- L2: `remote-ai-ollama/remote-ai-service` (provides detection results)

## Interface

```dart
/// Detects Ollama on SSH-connected servers
class OllamaDetector {
  OllamaDetector({
    required SshConnectionManager connectionManager,
  });
  
  /// Stream of detection events
  Stream<OllamaDetectionEvent> get detectionEvents;
  
  /// Manually trigger detection for a specific session
  Future<OllamaDetectionResult> detectForSession(SshSession session);
  
  /// Get cached detection result for a host
  OllamaDetectionResult? getCachedResult(String hostId);
  
  /// Clear cached result (e.g., after server restart)
  void clearCache(String hostId);
}
```

## Data Types

```dart
/// Result of Ollama detection
class OllamaDetectionResult {
  final String hostId;
  final bool detected;
  final List<OllamaModel> models;
  final DateTime checkedAt;
  final String? error;
  
  bool get hasModels => models.isNotEmpty;
}

/// Events emitted during detection
sealed class OllamaDetectionEvent {
  final String hostId;
}

class OllamaDetectedEvent extends OllamaDetectionEvent {
  final List<OllamaModel> models;
}

class OllamaNotFoundEvent extends OllamaDetectionEvent {
  final String? reason;  // e.g., "timeout", "connection refused"
}
```

## Behavior

### Automatic Detection

```
GIVEN SSH connection is established to a host
WHEN SshConnectedEvent is received
THEN schedule detection probe (delayed 1 second to allow connection to settle)

GIVEN probe is scheduled
WHEN probe executes
THEN run curl command to localhost:11434/api/tags
AND emit appropriate detection event
AND cache the result
```

### Manual Detection

```
GIVEN user requests detection check
WHEN detectForSession() is called
THEN bypass cache and probe immediately
AND update cache with new result
AND return result
```

### Caching Strategy

```
GIVEN detection was performed for a host
WHEN getCachedResult() is called within 5 minutes
THEN return cached result (avoid repeated probes)

GIVEN cache entry is older than 5 minutes
WHEN new SSH session connects to same host
THEN re-probe and update cache
```

## Implementation

```dart
class OllamaDetector {
  final Map<String, OllamaDetectionResult> _cache = {};
  final _eventController = StreamController<OllamaDetectionEvent>.broadcast();
  
  OllamaDetector({required SshConnectionManager connectionManager}) {
    connectionManager.connectionEvents.listen(_onConnectionEvent);
  }
  
  void _onConnectionEvent(SshConnectionEvent event) {
    if (event is SshConnectedEvent) {
      // Delay probe to let connection settle
      Future.delayed(Duration(seconds: 1), () {
        _probeForOllama(event.session);
      });
    }
  }
  
  Future<void> _probeForOllama(SshSession session) async {
    final hostId = session.hostId;
    
    try {
      final result = await session.execute(
        'curl -s --connect-timeout 2 localhost:11434/api/tags',
      ).timeout(Duration(seconds: 3));
      
      if (result.exitCode == 0) {
        final json = jsonDecode(result.stdout);
        final models = _parseModels(json);
        
        final detectionResult = OllamaDetectionResult(
          hostId: hostId,
          detected: true,
          models: models,
          checkedAt: DateTime.now(),
        );
        
        _cache[hostId] = detectionResult;
        _eventController.add(OllamaDetectedEvent(
          hostId: hostId,
          models: models,
        ));
      } else {
        _cacheNotFound(hostId, 'curl failed: ${result.stderr}');
      }
    } on TimeoutException {
      _cacheNotFound(hostId, 'timeout');
    } catch (e) {
      _cacheNotFound(hostId, e.toString());
    }
  }
  
  void _cacheNotFound(String hostId, String? reason) {
    _cache[hostId] = OllamaDetectionResult(
      hostId: hostId,
      detected: false,
      models: [],
      checkedAt: DateTime.now(),
      error: reason,
    );
    _eventController.add(OllamaNotFoundEvent(
      hostId: hostId,
      reason: reason,
    ));
  }
  
  List<OllamaModel> _parseModels(Map<String, dynamic> json) {
    final modelsList = json['models'] as List? ?? [];
    return modelsList.map((m) => OllamaModel(
      name: m['name'] as String,
      digest: m['digest'] as String?,
      sizeBytes: m['size'] as int? ?? 0,
      modifiedAt: DateTime.tryParse(m['modified_at'] ?? '') ?? DateTime.now(),
      details: m['details'] as Map<String, dynamic>?,
    )).toList();
  }
}
```

## Integration Points

### SSH Connection Events

```dart
// In SSH feature initialization
final sshManager = ref.watch(sshConnectionManagerProvider);
final ollamaDetector = OllamaDetector(connectionManager: sshManager);

// Listen for detections
ollamaDetector.detectionEvents.listen((event) {
  if (event is OllamaDetectedEvent) {
    // Show notification or update AI options
    ref.read(aiOptionsProvider.notifier).addRemoteOption(
      hostId: event.hostId,
      models: event.models,
    );
  }
});
```

### AI Setup Wizard Integration

```dart
// In setup wizard, check if remote option is available
final ollamaDetector = ref.watch(ollamaDetectorProvider);
final currentHostId = ref.watch(currentSshSessionProvider)?.hostId;

if (currentHostId != null) {
  final detection = ollamaDetector.getCachedResult(currentHostId);
  if (detection?.detected == true) {
    // Show "Use server's Ollama" option in wizard
  }
}
```

## Error Handling

| Error                 | Behavior                           |
| --------------------- | ---------------------------------- |
| curl not found        | Treat as "not detected" (silent)   |
| Connection refused    | Treat as "not detected" (silent)   |
| Invalid JSON response | Log warning, treat as not detected |
| SSH channel error     | Treat as not detected, don't cache |

## Performance Considerations

- Probe is non-blocking (async)
- 3-second timeout prevents hanging on slow servers
- Results cached to avoid repeated probes
- Detection runs in background, doesn't block SSH usage
