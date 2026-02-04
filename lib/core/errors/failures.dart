// @telos L1:function:lib/core/errors:failures

import 'package:equatable/equatable.dart';

/// Base class for all failures in the application.
///
/// Uses [Equatable] for value equality comparison.
/// Failures represent expected error conditions that should be handled gracefully.
abstract class Failure extends Equatable {
  const Failure({this.message, this.code});

  /// Human-readable error message
  final String? message;

  /// Optional error code for programmatic handling
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

/// Failure when a server/API request fails.
class ServerFailure extends Failure {
  const ServerFailure({super.message, super.code, this.statusCode});

  /// HTTP status code if available
  final int? statusCode;

  @override
  List<Object?> get props => [message, code, statusCode];
}

/// Failure when network is unavailable or request times out.
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Network unavailable',
    super.code = 'NETWORK_ERROR',
  });
}

/// Failure when reading from or writing to cache.
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Cache operation failed',
    super.code = 'CACHE_ERROR',
  });
}

/// Failure when input validation fails.
class ValidationFailure extends Failure {
  const ValidationFailure({
    required String super.message,
    super.code = 'VALIDATION_ERROR',
    this.field,
  });

  /// The field that failed validation, if applicable
  final String? field;

  @override
  List<Object?> get props => [message, code, field];
}

/// Failure for SSH connection errors.
class ConnectionFailure extends Failure {
  const ConnectionFailure({
    super.message = 'Connection failed',
    super.code = 'CONNECTION_ERROR',
    this.host,
    this.port,
  });

  /// The host that failed to connect
  final String? host;

  /// The port that was attempted
  final int? port;

  @override
  List<Object?> get props => [message, code, host, port];
}

/// Failure for authentication errors.
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    super.message = 'Authentication failed',
    super.code = 'AUTH_ERROR',
  });
}

/// Failure when a resource is not found.
class NotFoundFailure extends Failure {
  const NotFoundFailure({
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
  List<Object?> get props => [message, code, resourceType, resourceId];
}

/// Failure for unknown or unexpected errors.
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred',
    super.code = 'UNKNOWN_ERROR',
    this.originalError,
  });

  /// The original error/exception if available
  final Object? originalError;

  @override
  List<Object?> get props => [message, code, originalError];
}
