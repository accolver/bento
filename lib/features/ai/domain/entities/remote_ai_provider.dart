// @telos L1:function:lib/features/ai/domain/entities:remote_ai_provider

/// Known AI providers detectable via environment variables on remote hosts.
///
/// Each provider maps to one or more environment variable names that
/// indicate the user has configured API access to that provider.
enum RemoteCloudProvider {
  /// Claude Code — OAuth-based Anthropic access via installed CLI
  claudeCode,

  /// Anthropic — Claude models, best reasoning for terminal commands
  anthropic,

  /// OpenAI — GPT-4o and other models
  openai,

  /// OpenRouter — unified API gateway for 500+ models
  openRouter,

  /// Groq — high-speed inference hardware
  groq,

  /// Google — Gemini models
  google,

  /// Mistral AI — European AI provider
  mistral,

  /// xAI — Grok models
  xai,

  /// DeepSeek — Chinese AI lab
  deepseek,

  /// Fireworks AI — fast inference platform
  fireworks,

  /// Together AI — open-source model hosting
  togetherAi,

  /// Cohere — enterprise NLP
  cohere,
}

/// API request format used by a provider.
///
/// Most providers use the OpenAI-compatible chat completion format.
/// Anthropic is the notable exception with its own Messages API.
enum ApiFormat {
  /// OpenAI-compatible chat completion format.
  ///
  /// Used by: OpenAI, Groq, Mistral, xAI, DeepSeek, Fireworks, Together,
  /// OpenRouter, Cohere, Google (v1beta)
  ///
  /// Endpoint pattern: `{base}/chat/completions`
  /// Body: `{ "model": "...", "messages": [...], "stream": bool }`
  openaiCompatible,

  /// Anthropic Messages API format.
  ///
  /// Used by: Anthropic (direct API)
  ///
  /// Endpoint: `{base}/v1/messages`
  /// Body: `{ "model": "...", "system": "...", "messages": [...], "max_tokens": int }`
  anthropicMessages,
}

/// Configuration for a known cloud AI provider.
///
/// Contains all metadata needed to detect the provider's presence on a
/// remote host and to build API requests through SSH proxy.
class RemoteProviderConfig {
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

  /// Which provider this config represents.
  final RemoteCloudProvider provider;

  /// Environment variable names that indicate this provider is configured.
  ///
  /// Multiple vars may map to the same provider (e.g., GOOGLE_API_KEY and
  /// GEMINI_API_KEY both indicate Google Gemini access).
  /// The first var in the list is preferred when multiple are detected.
  final List<String> envVars;

  /// Human-readable name for UI display (e.g., "Claude (Anthropic)").
  final String displayName;

  /// Base URL for the provider's API.
  final String apiBaseUrl;

  /// Default model to use when no specific model is selected.
  final String defaultModel;

  /// API format (OpenAI-compatible or Anthropic Messages).
  final ApiFormat apiFormat;

  /// Name of the HTTP header used for authentication.
  final String authHeaderName;

  /// Format string for the auth header value.
  ///
  /// Use `\$KEY` as a placeholder — it will be replaced with the
  /// shell variable reference (e.g., `\$ANTHROPIC_API_KEY`) so the
  /// actual key value is expanded by the remote shell, never by Bento.
  final String authHeaderFormat;

  /// Quality ranking for auto-recommendation (1 = best).
  ///
  /// When multiple providers are detected, the one with the lowest
  /// qualityRank is recommended first.
  final int qualityRank;

  /// Additional HTTP headers required by this provider.
  ///
  /// Example: Anthropic requires `anthropic-version: 2023-06-01`.
  final Map<String, String> extraHeaders;
}

/// Static registry of all known AI providers and their configurations.
///
/// This is the single source of truth for:
/// - Which environment variables to check on remote hosts
/// - How to build API requests for each provider
/// - Provider ranking for recommendations
class RemoteProviderRegistry {
  RemoteProviderRegistry._();

  /// All known provider configurations, ordered by quality rank.
  static const List<RemoteProviderConfig> providers = [
    // Rank 0: Claude Code — detected via ~/.claude/.credentials file, not env vars
    RemoteProviderConfig(
      provider: RemoteCloudProvider.claudeCode,
      envVars: [],
      displayName: 'Claude Code',
      apiBaseUrl: 'https://api.anthropic.com',
      defaultModel: 'claude-sonnet-4-5-20250514',
      apiFormat: ApiFormat.anthropicMessages,
      authHeaderName: 'Authorization',
      authHeaderFormat: r'Bearer $KEY',
      qualityRank: 0,
    ),
    // Rank 1: Anthropic — best reasoning for terminal commands
    RemoteProviderConfig(
      provider: RemoteCloudProvider.anthropic,
      // NOTE: CLAUDE_CODE_OAUTH_TOKEN was intentionally removed. It uses
      // Authorization: Bearer format, but Anthropic's API requires x-api-key.
      // Mixing them would send the wrong auth header format.
      envVars: ['ANTHROPIC_API_KEY'],
      displayName: 'Claude (Anthropic)',
      apiBaseUrl: 'https://api.anthropic.com',
      defaultModel: 'claude-sonnet-4-20250514',
      apiFormat: ApiFormat.anthropicMessages,
      authHeaderName: 'x-api-key',
      authHeaderFormat: r'$KEY',
      qualityRank: 1,
      extraHeaders: {
        'anthropic-version': '2023-06-01',
      },
    ),
    // Rank 2: OpenAI — strong general purpose
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
    // Rank 3: OpenRouter — unified gateway, likely good models
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
    // Rank 4: Groq — very fast inference
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
    // Rank 5: Google Gemini — good and free tier available
    RemoteProviderConfig(
      provider: RemoteCloudProvider.google,
      envVars: ['GOOGLE_API_KEY', 'GEMINI_API_KEY'],
      displayName: 'Gemini (Google)',
      apiBaseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
      defaultModel: 'gemini-2.0-flash',
      apiFormat: ApiFormat.openaiCompatible,
      authHeaderName: 'Authorization',
      authHeaderFormat: r'Bearer $KEY',
      qualityRank: 5,
    ),
    // Rank 6: Mistral AI
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
    // Rank 7: xAI — Grok models
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
    // Rank 8: DeepSeek
    RemoteProviderConfig(
      provider: RemoteCloudProvider.deepseek,
      envVars: ['DEEPSEEK_API_KEY'],
      displayName: 'DeepSeek',
      apiBaseUrl: 'https://api.deepseek.com',
      defaultModel: 'deepseek-chat',
      apiFormat: ApiFormat.openaiCompatible,
      authHeaderName: 'Authorization',
      authHeaderFormat: r'Bearer $KEY',
      qualityRank: 8,
    ),
    // Rank 9: Fireworks AI
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
    // Rank 10: Together AI
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
    // Rank 11: Cohere
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

  /// All environment variable names to check on remote hosts.
  ///
  /// This is the exhaustive list of variables that Bento will probe for.
  /// No other variables are ever read or checked.
  static List<String> get allEnvVarNames =>
      providers.expand((p) => p.envVars).toList();

  /// Look up provider config by detected env var name.
  ///
  /// Returns null if the variable name is not in the registry.
  static RemoteProviderConfig? forEnvVar(String envVarName) {
    for (final config in providers) {
      if (config.envVars.contains(envVarName)) {
        return config;
      }
    }
    return null;
  }

  /// Look up provider config by provider enum value.
  static RemoteProviderConfig? forProvider(RemoteCloudProvider provider) {
    for (final config in providers) {
      if (config.provider == provider) {
        return config;
      }
    }
    return null;
  }
}
