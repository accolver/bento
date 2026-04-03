// @telos L2:contract:service-ai-gateway

/// Spec-aligned failure used by AI command-assistance usecases.
class AIFailure {
  const AIFailure._(this.type, this.message);

  const AIFailure.invalidInput(String message)
      : this._(AIFailureType.invalidInput, message);

  const AIFailure.providerUnavailable()
      : this._(AIFailureType.providerUnavailable, 'AI provider unavailable');

  const AIFailure.modelNotLoaded()
      : this._(AIFailureType.modelNotLoaded, 'AI model not loaded');

  const AIFailure.networkError(String message)
      : this._(AIFailureType.networkError, message);

  const AIFailure.rateLimited()
      : this._(AIFailureType.rateLimited, 'AI provider is rate limited');

  const AIFailure.inferenceError(String message)
      : this._(AIFailureType.inferenceError, message);

  final AIFailureType type;
  final String message;

  @override
  bool operator ==(Object other) {
    return other is AIFailure &&
        other.type == type &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(type, message);

  @override
  String toString() => 'AIFailure(type: $type, message: $message)';
}

enum AIFailureType {
  invalidInput,
  providerUnavailable,
  modelNotLoaded,
  networkError,
  rateLimited,
  inferenceError,
}
