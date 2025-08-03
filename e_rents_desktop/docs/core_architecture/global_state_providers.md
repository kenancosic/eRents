# eRents Desktop Application Global State Providers Documentation

## Overview

This document provides documentation for the global state providers used in the eRents desktop application. These providers manage application-wide state including navigation, user preferences, and global error handling using the provider state management system.

## Provider Structure

The global state providers are located in the `lib/base/app_state_providers.dart` file and include:

1. `NavigationStateProvider` - Navigation state management
2. `PreferencesStateProvider` - User preferences management
3. `AppErrorProvider` - Global error state management

## Navigation State Provider

Manages the current navigation state of the application using a cleaner state-based approach.

### Features

1. **Path Tracking**: Tracks the current route path
2. **State Management**: Uses ChangeNotifier for reactive updates
3. **Path Checking**: Utility methods for path comparison
4. **Auth Path Detection**: Special handling for authentication routes

### Implementation

```dart
class NavigationStateProvider extends ChangeNotifier {
  String _currentPath = '/';

  NavigationStateProvider();

  /// Get the current path
  String get currentPath => _currentPath;

  /// Update the current navigation path
  void updateCurrentPath(String path) {
    if (_currentPath != path) {
      _currentPath = path;
      notifyListeners();
    }
  }

  /// Check if currently on a specific path
  bool isOnPath(String path) => _currentPath == path;

  /// Check if currently on any auth-related path
  bool get isOnAuthPath =>
      _currentPath == '/login' ||
      _currentPath == '/signup' ||
      _currentPath == '/forgot-password';
}
```

### Usage

```dart
// Update navigation path
final navProvider = Provider.of<NavigationStateProvider>(context, listen: false);
navProvider.updateCurrentPath('/properties');

// Check current path
final isOnProperties = navProvider.isOnPath('/properties');

// Check if on auth path
final isOnAuth = navProvider.isOnAuthPath;
```

## Preferences State Provider

Manages user preferences with better error handling and state management.

### Features

1. **Preference Management**: CRUD operations for user preferences
2. **Service Integration**: Integration with UserPreferencesService
3. **Error Handling**: Structured error handling with AppError
4. **Reactive Updates**: Uses ChangeNotifier for reactive updates
5. **Type Safety**: Generic methods for type-safe preference access

### Implementation

```dart
class PreferencesStateProvider extends ChangeNotifier {
  final UserPreferencesService _prefsService;
  Map<String, dynamic> _preferences = {};

  PreferencesStateProvider(this._prefsService);

  /// Load all preferences from the service
  Future<void> loadPreferences() async {
    try {
      _preferences = <String, dynamic>{};
      notifyListeners();
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Update a specific preference
  Future<void> updatePreference(String key, dynamic value) async {
    try {
      await _prefsService.setPreference(key, value);
      _preferences[key] = value;
      notifyListeners();
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Get a preference value with optional default
  T? getPreference<T>(String key, [T? defaultValue]) {
    return _preferences[key] as T? ?? defaultValue;
  }

  /// Check if a preference exists
  bool hasPreference(String key) => _preferences.containsKey(key);

  /// Remove a preference
  Future<void> removePreference(String key) async {
    try {
      await _prefsService.removePreference(key);
      _preferences.remove(key);
      notifyListeners();
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Clear all preferences (removes them individually)
  Future<void> clearAllPreferences() async {
    try {
      for (final key in _preferences.keys.toList()) {
        await _prefsService.removePreference(key);
      }
      _preferences.clear();
      notifyListeners();
    } catch (e) {
      throw AppError.fromException(e);
    }
  }
}
```

### Usage

```dart
// Load preferences
final prefsProvider = Provider.of<PreferencesStateProvider>(context, listen: false);
await prefsProvider.loadPreferences();

// Update preference
await prefsProvider.updatePreference('theme', 'dark');

// Get preference
final theme = prefsProvider.getPreference<String>('theme', 'light');

// Check preference existence
final hasTheme = prefsProvider.hasPreference('theme');

// Remove preference
await prefsProvider.removePreference('theme');

// Clear all preferences
await prefsProvider.clearAllPreferences();
```

## App Error Provider

Provides centralized error state management for the entire application using structured AppError handling.

### Features

1. **Global Error State**: Centralized error management
2. **Structured Errors**: Uses AppError model for consistent error handling
3. **Error Types**: Support for different error types (network, validation, etc.)
4. **Reactive Updates**: Uses ChangeNotifier for reactive updates
5. **Convenience Methods**: Helper methods for common error scenarios
6. **Error Information**: Access to error details and user messages

### Implementation

```dart
class AppErrorProvider extends ChangeNotifier {
  AppError? _error;

  AppErrorProvider();

  /// Get the current error state
  AppError? get error => _error;

  /// Set an error state
  void setError(AppError? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  /// Clear the current error
  void clearError() {
    setError(null);
  }

  /// Check if there's currently an error
  bool get hasError => _error != null;

  /// Get the current error type
  ErrorType? get currentErrorType => _error?.type;

  /// Get user-friendly error message
  String? get userMessage => _error?.userMessage;

  /// Check if current error is retryable
  bool get isRetryable => _error?.isRetryable ?? false;

  /// Set error from exception (convenience method)
  void setErrorFromException(dynamic exception, [StackTrace? stackTrace]) {
    setError(AppError.fromException(exception, stackTrace));
  }

  /// Set a network error
  void setNetworkError(String message, [String? details]) {
    setError(
      AppError(type: ErrorType.network, message: message, details: details),
    );
  }

  /// Set a validation error
  void setValidationError(String message, [String? details]) {
    setError(
      AppError(type: ErrorType.validation, message: message, details: details),
    );
  }

  /// Set an authentication error
  void setAuthenticationError(String message, [String? details]) {
    setError(
      AppError(
        type: ErrorType.authentication,
        message: message,
        details: details,
      ),
    );
  }
}
```

### Usage

```dart
// Set error from exception
final errorProvider = Provider.of<AppErrorProvider>(context, listen: false);
errorProvider.setErrorFromException(exception);

// Set specific error types
errorProvider.setNetworkError('Network connection failed');
errorProvider.setValidationError('Invalid input data');
errorProvider.setAuthenticationError('Invalid credentials');

// Check error state
final hasError = errorProvider.hasError;
final errorType = errorProvider.currentErrorType;
final userMessage = errorProvider.userMessage;
final isRetryable = errorProvider.isRetryable;

// Clear error
errorProvider.clearError();
```

## Provider Integration

### Registration

Global providers are registered in the main application:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => NavigationStateProvider()),
    ChangeNotifierProvider(create: (_) => PreferencesStateProvider(prefsService)),
    ChangeNotifierProvider(create: (_) => AppErrorProvider()),
    // ... other providers
  ],
  child: const App(),
)
```

### Usage in Components

Providers are consumed in components using Provider.of or Consumer:

```dart
// Using Provider.of
final navProvider = Provider.of<NavigationStateProvider>(context);
final currentPath = navProvider.currentPath;

// Using Consumer
Consumer<PreferencesStateProvider>(
  builder: (context, prefsProvider, child) {
    final theme = prefsProvider.getPreference<String>('theme', 'light');
    return ThemeSwitcher(theme: theme);
  },
)

// Using Selector for specific properties
Selector<AppErrorProvider, bool>(
  selector: (context, errorProvider) => errorProvider.hasError,
  builder: (context, hasError, child) {
    return hasError ? ErrorIndicator() : Container();
  },
)
```

## Best Practices

1. **State Management**: Use ChangeNotifier for reactive state updates
2. **Error Handling**: Implement structured error handling with AppError
3. **Type Safety**: Use generic methods for type-safe preference access
4. **Resource Management**: Properly dispose of resources in providers
5. **Performance**: Use Selector for specific property updates
6. **Consistency**: Follow consistent patterns across all providers
7. **Documentation**: Document provider methods and properties
8. **Testing**: Write tests for provider logic and state management
9. **Error Recovery**: Implement clear error recovery mechanisms
10. **Global State**: Minimize global state and keep it focused

## Extensibility

The global state provider architecture supports easy extension:

1. **New Providers**: Create new providers following the ChangeNotifier pattern
2. **Provider Enhancement**: Add new methods to existing providers
3. **State Integration**: Integrate new state management requirements
4. **Service Integration**: Connect providers with new services
5. **Error Handling**: Extend error handling patterns
6. **Performance Optimization**: Optimize provider performance with selectors

This global state provider documentation ensures consistent implementation of application-wide state management and provides a solid foundation for future development.
