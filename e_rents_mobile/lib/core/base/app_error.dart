import 'dart:io';
import 'package:http/http.dart' as http;

/// Enum representing different types of errors that can occur in the application
enum ErrorType {
  /// Network-related errors (connection issues, timeouts, etc.)
  network,

  /// Authentication and authorization errors
  authentication,

  /// Data validation errors
  validation,

  /// Resource not found errors
  notFound,

  /// Server-side errors (5xx status codes)
  server,

  /// Cache-related errors
  cache,

  /// Permission-related errors
  permission,

  /// Unknown or unhandled errors
  unknown,
}

/// Structured error class that provides consistent error handling across the application
class AppError {
  /// The type of error that occurred
  final ErrorType type;

  /// Human-readable error message
  final String message;

  /// Additional technical details about the error
  final String? details;

  /// HTTP status code if applicable
  final int? statusCode;

  /// Timestamp when the error occurred
  final DateTime timestamp;

  /// Stack trace for debugging
  final StackTrace? stackTrace;

  /// Original exception that caused this error
  final Object? originalException;

  AppError({
    required this.type,
    required this.message,
    this.details,
    this.statusCode,
    DateTime? timestamp,
    this.stackTrace,
    this.originalException,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create AppError from an HTTP response
  factory AppError.fromHttpResponse(http.Response response, {String? details}) {
    final statusCode = response.statusCode;
    final errorType = _getErrorTypeFromStatusCode(statusCode);
    
    return AppError(
      type: errorType,
      message: _getMessageFromStatusCode(statusCode),
      details: details ?? response.body,
      statusCode: statusCode,
    );
  }

  /// Create AppError from a generic exception
  factory AppError.fromException(Object exception, {StackTrace? stackTrace}) {
    if (exception is SocketException) {
      return AppError(
        type: ErrorType.network,
        message: 'Network connection failed',
        details: exception.message,
        stackTrace: stackTrace,
        originalException: exception,
      );
    }

    if (exception is FormatException) {
      return AppError(
        type: ErrorType.validation,
        message: 'Invalid data format',
        details: exception.message,
        stackTrace: stackTrace,
        originalException: exception,
      );
    }

    return AppError(
      type: ErrorType.unknown,
      message: 'An unexpected error occurred',
      details: exception.toString(),
      stackTrace: stackTrace,
      originalException: exception,
    );
  }

  /// Create a network error
  factory AppError.network(String message, {String? details}) {
    return AppError(
      type: ErrorType.network,
      message: message,
      details: details,
    );
  }

  /// Create an authentication error
  factory AppError.authentication(String message, {String? details}) {
    return AppError(
      type: ErrorType.authentication,
      message: message,
      details: details,
    );
  }

  /// Create a validation error
  factory AppError.validation(String message, {String? details}) {
    return AppError(
      type: ErrorType.validation,
      message: message,
      details: details,
    );
  }

  /// Create a cache error
  factory AppError.cache(String message, {String? details}) {
    return AppError(
      type: ErrorType.cache,
      message: message,
      details: details,
    );
  }

  /// Get user-friendly error message based on error type
  String get userFriendlyMessage {
    switch (type) {
      case ErrorType.network:
        return 'Please check your internet connection and try again.';
      case ErrorType.authentication:
        return 'Please log in again to continue.';
      case ErrorType.validation:
        return 'Please check your input and try again.';
      case ErrorType.notFound:
        return 'The requested information could not be found.';
      case ErrorType.server:
        return 'Server is currently unavailable. Please try again later.';
      case ErrorType.cache:
        return 'Data loading issue. Please refresh and try again.';
      case ErrorType.permission:
        return 'You do not have permission to perform this action.';
      case ErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Whether this is a recoverable error (user can retry)
  bool get isRecoverable {
    switch (type) {
      case ErrorType.network:
      case ErrorType.server:
      case ErrorType.cache:
      case ErrorType.unknown:
        return true;
      case ErrorType.authentication:
      case ErrorType.validation:
      case ErrorType.notFound:
      case ErrorType.permission:
        return false;
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('AppError(${type.name}): $message');
    
    if (statusCode != null) {
      buffer.write(' [HTTP $statusCode]');
    }
    
    if (details != null) {
      buffer.write('\nDetails: $details');
    }
    
    return buffer.toString();
  }

  /// Convert to JSON for logging/debugging
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'message': message,
      'details': details,
      'statusCode': statusCode,
      'timestamp': timestamp.toIso8601String(),
      'userFriendlyMessage': userFriendlyMessage,
      'isRecoverable': isRecoverable,
    };
  }

  /// Helper method to determine error type from HTTP status code
  static ErrorType _getErrorTypeFromStatusCode(int statusCode) {
    if (statusCode >= 400 && statusCode < 500) {
      switch (statusCode) {
        case 401:
        case 403:
          return ErrorType.authentication;
        case 404:
          return ErrorType.notFound;
        case 422:
          return ErrorType.validation;
        default:
          return ErrorType.validation;
      }
    } else if (statusCode >= 500) {
      return ErrorType.server;
    } else {
      return ErrorType.unknown;
    }
  }

  /// Helper method to get message from HTTP status code
  static String _getMessageFromStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Authentication required';
      case 403:
        return 'Access forbidden';
      case 404:
        return 'Resource not found';
      case 422:
        return 'Validation failed';
      case 500:
        return 'Internal server error';
      case 502:
        return 'Bad gateway';
      case 503:
        return 'Service unavailable';
      default:
        return 'HTTP error $statusCode';
    }
  }
}
