// @telos L1:function:lib/features/ai/domain/entities:remote_ai_config

import 'package:freezed_annotation/freezed_annotation.dart';

import 'remote_ai_provider.dart';

part 'remote_ai_config.freezed.dart';

/// Type of remote AI backend.
enum RemoteBackendType {
  /// Ollama running locally on the remote host.
  ///
  /// Uses localhost:11434 API. Data never leaves the remote server.
  ollama,

  /// Cloud provider accessed via SSH-proxied API calls.
  ///
  /// API calls are executed on the remote host using its env var API keys.
  /// Keys never transit to Bento — expanded by the remote shell.
  cloudProxy,

  /// Claude Code CLI detected on the remote host.
  ///
  /// Uses OAuth credentials from `~/.claude/.credentials` to proxy
  /// Anthropic API calls through the remote host. Tokens are key-opaque.
  claudeCode,
}

/// Per-host remote AI configuration.
///
/// Stores the user's AI provider preference for a specific SSH host.
/// This allows different providers for different machines (e.g.,
/// Claude on dev machine, Ollama on GPU server).
@freezed
class RemoteAiConfig with _$RemoteAiConfig {
  const factory RemoteAiConfig({
    /// SSH host identifier this config applies to.
    required String hostId,

    /// Which backend type is selected.
    required RemoteBackendType backendType,

    /// For Ollama: selected model name (e.g., "llama3:8b").
    String? ollamaModel,

    /// For cloud proxy: which provider is selected.
    RemoteCloudProvider? cloudProvider,

    /// For cloud proxy: which env var to use for the API key.
    ///
    /// This is the variable name (e.g., "ANTHROPIC_API_KEY"),
    /// never the actual key value.
    String? envVarName,

    /// Ollama port (default 11434).
    @Default(11434) int ollamaPort,
  }) = _RemoteAiConfig;

  const RemoteAiConfig._();

  /// Whether this config has enough information to create a backend.
  bool get isValid {
    switch (backendType) {
      case RemoteBackendType.ollama:
        return ollamaModel != null;
      case RemoteBackendType.cloudProxy:
        return cloudProvider != null && envVarName != null;
      case RemoteBackendType.claudeCode:
        return true; // No additional config needed
    }
  }

  /// Creates a config for an Ollama backend.
  factory RemoteAiConfig.ollama({
    required String hostId,
    required String model,
    int port = 11434,
  }) =>
      RemoteAiConfig(
        hostId: hostId,
        backendType: RemoteBackendType.ollama,
        ollamaModel: model,
        ollamaPort: port,
      );

  /// Creates a config for a cloud proxy backend.
  factory RemoteAiConfig.cloudProxy({
    required String hostId,
    required RemoteCloudProvider provider,
    required String envVarName,
  }) =>
      RemoteAiConfig(
        hostId: hostId,
        backendType: RemoteBackendType.cloudProxy,
        cloudProvider: provider,
        envVarName: envVarName,
      );

  /// Creates a config for a Claude Code backend.
  factory RemoteAiConfig.claudeCode({
    required String hostId,
  }) =>
      RemoteAiConfig(
        hostId: hostId,
        backendType: RemoteBackendType.claudeCode,
      );
}
