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
  
  /// Timeout errors
  timeout,
  
  /// Service unavailable errors
  serviceUnavailable,
  
  /// Rate limiting errors
  rateLimit,
  
  /// Feature not available errors
  notAvailable,
  
  /// Payment required errors
  paymentRequired,

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

  /// Creates a new AppError instance
  AppError({
    required this.type,
    required this.message,
    this.details,
    this.statusCode,
    DateTime? timestamp,
    this.stackTrace,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// Creates a network error
  factory AppError.network(String message, {String? details, StackTrace? stackTrace}) {
    return AppError(
      type: ErrorType.network,
      message: message,
      details: details,
      stackTrace: stackTrace,
    );
  }
  
  /// Creates a validation error
  factory AppError.validation(String message, {String? details, StackTrace? stackTrace}) {
    return AppError(
      type: ErrorType.validation,
      message: message,
      details: details,
      stackTrace: stackTrace,
    );
  }
  
  /// Creates an authentication error
  factory AppError.authentication(String message, {String? details, int? statusCode, StackTrace? stackTrace}) {
    return AppError(
      type: ErrorType.authentication,
      message: message,
      details: details,
      statusCode: statusCode ?? 401,
      stackTrace: stackTrace,
    );
  }
  
  /// Creates a not found error
  factory AppError.notFound(String message, {String? details, StackTrace? stackTrace}) {
    return AppError(
      type: ErrorType.notFound,
      message: message,
      details: details,
      statusCode: 404,
      stackTrace: stackTrace,
    );
  }
  
  /// Creates a server error
  factory AppError.server(String message, {String? details, int? statusCode, StackTrace? stackTrace}) {
    return AppError(
      type: ErrorType.server,
      message: message,
      details: details,
      statusCode: statusCode ?? 500,
      stackTrace: stackTrace,
    );
  }
  
  /// Creates a timeout error
  factory AppError.timeout(String message, {String? details, StackTrace? stackTrace}) {
    return AppError(
      type: ErrorType.timeout,
      message: message,
      details: details,
      stackTrace: stackTrace,
    );
  }

  /// Creates an AppError from various exception types
  factory AppError.fromException(dynamic exception, [StackTrace? stackTrace, String? message]) {
    if (exception is SocketException) {
      return AppError(
        type: ErrorType.network,
        message: message ?? 'Network connection failed',
        details: exception.message,
        stackTrace: stackTrace,
      );
    }

    if (exception is HttpException) {
      return AppError(
        type: ErrorType.network,
        message: 'HTTP error occurred',
        details: exception.message,
        stackTrace: stackTrace,
      );
    }

    if (exception is http.ClientException) {
      return AppError(
        type: ErrorType.network,
        message: 'Network request failed',
        details: exception.message,
        stackTrace: stackTrace,
      );
    }

    if (exception is FormatException) {
      return AppError(
        type: ErrorType.validation,
        message: 'Invalid data format',
        details: exception.message,
        stackTrace: stackTrace,
      );
    }

    if (exception is ArgumentError) {
      return AppError(
        type: ErrorType.validation,
        message: 'Invalid argument provided',
        details: exception.message,
        stackTrace: stackTrace,
      );
    }

    if (exception is StateError) {
      return AppError(
        type: ErrorType.unknown,
        message: 'Invalid state',
        details: exception.message,
        stackTrace: stackTrace,
      );
    }

    // Handle string exceptions
    if (exception is String) {
      return AppError(
        type: ErrorType.unknown,
        message: exception,
        stackTrace: stackTrace,
      );
    }

    // Handle Exception objects
    if (exception is Exception) {
      final exceptionString = exception.toString();

      // Try to extract meaningful information from common exception patterns
      if (exceptionString.contains('401') ||
          exceptionString.contains('Unauthorized')) {
        return AppError(
          type: ErrorType.authentication,
          message: 'Authentication failed',
          details: exceptionString,
          statusCode: 401,
          stackTrace: stackTrace,
        );
      }

      if (exceptionString.contains('403') ||
          exceptionString.contains('Forbidden')) {
        return AppError(
          type: ErrorType.permission,
          message: 'Access denied',
          details: exceptionString,
          statusCode: 403,
          stackTrace: stackTrace,
        );
      }

      if (exceptionString.contains('404') ||
          exceptionString.contains('Not Found')) {
        return AppError(
          type: ErrorType.notFound,
          message: 'Resource not found',
          details: exceptionString,
          statusCode: 404,
          stackTrace: stackTrace,
        );
      }

      if (exceptionString.contains('500') ||
          exceptionString.contains('Internal Server Error')) {
        return AppError(
          type: ErrorType.server,
          message: 'Server error occurred',
          details: exceptionString,
          statusCode: 500,
          stackTrace: stackTrace,
        );
      }
    }

    // Default case for unknown exceptions
    return AppError(
      type: ErrorType.unknown,
      message: 'An unexpected error occurred',
      details: exception.toString(),
      stackTrace: stackTrace,
    );
  }

  /// Creates an AppError from an HTTP status code and response
  factory AppError.fromHttpResponse(
    int statusCode,
    String? responseBody, [
    StackTrace? stackTrace,
  ]) {
    final type = _getErrorTypeFromStatusCode(statusCode);
    final message = _getMessageFromStatusCode(statusCode);

    return AppError(
      type: type,
      message: message,
      details: responseBody,
      statusCode: statusCode,
      stackTrace: stackTrace,
    );
  }

  /// Determines if this error is retryable
  bool get isRetryable {
    switch (type) {
      case ErrorType.network:
      case ErrorType.server:
      case ErrorType.timeout:
      case ErrorType.rateLimit:
      case ErrorType.serviceUnavailable:
        return true;
      case ErrorType.authentication:
      case ErrorType.permission:
      case ErrorType.validation:
      case ErrorType.notFound:
      case ErrorType.cache:
      case ErrorType.unknown:
      case ErrorType.notAvailable:
      case ErrorType.paymentRequired:
        return false;
    }
  }

  /// Returns a user-friendly message for this error
  String get userMessage {
    switch (type) {
      case ErrorType.network:
        return 'Network connection failed. Please check your internet connection and try again.';
      case ErrorType.timeout:
        return 'Request timed out. Please check your connection and try again.';
      case ErrorType.authentication:
        return 'Session expired. Please log in again to continue.';
      case ErrorType.permission:
        return 'You don\'t have permission to perform this action. Please contact support if you believe this is an error.';
      case ErrorType.validation:
        return 'Invalid input. Please check your information and try again.';
      case ErrorType.notFound:
        return 'The requested resource could not be found.';
      case ErrorType.server:
        return 'Our servers are experiencing issues. Please try again in a few moments.';
      case ErrorType.cache:
        return 'Unable to load cached data. Please refresh and try again.';
      case ErrorType.rateLimit:
        return 'Too many requests. Please wait a moment and try again.';
      case ErrorType.serviceUnavailable:
        return 'Service is temporarily unavailable. Please try again later.';
      case ErrorType.notAvailable:
        return 'This feature is not available in your current plan.';
      case ErrorType.paymentRequired:
        return 'Payment required. Please update your subscription to continue.';
      case ErrorType.unknown:
        return 'An unexpected error occurred. Please try again or contact support if the problem persists.';
    }
  }

  /// Returns a detailed error description for debugging
  String get debugDescription {
    final buffer = StringBuffer();
    buffer.writeln('AppError: $type');
    buffer.writeln('Message: $message');
    if (details != null) buffer.writeln('Details: $details');
    if (statusCode != null) buffer.writeln('Status Code: $statusCode');
    buffer.writeln('Timestamp: $timestamp');
    if (stackTrace != null) buffer.writeln('Stack Trace: $stackTrace');
    return buffer.toString();
  }

  @override
  String toString() {
    return 'AppError(type: $type, message: $message, statusCode: $statusCode)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppError &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          message == other.message &&
          statusCode == other.statusCode;

  @override
  int get hashCode => type.hashCode ^ message.hashCode ^ statusCode.hashCode;

  /// Helper method to determine error type from HTTP status code
  static ErrorType _getErrorTypeFromStatusCode(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return ErrorType.unknown; // Shouldn't create errors for success codes
    } else if (statusCode == 401) {
      return ErrorType.authentication;
    } else if (statusCode == 403) {
      return ErrorType.permission;
    } else if (statusCode == 404) {
      return ErrorType.notFound;
    } else if (statusCode >= 400 && statusCode < 500) {
      return ErrorType.validation;
    } else if (statusCode >= 500) {
      return ErrorType.server;
    } else {
      return ErrorType.unknown;
    }
  }

  /// Helper method to get error message from HTTP status code
  static String _getMessageFromStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not found';
      case 409:
        return 'Conflict';
      case 422:
        return 'Unprocessable entity';
      case 429:
        return 'Too many requests';
      case 500:
        return 'Internal server error';
      case 502:
        return 'Bad gateway';
      case 503:
        return 'Service unavailable';
      case 504:
        return 'Gateway timeout';
      default:
        return 'HTTP error $statusCode';
    }
  }
}
