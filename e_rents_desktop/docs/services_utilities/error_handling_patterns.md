# Error Handling Patterns in eRents Desktop Application

## Overview

The eRents desktop application implements a structured error handling system using the `AppError` class and `AppErrorProvider` for centralized error management. This approach provides consistent error handling across the application with user-friendly messages, retry capabilities, and detailed debugging information.

## Core Components

### AppError Class

The `AppError` class is a structured error representation that provides:

1. **Error Typing**: Categorizes errors into specific types for appropriate handling
2. **User-Friendly Messages**: Provides clear messages for end users
3. **Technical Details**: Maintains detailed information for debugging
4. **Retry Capabilities**: Identifies which errors are retryable
5. **HTTP Status Mapping**: Automatically maps HTTP status codes to error types

#### Error Types

```dart
enum ErrorType {
  network,         // Network connection issues
  authentication,  // Auth failures (401)
  validation,      // Data validation errors (400, 422)
  notFound,        // Resource not found (404)
  server,          // Server errors (5xx)
  cache,           // Cache-related issues
  permission,      // Permission denied (403)
  unknown          // Unhandled errors
}
```

#### Key Features

- **Retryable Errors**: Network and server errors are considered retryable
- **User Messages**: Each error type has a predefined user-friendly message
- **Debug Information**: Full error details and stack traces for development
- **Exception Conversion**: Automatically converts various exception types

### AppErrorProvider

The `AppErrorProvider` is a global state provider that manages the application's error state:

```dart
class AppErrorProvider extends ChangeNotifier {
  AppError? _error;
  
  // State accessors
  AppError? get error => _error;
  bool get hasError => _error != null;
  ErrorType? get currentErrorType => _error?.type;
  String? get userMessage => _error?.userMessage;
  bool get isRetryable => _error?.isRetryable ?? false;
  
  // Error setting methods
  void setError(AppError? error);
  void clearError();
  void setErrorFromException(dynamic exception, [StackTrace? stackTrace]);
  void setNetworkError(String message, [String? details]);
  void setValidationError(String message, [String? details]);
  void setAuthenticationError(String message, [String? details]);
}
```

## Implementation Patterns

### Provider Integration

Providers integrate with the error handling system through the base provider architecture:

```dart
class MyProvider extends BaseProvider {
  Future<void> loadData() async {
    final data = await executeWithState(() async {
      return await api.getAndDecode('/data', DataModel.fromJson);
    });
    
    if (data != null) {
      _processData(data);
    }
    // Errors are automatically handled by BaseProviderMixin
  }
}
```

### Manual Error Setting

For specific error scenarios, providers can manually set errors:

```dart
Future<bool> performOperation() async {
  return await executeWithStateForSuccess(() async {
    try {
      await api.post('/endpoint', requestData);
    } catch (e) {
      // Set specific error type
      if (e is ValidationException) {
        errorProvider.setValidationError('Invalid input', e.details);
      } else {
        errorProvider.setErrorFromException(e);
      }
      rethrow;
    }
  });
}
```

### Global Error Handling

The application implements global error handling through:

1. **Main App Integration**:
```dart
MultiProvider(
  providers: [
    // Other providers
    ChangeNotifierProvider(create: (_) => AppErrorProvider()),
  ],
  child: MaterialApp(
    // ...
  ),
)
```

2. **Global Error Dialog**:
```dart
// In main.dart
if (errorProvider.hasError) {
  GlobalErrorDialog(
    error: errorProvider.error,
    onRetry: _handleRetry,
    onDismiss: errorProvider.clearError,
  );
}
```

## Best Practices

1. **Use Structured Errors**: Always use `AppError` instead of raw strings
2. **Provide Context**: Include relevant details in error messages
3. **Enable Retry**: Mark errors as retryable when appropriate
4. **User-Friendly Messages**: Ensure error messages are understandable
5. **Log for Debugging**: Include stack traces for development debugging
6. **Clear Errors**: Clear errors after they've been addressed

## Error Flow

1. Exception occurs in provider or service
2. BaseProviderMixin automatically catches and converts to AppError
3. AppErrorProvider stores the error and notifies listeners
4. UI components listen to error state and display appropriate messages
5. User can retry if error is retryable or dismiss to clear

This error handling pattern ensures consistent, user-friendly error experiences while providing developers with detailed debugging information.
