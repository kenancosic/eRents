# eRents Desktop Application AppError Class Documentation

## Overview

This document provides detailed documentation for the `AppError` class used in the eRents desktop application. The `AppError` class is a structured error representation that provides consistent error handling across the application with user-friendly messages, retry capabilities, and detailed debugging information.

## Class Structure

The `AppError` class is located in the `lib/base/app_error.dart` file and provides:

1. Structured error representation
2. Error typing and categorization
3. User-friendly error messages
4. Technical error details
5. Retry capability identification
6. Exception conversion utilities

## Core Properties

### errorType

```dart
final ErrorType errorType;
```

The type of error that occurred, categorized into specific types for appropriate handling.

### userMessage

```dart
globalStateProviders.dart:48:3: Error: Expected a declaration, but got 'final'.
final String userMessage;
  ^^^^^
final String userMessage;
```

A user-friendly message that can be displayed to the end user.

### technicalMessage

```dart
final String technicalMessage;
```

A detailed technical message for debugging purposes.

### exception

```dart
final Object? exception;
```

The original exception that caused this error, if available.

### stackTrace

```dart
final StackTrace? stackTrace;
```

The stack trace associated with the error, if available.

### isRetryable

```dart
final bool isRetryable;
```

Whether the error is retryable (e.g., network errors).

### timestamp

```dart
final DateTime timestamp;
```

The time when the error occurred.

## Error Types

The `ErrorType` enum categorizes errors into specific types:

```dart
enum ErrorType {
  network,         // Network connection issues
  authentication,  // Auth failures (401)
  validation,      // Data validation errors (400, 422)
  notFound,        // Resource not found (404)
  server,          // Server errors (5xx)
  permission,      // Permission denied (403)
  unknown          // Unhandled errors
}
```

## Constructors

### AppError Constructor

```dart
AppError({
  required this.errorType,
  required this.userMessage,
  required this.technicalMessage,
  this.exception,
  this.stackTrace,
  this.isRetryable = false,
});
```

Creates a new AppError instance with the specified properties.

### AppError.fromException

```dart
AppError.fromException(
  Object exception,
  StackTrace stackTrace,
  String? context,
);
```

Creates an AppError from an exception, automatically determining the error type and messages.

### AppError.fromHttpException

```dart
AppError.fromHttpException(
  http.Response response,
  Object? exception,
  StackTrace? stackTrace,
  String? context,
);
```

Creates an AppError from an HTTP response, mapping HTTP status codes to error types.

## Factory Methods

### fromNetworkException

```dart
factory AppError.fromNetworkException(
  Object exception,
  StackTrace stackTrace,
  String? context,
);
```

Creates an AppError specifically for network-related exceptions.

### fromAuthException

```dart
factory AppError.fromAuthException(
  Object exception,
  StackTrace stackTrace,
  String? context,
);
```

Creates an AppError specifically for authentication-related exceptions.

### fromValidationException

```dart
factory AppError.fromValidationException(
  Object exception,
  StackTrace stackTrace,
  String? context,
);
```

Creates an AppError specifically for validation-related exceptions.

## Methods

### copyWith

```dart
AppError copyWith({
  ErrorType? errorType,
  String? userMessage,
  String? technicalMessage,
  Object? exception,
  StackTrace? stackTrace,
  bool? isRetryable,
});
```

Creates a copy of this AppError with the specified fields replaced.

### toString

```dart
@override
String toString();
```

Returns a string representation of the error for debugging.

## Usage Examples

### Creating a Basic Error

```dart
final error = AppError(
  errorType: ErrorType.unknown,
  userMessage: 'An unexpected error occurred',
  technicalMessage: 'Unexpected error in property loading',
  isRetryable: false,
);
```

### Creating an Error from an Exception

```dart
try {
  await apiService.get('/properties');
} catch (e, s) {
  final error = AppError.fromException(e, s, 'Loading properties');
  // Handle the error
}
```

### Creating an Error from an HTTP Response

```dart
final response = await apiService.get('/properties');
if (response.statusCode != 200) {
  final error = AppError.fromHttpException(
    response,
    null,
    null,
    'Loading properties',
  );
  // Handle the error
}
```

### Using with AppErrorProvider

```dart
// In a provider
final error = AppError.fromException(e, s, 'Loading properties');
_appErrorProvider.setError(error);

// In UI
if (provider.hasError) {
  return ErrorDisplayWidget(error: provider.error);
}
```

## Integration with Base Provider Architecture

The AppError class works seamlessly with the base provider architecture:

```dart
// In a provider that extends BaseProvider
class PropertyProvider extends BaseProvider<PropertyProvider> {
  final ApiService _apiService;
  
  PropertyProvider(this._apiService);
  
  Future<List<Property>?> loadProperties() async {
    try {
      return await _apiService.getListAndDecode<Property>(
        '/api/properties',
        Property.fromJson,
      );
    } catch (e, s) {
      // Errors are automatically converted to AppError
      rethrow;
    }
  }
}
```

## Error Type Mapping

The AppError class automatically maps HTTP status codes to error types:

| Status Code | Error Type | Retryable | User Message |
|-------------|------------|-----------|--------------|
| 400, 422 | validation | No | Invalid data provided |
| 401 | authentication | No | Authentication required |
| 403 | permission | No | Access denied |
| 404 | notFound | No | Resource not found |
| 408, 502, 503, 504 | network/server | Yes | Service temporarily unavailable |
| 5xx | server | Yes | Server error |
| Network exceptions | network | Yes | Network connection failed |
| Other | unknown | No | An unexpected error occurred |

## Best Practices

1. **Use AppError Consistently**: Always use AppError for error representation
2. **Provide User-Friendly Messages**: Ensure userMessage is clear and actionable
3. **Include Technical Details**: Maintain detailed technicalMessage for debugging
4. **Set Retryable Correctly**: Mark network and server errors as retryable
5. **Preserve Stack Traces**: Always include stack traces for debugging
6. **Contextual Information**: Include context about where the error occurred
7. **Error Type Accuracy**: Use appropriate ErrorType values
8. **Exception Preservation**: Keep original exceptions when available

## Testing

When testing code that uses AppError:

```dart
// Test error creation
void main() {
  test('AppError creation', () {
    final error = AppError(
      errorType: ErrorType.network,
      userMessage: 'Network error',
      technicalMessage: 'Connection failed',
      isRetryable: true,
    );
    
    expect(error.errorType, ErrorType.network);
    expect(error.isRetryable, true);
  });
  
  test('AppError from exception', () {
    final exception = Exception('Network failure');
    final stackTrace = StackTrace.current;
    final error = AppError.fromException(
      exception,
      stackTrace,
      'Testing',
    );
    
    expect(error.errorType, ErrorType.network);
    expect(error.isRetryable, true);
  });
}
```

This documentation ensures consistent implementation of error handling and provides a solid foundation for future development.
