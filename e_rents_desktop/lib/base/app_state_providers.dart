import 'package:flutter/foundation.dart';

import 'app_error.dart';
import '../services/user_preferences_service.dart';

/// Navigation state provider using StateProvider for current path tracking
///
/// Replaces the old NavigationProvider with a cleaner state-based approach.
/// Tracks the current route path and provides navigation state management.
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

/// Preferences state provider for managing user preferences
///
/// Replaces the old PreferencesProvider with better error handling and
/// state management using the new StateProvider infrastructure.
class PreferencesStateProvider extends ChangeNotifier {
  final UserPreferencesService _prefsService;
  Map<String, dynamic> _preferences = {};

  PreferencesStateProvider(this._prefsService);

  /// Load all preferences from the service
  Future<void> loadPreferences() async {
    try {
      // This is a placeholder, assuming the service returns a Map.
      // You will need to implement the actual service call.
      _preferences = <String, dynamic>{}; // await _prefsService.getAllPreferences();
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

/// Global application error state provider
///
/// Replaces the old ErrorProvider with structured AppError handling.
/// Provides centralized error state management for the entire application.
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
