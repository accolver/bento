// @telos L1:function:lib/features/ai/domain/entities:remote_ai_detection

import 'ollama_model.dart';
import 'remote_ai_provider.dart';

/// Result of detecting a single cloud provider on a remote host.
///
/// Created when an environment variable is found indicating that
/// the remote machine has a cloud AI provider configured.
class DetectedCloudProvider {
  const DetectedCloudProvider({
    required this.provider,
    required this.envVarName,
    required this.displayName,
    required this.defaultModel,
    required this.qualityRank,
  });

  /// Which provider was detected.
  final RemoteCloudProvider provider;

  /// Which environment variable was found (e.g., "ANTHROPIC_API_KEY").
  final String envVarName;

  /// Human-readable name for UI display.
  final String displayName;

  /// Default model for this provider.
  final String defaultModel;

  /// Quality ranking (1 = best). Used for sorting recommendations.
  final int qualityRank;

  @override
  String toString() => 'DetectedCloudProvider($displayName via $envVarName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetectedCloudProvider &&
          runtimeType == other.runtimeType &&
          provider == other.provider &&
          envVarName == other.envVarName;

  @override
  int get hashCode => Object.hash(provider, envVarName);
}

/// Combined result of all AI detection on a remote host.
///
/// Contains both Ollama models and cloud providers detected during
/// the unified detection pass after SSH connection.
class RemoteAiDetectionResult {
  const RemoteAiDetectionResult({
    required this.hostId,
    this.ollamaModels = const [],
    this.cloudProviders = const [],
    required this.checkedAt,
    this.detectionMethod = RemoteDetectionMethod.direct,
  });

  /// SSH host identifier this result applies to.
  final String hostId;

  /// Ollama models found on the remote host (empty if Ollama not running).
  final List<OllamaModel> ollamaModels;

  /// Cloud providers detected via environment variables.
  final List<DetectedCloudProvider> cloudProviders;

  /// When this detection was performed.
  final DateTime checkedAt;

  /// How the env vars were detected (direct shell or login shell fallback).
  final RemoteDetectionMethod detectionMethod;

  /// Whether any AI provider was detected (Ollama or cloud).
  bool get hasAnyProvider =>
      ollamaModels.isNotEmpty || cloudProviders.isNotEmpty;

  /// Whether Ollama was detected with at least one model.
  bool get hasOllama => ollamaModels.isNotEmpty;

  /// Whether any cloud providers were detected.
  bool get hasCloudProviders => cloudProviders.isNotEmpty;

  /// Total number of detected providers (Ollama counts as 1 if present).
  int get providerCount => (hasOllama ? 1 : 0) + cloudProviders.length;

  /// The best recommended provider based on quality ranking.
  ///
  /// Returns the cloud provider with the lowest qualityRank, or null
  /// if only Ollama is available (Ollama is always lower priority than
  /// cloud providers for auto-recommendation).
  DetectedCloudProvider? get bestCloudProvider =>
      cloudProviders.isNotEmpty ? cloudProviders.first : null;

  /// Whether this result is stale (older than 5 minutes).
  bool get isStale =>
      DateTime.now().difference(checkedAt) > const Duration(minutes: 5);

  /// Creates an empty result (nothing detected).
  factory RemoteAiDetectionResult.empty(String hostId) =>
      RemoteAiDetectionResult(
        hostId: hostId,
        checkedAt: DateTime.now(),
      );

  @override
  String toString() => 'RemoteAiDetectionResult(hostId: $hostId, '
      'ollama: ${ollamaModels.length} models, '
      'cloud: ${cloudProviders.length} providers)';
}

/// How environment variables were detected on the remote host.
enum RemoteDetectionMethod {
  /// Direct `test -n` in the default shell.
  direct,

  /// Required `bash -l -c` login shell fallback.
  bashLogin,

  /// Required `zsh -l -c` login shell fallback.
  zshLogin,

  /// Required `bash -li -c` interactive login shell fallback.
  ///
  /// Needed when env vars are set in `~/.bashrc` (sourced only for
  /// interactive shells, not login-only shells).
  bashInteractiveLogin,

  /// Required `zsh -li -c` interactive login shell fallback.
  ///
  /// Needed when env vars are set in `~/.zshrc` (sourced only for
  /// interactive shells, not login-only shells). Common on macOS.
  zshInteractiveLogin,
}

/// Events emitted by the remote AI detection system.
sealed class RemoteAiDetectionEvent {
  const RemoteAiDetectionEvent({required this.hostId});

  /// SSH host this event relates to.
  final String hostId;
}

/// Emitted when AI providers are detected on a remote host.
class RemoteAiDetectedEvent extends RemoteAiDetectionEvent {
  const RemoteAiDetectedEvent({
    required super.hostId,
    required this.result,
  });

  /// Full detection result with all found providers.
  final RemoteAiDetectionResult result;

  @override
  String toString() =>
      'RemoteAiDetectedEvent(${result.providerCount} providers on $hostId)';
}

/// Emitted when no AI providers are found on a remote host.
class RemoteAiNotFoundEvent extends RemoteAiDetectionEvent {
  const RemoteAiNotFoundEvent({
    required super.hostId,
    this.reason,
  });

  /// Optional reason why detection failed (e.g., "timeout", "no env vars").
  final String? reason;

  @override
  String toString() => 'RemoteAiNotFoundEvent($hostId: $reason)';
}
