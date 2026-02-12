# L2 Contract: EnvProviderDetector

## Purpose

Detects AI provider API keys configured as environment variables on
SSH-connected hosts. Checks for a curated list of known provider environment
variables without reading their values, enabling Bento to offer AI capabilities
using the remote machine's existing configuration.

## Parent

- L2: `ssh-connectivity/ssh-client` (uses SSH exec for probing)
- L2: `remote-ai-ollama/remote-ai-service` (provides detection results)

## Interface

```dart
/// Detects AI provider environment variables on SSH-connected hosts
class EnvProviderDetector {
  const EnvProviderDetector();

  /// Probe an SSH session for known AI provider env vars.
  ///
  /// Executes a batched `test -n "$VAR"` command over SSH to check
  /// which provider API keys are set. Never reads key values.
  ///
  /// Returns list of detected providers, empty if none found.
  Future<List<DetectedCloudProvider>> detect(SshSession session);
}

/// Result of detecting a single cloud provider
class DetectedCloudProvider {
  final RemoteCloudProvider provider;
  final String envVarName;        // Which env var was found
  final String displayName;       // e.g., "Claude (Anthropic)"
  final String defaultModel;      // e.g., "claude-sonnet-4-20250514"
  final int qualityRank;          // 1 = best (for ordering)
}
```

## Data Types

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

/// Static registry mapping env vars to provider metadata
class RemoteProviderRegistry {
  /// All known provider configurations
  static const List<RemoteProviderConfig> providers = [
    RemoteProviderConfig(
      provider: RemoteCloudProvider.anthropic,
      envVars: ['ANTHROPIC_API_KEY', 'CLAUDE_CODE_OAUTH_TOKEN'],
      displayName: 'Claude (Anthropic)',
      apiBaseUrl: 'https://api.anthropic.com',
      defaultModel: 'claude-sonnet-4-20250514',
      apiFormat: ApiFormat.anthropicMessages,
      authHeaderName: 'x-api-key',
      authHeaderFormat: r'$KEY',
      qualityRank: 1,
      extraHeaders: {'anthropic-version': '2023-06-01'},
    ),
    RemoteProviderConfig(
      provider: RemoteCloudProvider.openai,
      envVars: ['OPENAI_API_KEY'],
      displayName: 'GPT-4o (OpenAI)',
      apiBaseUrl: 'https://api.openai.com/v1',
      defaultModel: 'gpt-4o',
      apiFormat: ApiFormat.openaiCompatible,
      authHeaderName: 'Authorization',
      authHeaderFormat: r'Bearer $KEY',
      qualityRank: 2,
    ),
    RemoteProviderConfig(
      provider: RemoteCloudProvider.openRouter,
      envVars: ['OPENROUTER_API_KEY'],
      displayName: 'OpenRouter',
      apiBaseUrl: 'https://openrouter.ai/api/v1',
      defaultModel: 'anthropic/claude-sonnet-4-20250514',
      apiFormat: ApiFormat.openaiCompatible,
      authHeaderName: 'Authorization',
      authHeaderFormat: r'Bearer $KEY',
      qualityRank: 3,
    ),
    RemoteProviderConfig(
      provider: RemoteCloudProvider.groq,
      envVars: ['GROQ_API_KEY'],
      displayName: 'Groq',
      apiBaseUrl: 'https://api.groq.com/openai/v1',
      defaultModel: 'llama-3.3-70b-versatile',
      apiFormat: ApiFormat.openaiCompatible,
      authHeaderName: 'Authorization',
      authHeaderFormat: r'Bearer $KEY',
      qualityRank: 4,
    ),
    RemoteProviderConfig(
      provider: RemoteCloudProvider.google,
      envVars: ['GOOGLE_API_KEY', 'GEMINI_API_KEY'],
      displayName: 'Gemini (Google)',
      apiBaseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      defaultModel: 'gemini-2.0-flash',
      apiFormat: ApiFormat.openaiCompatible,
      authHeaderName: 'Authorization',
      authHeaderFormat: r'Bearer $KEY',
      qualityRank: 5,
    ),
    RemoteProviderConfig(
      provider: RemoteCloudProvider.mistral,
      envVars: ['MISTRAL_API_KEY'],
      displayName: 'Mistral AI',
      apiBaseUrl: 'https://api.mistral.ai/v1',
      defaultModel: 'mistral-large-latest',
      apiFormat: ApiFormat.openaiCompatible,
      authHeaderName: 'Authorization',
      authHeaderFormat: r'Bearer $KEY',
      qualityRank: 6,
    ),
    RemoteProviderConfig(
      provider: RemoteCloudProvider.xai,
      envVars: ['XAI_API_KEY'],
      displayName: 'Grok (xAI)',
      apiBaseUrl: 'https://api.x.ai/v1',
      defaultModel: 'grok-3',
      apiFormat: ApiFormat.openaiCompatible,
      authHeaderName: 'Authorization',
      authHeaderFormat: r'Bearer $KEY',
      qualityRank: 7,
    ),
    RemoteProviderConfig(
      provider: RemoteCloudProvider.deepseek,
      envVars: ['DEEPSEEK_API_KEY'],
      displayName: 'DeepSeek',
      apiBaseUrl: 'https://api.deepseek.com/v1',
      defaultModel: 'deepseek-chat',
      apiFormat: ApiFormat.openaiCompatible,
      authHeaderName: 'Authorization',
      authHeaderFormat: r'Bearer $KEY',
      qualityRank: 8,
    ),
    RemoteProviderConfig(
      provider: RemoteCloudProvider.fireworks,
      envVars: ['FIREWORKS_API_KEY'],
      displayName: 'Fireworks AI',
      apiBaseUrl: 'https://api.fireworks.ai/inference/v1',
      defaultModel: 'accounts/fireworks/models/llama-v3p1-70b-instruct',
      apiFormat: ApiFormat.openaiCompatible,
      authHeaderName: 'Authorization',
      authHeaderFormat: r'Bearer $KEY',
      qualityRank: 9,
    ),
    RemoteProviderConfig(
      provider: RemoteCloudProvider.togetherAi,
      envVars: ['TOGETHER_API_KEY'],
      displayName: 'Together AI',
      apiBaseUrl: 'https://api.together.xyz/v1',
      defaultModel: 'meta-llama/Llama-3.3-70B-Instruct-Turbo',
      apiFormat: ApiFormat.openaiCompatible,
      authHeaderName: 'Authorization',
      authHeaderFormat: r'Bearer $KEY',
      qualityRank: 10,
    ),
    RemoteProviderConfig(
      provider: RemoteCloudProvider.cohere,
      envVars: ['COHERE_API_KEY'],
      displayName: 'Cohere',
      apiBaseUrl: 'https://api.cohere.com/v2',
      defaultModel: 'command-r-plus',
      apiFormat: ApiFormat.openaiCompatible,
      authHeaderName: 'Authorization',
      authHeaderFormat: r'Bearer $KEY',
      qualityRank: 11,
    ),
  ];

  /// All environment variable names to check
  static List<String> get allEnvVarNames =>
      providers.expand((p) => p.envVars).toList();

  /// Look up provider config by detected env var name
  static RemoteProviderConfig? forEnvVar(String envVarName) =>
      providers.where((p) => p.envVars.contains(envVarName)).firstOrNull;
}

/// Configuration for a single cloud provider
class RemoteProviderConfig {
  final RemoteCloudProvider provider;
  final List<String> envVars;
  final String displayName;
  final String apiBaseUrl;
  final String defaultModel;
  final ApiFormat apiFormat;
  final String authHeaderName;
  final String authHeaderFormat;
  final int qualityRank;
  final Map<String, String> extraHeaders;

  const RemoteProviderConfig({
    required this.provider,
    required this.envVars,
    required this.displayName,
    required this.apiBaseUrl,
    required this.defaultModel,
    required this.apiFormat,
    required this.authHeaderName,
    required this.authHeaderFormat,
    required this.qualityRank,
    this.extraHeaders = const {},
  });
}

/// API request format
enum ApiFormat {
  /// OpenAI-compatible chat completion format
  /// Used by: OpenAI, Groq, Mistral, xAI, DeepSeek, Fireworks, Together,
  ///          OpenRouter, Cohere, Google (v1beta)
  openaiCompatible,

  /// Anthropic Messages API format
  /// Used by: Anthropic (direct)
  anthropicMessages,
}
```

## Behavior

### Detection Flow

```
GIVEN SSH connection is established to a host
WHEN detect() is called with the SSH session
THEN build a batched shell command checking all known env var names
AND execute via SSH exec
AND parse output to determine which vars are set
AND return list of DetectedCloudProvider sorted by qualityRank

GIVEN the detection command is built
WHEN executed on the remote host
THEN each env var is checked using `test -n "$VAR_NAME"`
AND only the variable NAME is echoed if set (never the value)
AND stderr is suppressed with 2>/dev/null
```

### Login Shell Fallback

```
GIVEN initial detection returns no providers
WHEN the command ran in a non-login shell
THEN retry detection with `bash -l -c '...'` wrapper
AND if that also fails, try `zsh -l -c '...'`
AND cache which shell invocation strategy works per host

GIVEN login shell retry succeeds
WHEN future detections are needed for this host
THEN use the cached shell invocation strategy
```

### Multiple Env Vars for Same Provider

```
GIVEN a provider has multiple possible env vars (e.g., GOOGLE_API_KEY, GEMINI_API_KEY)
WHEN both are detected
THEN only include the provider once in results
AND prefer the first env var listed in the provider config

GIVEN CLAUDE_CODE_OAUTH_TOKEN is detected
WHEN ANTHROPIC_API_KEY is also detected
THEN prefer ANTHROPIC_API_KEY (standard key format)
AND only include Anthropic once
```

### Error Handling

```
GIVEN SSH exec fails or times out
WHEN detection is attempted
THEN return empty list (no providers detected)
AND do not throw — detection is best-effort

GIVEN remote shell does not support `test` builtin
WHEN command fails
THEN fallback is empty result (extremely unlikely, test is POSIX)
```

## Detection Command Implementation

```dart
class EnvProviderDetector {
  const EnvProviderDetector();

  Future<List<DetectedCloudProvider>> detect(SshSession session) async {
    final allVars = RemoteProviderRegistry.allEnvVarNames;

    // Build batched check command
    final checks = allVars
        .map((v) => '(test -n "\$$v" && echo "$v") 2>/dev/null')
        .join('\n');
    final command = '$checks\necho "---ENV_CHECK_DONE---"';

    try {
      final result = await session.execute(command)
          .timeout(const Duration(seconds: 5));

      if (result.exitCode != 0 && !result.stdout.contains('---ENV_CHECK_DONE---')) {
        // Command failed — try login shell fallback
        return _detectWithLoginShell(session, command);
      }

      return _parseDetectionOutput(result.stdout);
    } on TimeoutException {
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<DetectedCloudProvider>> _detectWithLoginShell(
    SshSession session,
    String command,
  ) async {
    // Try bash -l first, then zsh -l
    for (final shell in ['bash', 'zsh']) {
      try {
        final result = await session.execute(
          '$shell -l -c ${_shellEscape(command)}',
        ).timeout(const Duration(seconds: 5));

        if (result.stdout.contains('---ENV_CHECK_DONE---')) {
          return _parseDetectionOutput(result.stdout);
        }
      } catch (_) {
        continue;
      }
    }
    return [];
  }

  List<DetectedCloudProvider> _parseDetectionOutput(String stdout) {
    final lines = stdout
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l != '---ENV_CHECK_DONE---')
        .toList();

    final detected = <RemoteCloudProvider, DetectedCloudProvider>{};

    for (final varName in lines) {
      final config = RemoteProviderRegistry.forEnvVar(varName);
      if (config != null && !detected.containsKey(config.provider)) {
        detected[config.provider] = DetectedCloudProvider(
          provider: config.provider,
          envVarName: varName,
          displayName: config.displayName,
          defaultModel: config.defaultModel,
          qualityRank: config.qualityRank,
        );
      }
    }

    final results = detected.values.toList()
      ..sort((a, b) => a.qualityRank.compareTo(b.qualityRank));

    return results;
  }
}
```

## Security Considerations

- **Never read key values**: Only `test -n` to check existence
- **No env dump**: Never run `env`, `printenv`, or `set` commands
- **Curated list only**: Only check variables in `RemoteProviderRegistry`
- **Keys stay remote**: During API calls, `$VAR_NAME` is expanded by the remote
  shell — Bento never sees the actual key value
- **Stderr suppressed**: `2>/dev/null` prevents any error leakage
- **No persistence of key material**: Detection results only contain provider
  names and env var names, never key values

## Performance Considerations

- Single SSH exec for all env var checks (~50ms on typical connection)
- No additional round trips beyond the one batched command
- Timeout at 5 seconds prevents hanging on slow connections
- Results cached by RemoteAiDetector (parent component)
