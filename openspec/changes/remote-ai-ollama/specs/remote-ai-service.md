# L2 Contract: RemoteAiService

## Purpose

Implements the AiService interface for remote AI, routing requests to either
Ollama running on the SSH host or cloud providers via SSH-proxied API calls.
Provides a unified interface regardless of which remote backend is active.

## Parent

- L3: `ai-setup-flow` (user selects remote AI mode)
- L2: `ai-gateway/ai-service-interface` (implements AiService)
- L2: `ssh-connectivity/ssh-client` (uses SSH for exec)

## Interface

```dart
/// Remote AI service — routes to Ollama or cloud proxy backend
class RemoteAiService implements AiService {
  RemoteAiService({
    required SshSession sshSession,
    required RemoteAiConfig config,
    required RemoteBackend backend,
  });

  /// The active backend (Ollama or cloud proxy)
  RemoteBackend get backend;

  /// Switch to a different backend/provider
  void switchBackend(RemoteBackend newBackend);

  /// Whether this service is bound to an active SSH session
  bool get isConnected;

  /// Handle SSH disconnection
  void onDisconnected();

  /// Handle SSH reconnection — triggers re-detection
  void onReconnected(SshSession newSession);

  // Inherited from AiService:
  // - Future<AiSuggestion> generateCommand(AiPrompt prompt)
  // - Stream<AiStreamEvent> generateCommandStream(AiPrompt prompt)
  // - Future<String> summarizeOutput(String output)
  // - Future<bool> isAvailable()
  // - AiPrivacyMode get privacyMode => AiPrivacyMode.remote
  // - Future<void> dispose()
}

/// Abstract backend that RemoteAiService delegates to
abstract class RemoteBackend {
  /// Execute a command generation request via SSH
  Future<AiSuggestion> generateCommand(
    SshSession session,
    AiPrompt prompt,
  );

  /// Execute a streaming command generation via SSH
  Stream<AiStreamEvent> generateCommandStream(
    SshSession session,
    AiPrompt prompt,
  );

  /// Execute an output summarization request via SSH
  Future<String> summarizeOutput(
    SshSession session,
    String output,
  );

  /// Whether this backend is properly configured
  bool get isConfigured;

  /// Display name for UI
  String get displayName;

  /// Privacy description
  String get privacyDescription;
}
```

## Backend Implementations

### OllamaBackend

```dart
/// Uses Ollama's OpenAI-compatible API on the remote host
class OllamaBackend extends RemoteBackend {
  OllamaBackend({
    required this.selectedModel,
    required this.availableModels,
    this.port = 11434,
  });

  final String selectedModel;
  final List<OllamaModel> availableModels;
  final int port;

  @override
  String get displayName => 'Ollama ($selectedModel)';

  @override
  String get privacyDescription =>
      'Running locally on remote server. No data leaves your infrastructure.';

  @override
  Future<AiSuggestion> generateCommand(
    SshSession session,
    AiPrompt prompt,
  ) async {
    final requestBody = _buildRequestBody(prompt, stream: false);
    final escaped = ShellEscape.escape(jsonEncode(requestBody));

    final result = await session.execute('''
curl -s localhost:$port/v1/chat/completions \\
  -H "Content-Type: application/json" \\
  -d '$escaped'
''');

    if (result.exitCode != 0) {
      throw RemoteExecutionException(
        'Ollama request failed: ${result.stderr}',
        exitCode: result.exitCode,
      );
    }

    return _parseOpenAiResponse(result.stdout);
  }
}
```

### CloudProxyBackend

```dart
/// Proxies cloud API calls through SSH using the remote host's API keys
class CloudProxyBackend extends RemoteBackend {
  CloudProxyBackend({
    required this.providerConfig,
    required this.envVarName,
  });

  final RemoteProviderConfig providerConfig;
  final String envVarName; // Which env var holds the API key

  @override
  String get displayName => providerConfig.displayName;

  @override
  String get privacyDescription =>
      'API calls routed through remote host. '
      'Keys never leave the remote machine.';

  @override
  Future<AiSuggestion> generateCommand(
    SshSession session,
    AiPrompt prompt,
  ) async {
    final curl = _buildCurlCommand(prompt, stream: false);

    final result = await session.execute(curl)
        .timeout(const Duration(seconds: 30));

    if (result.exitCode != 0) {
      throw RemoteExecutionException(
        'API request failed: ${result.stderr}',
        exitCode: result.exitCode,
      );
    }

    return _parseResponse(result.stdout);
  }

  /// Build curl command for this provider.
  /// Key insight: $ENV_VAR is expanded by remote shell, not by Dart.
  String _buildCurlCommand(AiPrompt prompt, {required bool stream}) {
    final body = _buildRequestBody(prompt, stream: stream);
    final escapedBody = ShellEscape.escape(jsonEncode(body));

    switch (providerConfig.apiFormat) {
      case ApiFormat.openaiCompatible:
        return _buildOpenAiCompatibleCurl(escapedBody, stream);
      case ApiFormat.anthropicMessages:
        return _buildAnthropicCurl(escapedBody, stream);
    }
  }

  String _buildOpenAiCompatibleCurl(String body, bool stream) {
    final endpoint = '${providerConfig.apiBaseUrl}/chat/completions';
    final authHeader = providerConfig.authHeaderFormat
        .replaceAll(r'$KEY', '\$${envVarName}');

    final extraHeaders = providerConfig.extraHeaders.entries
        .map((e) => '-H "${e.key}: ${e.value}"')
        .join(' \\\n  ');

    return '''
curl -s${stream ? 'N' : ''} $endpoint \\
  -H "${providerConfig.authHeaderName}: $authHeader" \\
  -H "Content-Type: application/json" \\
  ${extraHeaders.isNotEmpty ? '$extraHeaders \\\n  ' : ''}-d '$body'
''';
  }

  String _buildAnthropicCurl(String body, bool stream) {
    return '''
curl -s${stream ? 'N' : ''} ${providerConfig.apiBaseUrl}/v1/messages \\
  -H "x-api-key: \$${envVarName}" \\
  -H "anthropic-version: 2023-06-01" \\
  -H "Content-Type: application/json" \\
  -d '$body'
''';
  }

  /// Build request body appropriate for the provider's API format
  Map<String, dynamic> _buildRequestBody(AiPrompt prompt, {required bool stream}) {
    switch (providerConfig.apiFormat) {
      case ApiFormat.openaiCompatible:
        return {
          'model': providerConfig.defaultModel,
          'messages': [
            {'role': 'system', 'content': _buildSystemPrompt(prompt.context)},
            {'role': 'user', 'content': prompt.text},
          ],
          'max_tokens': 256,
          'temperature': 0.3,
          'stream': stream,
        };
      case ApiFormat.anthropicMessages:
        return {
          'model': providerConfig.defaultModel,
          'system': _buildSystemPrompt(prompt.context),
          'messages': [
            {'role': 'user', 'content': prompt.text},
          ],
          'max_tokens': 256,
          'temperature': 0.3,
          if (stream) 'stream': true,
        };
    }
  }
}
```

## Data Types

```dart
/// Ollama model metadata (from /api/tags response)
@freezed
class OllamaModel with _$OllamaModel {
  const factory OllamaModel({
    required String name,
    String? digest,
    @Default(0) int sizeBytes,
    required DateTime modifiedAt,
    Map<String, dynamic>? details,
  }) = _OllamaModel;

  const OllamaModel._();

  /// Pretty name for display (e.g., "Llama3" from "llama3:8b")
  String get displayName {
    final base = name.split(':').first;
    return base[0].toUpperCase() + base.substring(1);
  }

  /// Size formatted for display (e.g., "4.3 GB")
  String get formattedSize => '${(sizeBytes / 1e9).toStringAsFixed(1)} GB';

  factory OllamaModel.fromJson(Map<String, dynamic> json) =>
      _$OllamaModelFromJson(json);
}

/// Per-host remote AI configuration
@freezed
class RemoteAiConfig with _$RemoteAiConfig {
  const factory RemoteAiConfig({
    required String hostId,

    /// Which backend type is selected
    required RemoteBackendType backendType,

    /// For Ollama: selected model name
    String? ollamaModel,

    /// For cloud proxy: which provider
    RemoteCloudProvider? cloudProvider,

    /// For cloud proxy: which env var to use
    String? envVarName,

    /// Ollama port (default 11434)
    @Default(11434) int ollamaPort,
  }) = _RemoteAiConfig;
}

/// Type of remote backend
enum RemoteBackendType {
  ollama,
  cloudProxy,
}
```

## Behavior

### Command Generation (Ollama)

```
GIVEN Ollama backend is selected and SSH is connected
WHEN generateCommand() is called
THEN build OpenAI-compatible request body
AND execute curl to localhost:11434 via SSH
AND parse JSON response
AND return AiSuggestion with command and confidence

GIVEN curl returns non-zero exit code
WHEN result is received
THEN throw RemoteExecutionException with stderr message
```

### Command Generation (Cloud Proxy)

```
GIVEN cloud proxy backend is selected (e.g., Anthropic)
WHEN generateCommand() is called
THEN build provider-specific curl command
AND use $ENV_VAR for API key (shell expansion, never read by Bento)
AND execute curl via SSH
AND parse provider-specific response format
AND return AiSuggestion

GIVEN Anthropic provider is selected
WHEN building request
THEN use Anthropic Messages API format (/v1/messages)
AND include x-api-key header with $ANTHROPIC_API_KEY
AND include anthropic-version header

GIVEN OpenAI-compatible provider is selected (OpenAI, Groq, etc.)
WHEN building request
THEN use standard chat completion format (/chat/completions)
AND include Authorization: Bearer $API_KEY header
```

### Streaming

```
GIVEN streaming is requested
WHEN generateCommandStream() is called
THEN add stream: true to request body
AND use curl -sN flag for streaming output
AND execute via SSH executeStream
AND parse SSE data: lines incrementally
AND yield AiStreamEvent.token for each delta
AND yield AiStreamEvent.complete at end

GIVEN Anthropic streaming format
WHEN parsing SSE events
THEN handle event types: message_start, content_block_delta, message_stop
AND extract text from content_block_delta events

GIVEN OpenAI-compatible streaming format
WHEN parsing SSE events
THEN handle data: lines with choices[0].delta.content
AND handle data: [DONE] as stream end
```

### Response Parsing

```
GIVEN OpenAI-compatible response (Ollama, OpenAI, Groq, etc.)
WHEN parsing JSON response
THEN extract choices[0].message.content
AND trim whitespace
AND return as AiSuggestion with default confidence 0.8

GIVEN Anthropic Messages API response
WHEN parsing JSON response
THEN extract content[0].text
AND trim whitespace
AND return as AiSuggestion with default confidence 0.8

GIVEN response contains error field
WHEN parsing response
THEN throw RemoteApiException with error message and provider name
```

### SSH Lifecycle

```
GIVEN SSH connection drops
WHEN onDisconnected() is called
THEN mark service as unavailable
AND emit RemoteAiStatusEvent.disconnected

GIVEN SSH reconnects
WHEN onReconnected() is called with new session
THEN update session reference
AND mark as connected
AND trigger re-detection (models or env vars may have changed)

GIVEN isAvailable() is called
WHEN SSH is disconnected
THEN return false

GIVEN isAvailable() is called
WHEN SSH is connected and backend is configured
THEN return true
```

## Shell Escaping

```dart
/// Utility for safely escaping strings for shell execution
class ShellEscape {
  /// Escape a string for use in single-quoted shell context.
  ///
  /// Strategy: Replace ' with '\'' (end quote, escaped quote, start quote)
  /// This is the safest approach for arbitrary JSON content.
  static String escape(String input) {
    return input.replaceAll("'", r"'\''");
  }
}
```

## Error Handling

| Error                    | Exception Type              | Recovery                             |
| ------------------------ | --------------------------- | ------------------------------------ |
| SSH disconnected         | RemoteDisconnectedException | Mark unavailable, await reconnect    |
| curl not found           | CurlNotFoundException       | Inform user, suggest installing curl |
| curl exec failed         | RemoteExecutionException    | Show stderr, suggest checking config |
| Invalid JSON response    | RemoteParseException        | Show raw response for debugging      |
| API error (4xx/5xx)      | RemoteApiException          | Show provider error message          |
| Timeout (>30s)           | TimeoutException            | Cancel and suggest retry             |
| Model not found (Ollama) | ModelNotFoundException      | Fall back to first available model   |
| Rate limited             | RateLimitException          | Show wait time, suggest retry later  |

## Dependencies

- Active SSH session from `ssh-connectivity`
- `curl` installed on remote host (standard on most systems)
- For cloud proxy: internet access from remote host to provider APIs
- For Ollama: Ollama running on localhost:11434 of remote host

## Prompt Engineering

System prompt is shared with other AiService implementations but enhanced with
remote context:

```
You are a terminal command assistant. Generate only the command, no explanation.

Environment:
- OS: {remotePlatform}        # Detected from SSH (uname -s)
- Shell: {remoteShell}        # e.g., bash, zsh
- User: {remoteUser}
- Host: {hostname}
- Working directory: {cwd}
- Recent commands: {history}   # Last 5 commands from terminal
```
