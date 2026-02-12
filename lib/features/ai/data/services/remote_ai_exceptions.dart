// @telos L1:function:lib/features/ai/data/services:remote_ai_exceptions

import '../../domain/services/ai_service.dart';

/// Thrown when an operation is attempted on a disconnected SSH session.
class RemoteDisconnectedException extends AiServiceException {
  /// Creates a disconnection exception with an optional custom [message].
  const RemoteDisconnectedException([
    String message = 'SSH connection lost. Reconnect to use remote AI.',
  ]) : super(
          message,
          code: 'remote_disconnected',
          isRetryable: true,
        );
}

/// Thrown when a remote command execution fails.
class RemoteExecutionException extends AiServiceException {
  /// Creates an execution exception with the error [message],
  /// optional [exitCode], and optional [stderr] output.
  const RemoteExecutionException(
    super.message, {
    this.exitCode,
    this.stderr,
  }) : super(
          code: 'remote_exec_failed',
          isRetryable: true,
        );

  /// Exit code of the remote command.
  final int? exitCode;

  /// Standard error output from the command.
  final String? stderr;
}

/// Thrown when the remote response cannot be parsed.
class RemoteParseException extends AiServiceException {
  /// Creates a parse exception with the error [message]
  /// and optional [rawResponse] snippet for debugging.
  const RemoteParseException(
    super.message, {
    this.rawResponse,
  }) : super(
          code: 'parse_error',
        );

  /// The raw response that couldn't be parsed.
  final String? rawResponse;
}

/// Thrown when a cloud provider returns an API error.
class RemoteApiException extends AiServiceException {
  /// Creates an API exception with the error [message],
  /// optional [providerName], and optional HTTP [statusCode].
  const RemoteApiException(
    super.message, {
    this.providerName,
    this.statusCode,
  }) : super(
          code: 'api_error',
          isRetryable: false,
        );

  /// The name of the provider that returned the error.
  final String? providerName;

  /// HTTP status code from the provider.
  final int? statusCode;
}

/// Thrown when curl is not found on the remote host.
class CurlNotFoundException extends AiServiceException {
  /// Creates a curl-not-found exception with an optional custom [message].
  const CurlNotFoundException([
    String message = 'curl is not installed on the remote host. '
        'Install curl to use remote AI.',
  ]) : super(
          message,
          code: 'curl_not_found',
        );
}

/// Thrown when the API rate limit is exceeded.
class RateLimitException extends AiServiceException {
  /// Creates a rate-limit exception with the error [message],
  /// optional [retryAfterSeconds], and optional [providerName].
  const RateLimitException(
    super.message, {
    this.retryAfterSeconds,
    this.providerName,
  }) : super(
          code: 'rate_limit',
          isRetryable: true,
        );

  /// How many seconds to wait before retrying.
  final int? retryAfterSeconds;

  /// The provider that rate-limited the request.
  final String? providerName;
}
