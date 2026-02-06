// @telos L1:function:lib/features/ai/domain/entities:ai_config

import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_config.freezed.dart';

/// AI operation mode.
///
/// Determines which AI service implementation will be used.
enum AiMode {
  /// Not configured - use mock/keyword matching.
  ///
  /// This is the default state when the user hasn't completed
  /// the AI setup wizard.
  unconfigured,

  /// On-device inference with flutter_llama.
  ///
  /// Data never leaves the device. Requires model download.
  local,

  /// Cloud API via OpenRouter.
  ///
  /// Sends prompts to external servers. Requires API key.
  cloud,

  /// Remote Ollama on SSH-connected server.
  ///
  /// Uses AI running on a server the user is connected to via SSH.
  /// Data stays on user's infrastructure.
  remote,
}

/// Cloud AI provider (via OpenRouter).
///
/// Each maps to a specific OpenRouter model ID.
enum CloudAiProvider {
  /// Anthropic Claude 3.5 Sonnet - best reasoning
  claude('anthropic/claude-3.5-sonnet'),

  /// OpenAI GPT-4o Mini - fast and cheap
  gpt4oMini('openai/gpt-4o-mini'),

  /// Meta Llama 3.1 70B - open source
  llama3('meta-llama/llama-3.1-70b-instruct'),

  /// Google Gemini 2.0 Flash - very fast
  gemini('google/gemini-2.0-flash');

  const CloudAiProvider(this.modelId);

  /// The OpenRouter model ID for this provider.
  final String modelId;
}

/// Main AI configuration.
///
/// Stores user preferences for AI behavior including mode,
/// provider settings, and feature flags.
@freezed
class AiConfig with _$AiConfig {
  const factory AiConfig({
    /// The current AI mode.
    required AiMode mode,

    // Local AI settings
    /// ID of the selected local model.
    String? localModelId,

    /// Path to the downloaded model file.
    String? localModelPath,

    // Cloud AI settings
    /// Selected cloud provider.
    CloudAiProvider? cloudProvider,
    // Note: API key stored separately in secure storage

    // Remote AI settings
    /// Whether to auto-detect Ollama on SSH connections.
    @Default(true) bool remoteAutoDetect,

    /// Selected remote model name (e.g., "llama3:8b").
    String? remoteModelName,

    // General settings
    /// Whether to show the privacy indicator in the UI.
    @Default(true) bool showPrivacyIndicator,

    // Timestamps
    /// When the configuration was first set up.
    DateTime? configuredAt,

    /// When AI was last used.
    DateTime? lastUsedAt,
  }) = _AiConfig;

  const AiConfig._();

  /// Creates an unconfigured (default) configuration.
  factory AiConfig.unconfigured() => const AiConfig(mode: AiMode.unconfigured);

  /// Whether AI is configured and ready to use.
  bool get isConfigured => mode != AiMode.unconfigured;

  /// Whether the current mode is privacy-preserving (data stays local/on user's server).
  bool get isPrivate => mode == AiMode.local || mode == AiMode.remote;
}
