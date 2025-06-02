import '../base/base.dart';
import '../services/user_preferences_service.dart';

/// Navigation state provider using StateProvider for current path tracking
///
/// Replaces the old NavigationProvider with a cleaner state-based approach.
/// Tracks the current route path and provides navigation state management.
class NavigationStateProvider extends StateProvider<String> {
  NavigationStateProvider() : super('/');

  /// Update the current navigation path
  void updateCurrentPath(String path) {
    updateState(path);
  }

  /// Get the current path
  String get currentPath => state;

  /// Check if currently on a specific path
  bool isOnPath(String path) => state == path;

  /// Check if currently on any auth-related path
  bool get isOnAuthPath =>
      state == '/login' || state == '/signup' || state == '/forgot-password';
}

/// Preferences state provider for managing user preferences
///
/// Replaces the old PreferencesProvider with better error handling and
/// state management using the new StateProvider infrastructure.
class PreferencesStateProvider extends StateProvider<Map<String, dynamic>> {
  final UserPreferencesService _prefsService;

  PreferencesStateProvider(this._prefsService) : super({});

  /// Load all preferences from the service
  Future<void> loadPreferences() async {
    try {
      // Note: This method depends on UserPreferencesService API
      // We'll implement based on the actual service interface
      final prefs =
          <String, dynamic>{}; // Placeholder - implement based on service
      updateState(prefs);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Update a specific preference
  Future<void> updatePreference(String key, dynamic value) async {
    try {
      await _prefsService.setPreference(key, value);
      final newState = Map<String, dynamic>.from(state);
      newState[key] = value;
      updateState(newState);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Get a preference value with optional default
  T? getPreference<T>(String key, [T? defaultValue]) {
    return state[key] as T? ?? defaultValue;
  }

  /// Check if a preference exists
  bool hasPreference(String key) => state.containsKey(key);

  /// Remove a preference
  Future<void> removePreference(String key) async {
    try {
      await _prefsService.removePreference(key);
      final newState = Map<String, dynamic>.from(state);
      newState.remove(key);
      updateState(newState);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Clear all preferences (removes them individually)
  Future<void> clearAllPreferences() async {
    try {
      // Since UserPreferencesService doesn't have clearAll,
      // we remove known preferences individually
      for (final key in state.keys.toList()) {
        await _prefsService.removePreference(key);
      }
      updateState(<String, dynamic>{});
    } catch (e) {
      throw AppError.fromException(e);
    }
  }
}

/// Global application error state provider
///
/// Replaces the old ErrorProvider with structured AppError handling.
/// Provides centralized error state management for the entire application.
class AppErrorProvider extends StateProvider<AppError?> {
  AppErrorProvider() : super(null);

  /// Set an error state
  void setError(AppError error) {
    updateState(error);
  }

  /// Clear the current error
  void clearError() {
    updateState(null);
  }

  /// Check if there's currently an error
  bool get hasError => state != null;

  /// Get the current error type
  ErrorType? get currentErrorType => state?.type;

  /// Get user-friendly error message
  String? get userMessage => state?.userMessage;

  /// Check if current error is retryable
  bool get isRetryable => state?.isRetryable ?? false;

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
