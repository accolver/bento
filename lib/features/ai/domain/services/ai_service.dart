// @telos L2:contract:lib/features/ai/domain/services:ai_service

import '../entities/ai_privacy_mode.dart';
import '../entities/ai_suggestion.dart';

/// Abstract interface for AI command generation services.
///
/// All AI providers (local, cloud, remote, mock) implement this interface,
/// allowing the application to use any provider interchangeably.
///
/// Implementations:
/// - [MockAiService]: Keyword-based matching for testing/fallback
/// - LocalAiService: On-device inference via flutter_llama
/// - CloudAiService: OpenRouter API for cloud models
/// - RemoteAiService: Ollama via SSH connection
abstract class AiService {
  /// Generate a command suggestion from natural language input.
  ///
  /// [prompt] - The user's natural language description of what they want.
  /// Returns an [AiSuggestion] with the command, explanation, and confidence.
  /// Throws [AiServiceException] if generation fails.
  Future<AiSuggestion> generateCommand(String prompt);

  /// Generate with streaming for real-time token display.
  ///
  /// Yields [AiStreamEvent]s as tokens are generated.
  /// The stream ends with either [AiStreamComplete] or [AiStreamError].
  ///
  /// For services that don't natively support streaming (like mock),
  /// this can simulate streaming by yielding tokens character by character.
  Stream<AiStreamEvent> generateCommandStream(String prompt);

  /// Check if the service is currently available and ready.
  ///
  /// For local: model is loaded
  /// For cloud: network available and API key valid
  /// For remote: SSH connected and Ollama responding
  /// For mock: always true
  Future<bool> isAvailable();

  /// Get the privacy mode indicator for UI display.
  ///
  /// - [AiPrivacyMode.local]: Data stays on device (local, remote on user's server)
  /// - [AiPrivacyMode.cloud]: Data sent to external servers
  AiPrivacyMode get privacyMode;

  /// Human-readable name for this service (for settings/debug).
  ///
  /// Examples: "Mock AI", "Local (TinyLlama)", "Cloud (Claude)", "Remote (Ollama)"
  String get serviceName;

  /// Dispose of resources held by this service.
  ///
  /// For local: unload model from memory
  /// For cloud: cancel pending requests
  /// For remote: close connections
  /// For mock: no-op
  Future<void> dispose();
}

/// Events emitted during streaming generation.
///
/// The stream will yield:
/// 1. Zero or more [AiStreamToken] events as tokens are generated
/// 2. Exactly one terminal event: [AiStreamComplete] or [AiStreamError]
sealed class AiStreamEvent {
  const AiStreamEvent();
}

/// A partial token was generated.
///
/// These are yielded as the AI generates output, allowing the UI
/// to display real-time progress.
class AiStreamToken extends AiStreamEvent {
  const AiStreamToken(this.token);

  /// The token text (may be a single character, word, or fragment).
  final String token;

  @override
  String toString() => 'AiStreamToken($token)';
}

/// Generation completed successfully.
///
/// Contains the final [AiSuggestion] with the complete command,
/// explanation, and confidence score.
class AiStreamComplete extends AiStreamEvent {
  const AiStreamComplete(this.suggestion);

  /// The final AI suggestion.
  final AiSuggestion suggestion;

  @override
  String toString() => 'AiStreamComplete(${suggestion.command})';
}

/// An error occurred during generation.
///
/// The stream will end after this event is yielded.
class AiStreamError extends AiStreamEvent {
  const AiStreamError(this.message, {this.code, this.originalError});

  /// Human-readable error message.
  final String message;

  /// Optional error code for programmatic handling.
  final String? code;

  /// The original exception, if any.
  final dynamic originalError;

  @override
  String toString() => 'AiStreamError($message)';
}

/// Exception thrown by AI services.
///
/// Wraps underlying errors with a consistent interface for the UI layer.
class AiServiceException implements Exception {
  const AiServiceException(
    this.message, {
    this.code,
    this.originalError,
    this.isRetryable = false,
  });

  /// Human-readable error message suitable for display.
  final String message;

  /// Error code for programmatic handling.
  ///
  /// Standard codes:
  /// - `unavailable`: Service not available (no model, no API key, etc.)
  /// - `network`: Network error (timeout, connection refused)
  /// - `rate_limit`: Rate limited by provider
  /// - `invalid_key`: API key is invalid or expired
  /// - `generation_failed`: Generation failed for unknown reason
  final String? code;

  /// The original exception that caused this error.
  final dynamic originalError;

  /// Whether this error might succeed on retry.
  ///
  /// True for transient errors like network timeouts.
  /// False for permanent errors like invalid API key.
  final bool isRetryable;

  @override
  String toString() => 'AiServiceException: $message';
}
