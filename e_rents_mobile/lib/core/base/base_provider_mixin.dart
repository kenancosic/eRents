import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'app_error.dart';
import 'app_state_providers.dart';

/// Base mixin for provider state management
///
/// Provides common state management functionality that all providers need:
/// - Explicit state management with ProviderState enum
/// - Loading state management
/// - Error state management with AppError
/// - Convenient methods for state updates
/// - Generic operation wrapper with automatic state handling
/// - Retry logic with exponential backoff
mixin BaseProviderMixin on ChangeNotifier {
  ProviderState _state = ProviderState.initial;
  AppError? _error;
  String? _message;
  bool _disposed = false;

  /// Current state of the provider
  ProviderState get state => _state;
  
  /// Current error if any
  AppError? get error => _error;
  
  /// Current message (success, info, or error message)
  String? get message => _message;

  /// Check if provider is in loading state
  bool get isLoading => _state.isLoading;
  
  /// Check if provider is in success state
  bool get isSuccess => _state.isSuccess;
  
  /// Check if provider is in error state
  bool get isError => _state.isError;

  /// UI compatibility: Check if provider has an error (same as isError)
  bool get hasError => isError;

  /// UI compatibility: Get error message as string
  String get errorMessage => _error?.message ?? '';
  
  /// Check if provider is in initial state
  bool get isInitial => _state.isInitial;
  
  /// Check if provider is in empty state
  bool get isEmpty => _state.isEmpty;
  
  /// Check if provider has data (success or empty)
  bool get hasData => _state.hasData;
  
  /// Check if provider can perform operations (not loading)
  bool get canPerformOperations => _state.canPerformOperations;

  /// Whether the provider is currently busy with an operation
  bool get isBusy => isLoading;

  @override
  void dispose() {
    _disposed = true;
    _state = ProviderState.initial;
    _error = null;
    _message = null;
    super.dispose();
  }

  /// Set the provider to loading state
  void setLoading() {
    if (_disposed) return;
    _error = null;
    _message = null;
    _state = ProviderState.loading;
    notifyListeners();
  }

  /// Set the provider to success state with optional message
  void setSuccess([String? message]) {
    if (_disposed) return;
    _error = null;
    _message = message;
    _state = ProviderState.success;
    notifyListeners();
  }

  /// Set the provider to error state with error and optional message
  void setError(AppError error, [String? message]) {
    if (_disposed) return;
    _error = error;
    _message = message ?? error.message;
    _state = ProviderState.error;
    notifyListeners();
  }

  /// Set the provider to empty state with optional message
  void setEmpty([String? message]) {
    if (_disposed) return;
    _error = null;
    _message = message;
    _state = ProviderState.empty;
    notifyListeners();
  }

  /// Set the provider to initial state
  void setInitial() {
    if (_disposed) return;
    _error = null;
    _message = null;
    _state = ProviderState.initial;
    notifyListeners();
  }

  /// Clear error and message
  void clearError() {
    if (_disposed) return;
    _error = null;
    _message = null;
    if (_state == ProviderState.error) {
      _state = ProviderState.success;
    }
    notifyListeners();
  }

  /// Clear message only
  void clearMessage() {
    if (_disposed) return;
    _message = null;
    notifyListeners();
  }

  /// Execute an operation with automatic loading and error state management
  /// 
  /// This method:
  /// 1. Sets loading state
  /// 2. Clears any existing error
  /// 3. Executes the operation
  /// 4. Handles any errors by setting error state
  /// 5. Updates state when complete
  /// 
  /// Usage:
  /// ```dart
  /// final result = await executeWithState(() async {
  ///   final data = await api.get('/endpoint');
  ///   return _processData(data);
  /// });
  /// ```
  Future<T?> executeWithState<T>(
    Future<T> Function() operation, {
    bool isRefresh = false,
  }) async {
    if (_disposed) return null;

    setLoading();

    try {
      final result = await operation();
      setSuccess();
      return result;
    } catch (e, stackTrace) {
      final error = _convertToAppError(e, stackTrace);
      setError(error);
      debugPrint('BaseProviderMixin error: ${error.message}');
      return null;
    }
  }

  /// Execute an operation with automatic loading and error state management
  /// using a custom error message
  Future<T?> executeWithStateAndMessage<T>(
    Future<T> Function() operation,
    String errorMessage, {
    bool isRefresh = false,
  }) async {
    if (_disposed) return null;

    setLoading();

    try {
      final result = await operation();
      setSuccess();
      return result;
    } catch (e, stackTrace) {
      final originalError = _convertToAppError(e, stackTrace);
      final customError = _createCustomError(originalError, errorMessage);
      setError(customError);
      debugPrint('BaseProviderMixin error: ${customError.message}');
      return null;
    }
  }

  /// Execute an operation with automatic loading and error state management
  /// Returns a boolean indicating success or failure
  /// 
  /// This is useful for operations where you only care about success/failure
  /// and don't need the result value.
  Future<bool> executeWithStateForSuccess(
    Future<void> Function() operation, {
    String? errorMessage,
  }) async {
    final result = await executeWithStateAndMessage(() async {
      await operation();
      return true;
    }, errorMessage ?? 'Operation failed');
    return result ?? false;
  }

  /// Execute an operation with automatic retry logic
  /// 
  /// This method will automatically retry the operation if it fails with a retryable error.
  /// It uses an exponential backoff strategy between retries.
  /// 
  /// Parameters:
  /// - operation: The operation to execute and potentially retry
  /// - maxRetries: Maximum number of retry attempts (default: 3)
  /// - initialDelay: Initial delay before first retry (default: 500ms)
  /// - maxDelay: Maximum delay between retries (default: 10s)
  /// - shouldRetry: Optional callback to determine if a failed operation should be retried
  /// 
  /// Returns: The result of the operation, or null if all retries failed
  Future<T?> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    Duration maxDelay = const Duration(seconds: 10),
    bool Function(AppError error, int attempt)? shouldRetry,
    String? errorMessage,
  }) async {
    if (_disposed) return null;

    int attempt = 0;
    Duration delay = initialDelay;

    setLoading();

    while (true) {
      try {
        final result = await operation();
        setSuccess();
        return result;
      } catch (e, stackTrace) {
        attempt++;
        final error = _convertToAppError(e, stackTrace);

        // Check if we should retry
        final bool willRetry = _shouldRetryOperation(error, attempt, maxRetries, shouldRetry);

        if (!willRetry) {
          // No more retries or error is not retryable
          final finalError = errorMessage != null
              ? _createCustomError(error, errorMessage)
              : error;
          setError(finalError);
          debugPrint('BaseProviderMixin error (attempt $attempt/$maxRetries): ${finalError.message}');
          return null;
        }

        // Log the retry
        debugPrint('BaseProviderMixin: Retrying operation (attempt $attempt/$maxRetries). Error: ${error.message}');

        // Wait before retrying with exponential backoff
        await Future.delayed(delay);

        // Update delay for next retry (exponential backoff with jitter)
        delay = _calculateNextDelay(delay, initialDelay, maxDelay);
      }
    }
  }

  /// Convert any exception to AppError
  AppError _convertToAppError(dynamic e, StackTrace stackTrace) {
    if (e is AppError) {
      return e;
    }

    return GenericError(
      message: 'Operation failed: $e',
      originalError: e,
      stackTrace: stackTrace,
    );
  }

  /// Create a custom error with a specific message
  AppError _createCustomError(AppError originalError, String customMessage) {
    if (originalError is NetworkError) {
      return NetworkError(
        message: customMessage,
        statusCode: originalError.statusCode,
        code: originalError.code,
        originalError: originalError.originalError,
        stackTrace: originalError.stackTrace,
      );
    } else if (originalError is AuthError) {
      return AuthError(
        message: customMessage,
        isTokenExpired: originalError.isTokenExpired,
        code: originalError.code,
        originalError: originalError.originalError,
        stackTrace: originalError.stackTrace,
      );
    } else if (originalError is ValidationError) {
      return ValidationError(
        message: customMessage,
        fieldErrors: originalError.fieldErrors,
        code: originalError.code,
        originalError: originalError.originalError,
        stackTrace: originalError.stackTrace,
      );
    }

    return GenericError(
      message: customMessage,
      code: originalError.code,
      originalError: originalError.originalError,
      stackTrace: originalError.stackTrace,
    );
  }

  /// Determine if an operation should be retried
  bool _shouldRetryOperation(
    AppError error,
    int attempt,
    int maxRetries,
    bool Function(AppError error, int attempt)? shouldRetry,
  ) {
    if (attempt > maxRetries) return false;

    if (shouldRetry != null) {
      return shouldRetry(error, attempt);
    }

    // Default retry logic: retry network errors but not auth or validation errors
    if (error is NetworkError) {
      // Retry on 5xx errors or network timeouts, but not on 4xx errors
      if (error.statusCode != null) {
        return error.statusCode! >= 500;
      }
      return true; // Retry if no status code (likely network issue)
    }

    return false; // Don't retry auth, validation, or other errors by default
  }

  /// Calculate next delay using exponential backoff with jitter
  Duration _calculateNextDelay(
    Duration currentDelay,
    Duration initialDelay,
    Duration maxDelay,
  ) {
    // Exponential backoff
    var nextDelay = Duration(
      milliseconds: (currentDelay.inMilliseconds * 1.5).toInt().clamp(
        initialDelay.inMilliseconds,
        maxDelay.inMilliseconds,
      ),
    );

    // Add jitter to prevent thundering herd
    final jitter = (nextDelay.inMilliseconds * 0.2 * (0.5 - math.Random().nextDouble())).toInt();
    nextDelay = Duration(
      milliseconds: (nextDelay.inMilliseconds + jitter).clamp(
        initialDelay.inMilliseconds,
        maxDelay.inMilliseconds,
      ),
    );

    return nextDelay;
  }
}