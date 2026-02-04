// @telos L1:function:lib/core/errors:exceptions

/// Base class for all exceptions in the application.
///
/// Exceptions are used for unexpected error conditions that may require
/// special handling or logging. They should be caught and converted to
/// [Failure] types at repository boundaries.
abstract class AppException implements Exception {
  const AppException({this.message, this.code});

  /// Human-readable error message
  final String? message;

  /// Optional error code for programmatic handling
  final String? code;

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Exception when a server/API request fails.
class ServerException extends AppException {
  const ServerException({
    super.message,
    super.code,
    this.statusCode,
    this.response,
  });

  /// HTTP status code if available
  final int? statusCode;

  /// Raw response body if available
  final dynamic response;

  @override
  String toString() =>
      'ServerException: $message (status: $statusCode, code: $code)';
}

/// Exception when network is unavailable or request times out.
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Network unavailable',
    super.code = 'NETWORK_ERROR',
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception when reading from or writing to cache.
class CacheException extends AppException {
  const CacheException({
    super.message = 'Cache operation failed',
    super.code = 'CACHE_ERROR',
  });

  @override
  String toString() => 'CacheException: $message';
}

/// Exception when input validation fails.
class ValidationException extends AppException {
  const ValidationException({
    required String super.message,
    super.code = 'VALIDATION_ERROR',
    this.field,
    this.value,
  });

  /// The field that failed validation
  final String? field;

  /// The value that was invalid
  final dynamic value;

  @override
  String toString() => 'ValidationException: $message (field: $field)';
}

/// Exception for SSH/terminal connection errors.
class ConnectionException extends AppException {
  const ConnectionException({
    super.message = 'Connection failed',
    super.code = 'CONNECTION_ERROR',
    this.host,
    this.port,
    this.originalError,
  });

  /// The host that failed to connect
  final String? host;

  /// The port that was attempted
  final int? port;

  /// Original exception from SSH library
  final Object? originalError;

  @override
  String toString() => 'ConnectionException: $message (host: $host:$port)';
}

/// Exception for authentication errors.
class AuthenticationException extends AppException {
  const AuthenticationException({
    super.message = 'Authentication failed',
    super.code = 'AUTH_ERROR',
  });

  @override
  String toString() => 'AuthenticationException: $message';
}

/// Exception when a resource is not found.
class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Resource not found',
    super.code = 'NOT_FOUND',
    this.resourceType,
    this.resourceId,
  });

  /// Type of resource that was not found
  final String? resourceType;

  /// ID of the resource that was not found
  final String? resourceId;

  @override
  String toString() =>
      'NotFoundException: $message (type: $resourceType, id: $resourceId)';
}
