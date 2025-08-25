/// Standardized error classes for consistent error handling across the application
abstract class AppError {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppError({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'AppError: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

/// Network-related errors (API calls, connectivity issues)
class NetworkError extends AppError {
  final int? statusCode;

  const NetworkError({
    required super.message,
    this.statusCode,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    return 'NetworkError: $message${statusCode != null ? ' (Status: $statusCode)' : ''}${code != null ? ' (Code: $code)' : ''}';
  }
}

/// Authentication and authorization errors
class AuthError extends AppError {
  final bool isTokenExpired;

  const AuthError({
    required super.message,
    this.isTokenExpired = false,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    return 'AuthError: $message${code != null ? ' (Code: $code)' : ''}${isTokenExpired ? ' (Token Expired)' : ''}';
  }
}

/// Validation errors for user input
class ValidationError extends AppError {
  final Map<String, List<String>>? fieldErrors;

  const ValidationError({
    required super.message,
    this.fieldErrors,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    return 'ValidationError: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

/// Generic application errors
class GenericError extends AppError {
  const GenericError(
      {required super.message,
      super.code,
      super.originalError,
      super.stackTrace});
}

/// Business logic errors
class BusinessError extends AppError {
  const BusinessError(
      {required super.message,
      super.code,
      super.originalError,
      super.stackTrace});
}

/// Storage-related errors
class StorageError extends AppError {
  const StorageError(
      {required super.message,
      super.code,
      super.originalError,
      super.stackTrace});
}