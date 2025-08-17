import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'app_error.dart';

/// Represents the current state of a provider
enum ProviderState {
  /// Initial state before any data is loaded
  initial,

  /// Data is currently being loaded
  loading,

  /// Data has been successfully loaded
  loaded,

  /// An error occurred while loading data
  error,

  /// Data is being refreshed in the background
  refreshing,

  /// Data is being updated (create/update/delete)
  updating,
}

/// Base mixin for provider state management
///
/// Provides common state management functionality that all providers need:
/// - Explicit state management with ProviderState enum
/// - Loading state management
/// - Error state management with AppError
/// - Convenient methods for state updates
/// - Generic operation wrapper with automatic state handling
mixin BaseProviderMixin on ChangeNotifier {
  ProviderState _state = ProviderState.initial;
  String? _error;
  bool _disposed = false;

  /// The current state of the provider
  ProviderState get state => _state;

  /// Whether the provider is in the initial state
  bool get isInitial => _state == ProviderState.initial;

  /// Whether the provider is currently loading data
  bool get isLoading => _state == ProviderState.loading;

  /// Whether the provider is currently refreshing data
  bool get isRefreshing => _state == ProviderState.refreshing;

  /// Whether the provider is currently updating data
  bool get isUpdating => _state == ProviderState.updating;

  /// Whether the provider has successfully loaded data
  bool get isLoaded => _state == ProviderState.loaded;

  /// Whether the provider is in an error state
  bool get hasError => _state == ProviderState.error;

  /// Whether the provider is currently busy with an operation
  bool get isBusy => isLoading || isRefreshing || isUpdating;

  @override
  void dispose() {
    _disposed = true;
    _state = ProviderState.initial;
    _error = null;
    super.dispose();
  }

  /// Current error message (null if no error)
  String? get error => _error;

  /// Set the current state and notify listeners
  void setState(ProviderState newState, {String? error}) {
    if (_disposed) return;

    _state = newState;
    _error = error;

    if (error != null) {
      _state = ProviderState.error;
    }

    _notifySafely();
  }

  /// Set loading state and notify listeners
  void setLoading(bool isLoading) {
    if (_disposed) return;

    if (isLoading) {
      _state = _state == ProviderState.loaded
          ? ProviderState.refreshing
          : ProviderState.loading;
      _error = null;
    } else if (_state == ProviderState.loading ||
        _state == ProviderState.refreshing) {
      _state = _error != null ? ProviderState.error : ProviderState.loaded;
    }

    _notifySafely();
  }

  /// Set error state and notify listeners
  void setError(String? error) {
    if (_disposed) return;

    _error = error;
    _state = error != null ? ProviderState.error : _state;

    // If we were in a loading/refreshing state, transition to appropriate state
    if (error != null &&
        (_state == ProviderState.loading ||
            _state == ProviderState.refreshing)) {
      _state = ProviderState.error;
    }

    _notifySafely();
  }

  /// Clear error state and notify listeners if there was an error
  void clearError() {
    if (_disposed || _error == null) return;

    _error = null;

    // Only change state if we were in an error state
    if (_state == ProviderState.error) {
      _state = ProviderState.loaded;
    }

    _notifySafely();
  }

  /// Mark the state as updating (for create/update/delete operations)
  void setUpdating(bool isUpdating) {
    if (_disposed) return;

    _state = isUpdating ? ProviderState.updating : ProviderState.loaded;
    if (isUpdating) _error = null;

    _notifySafely();
  }

  /// Notify listeners safely. If we're in the middle of a frame build,
  /// defer the notification to the next frame to avoid the
  /// "setState() or markNeedsBuild() called during build" exception.
  void _notifySafely() {
    if (_disposed) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.transientCallbacks ||
        phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.postFrameCallbacks) {
      // We're currently building/layout/painting; schedule for next frame
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) {
          notifyListeners();
        }
      });
    } else {
      notifyListeners();
    }
  }

  /// Execute an operation with automatic loading and error state management
  ///
  /// This method:
  /// 1. Sets appropriate loading state
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
    // Set appropriate state based on current state
    setState(isRefresh ? ProviderState.refreshing : ProviderState.loading);

    try {
      final result = await operation();
      setState(ProviderState.loaded);
      return result;
    } catch (e, stackTrace) {
      final error = e is AppError
          ? e
          : AppError(
              type: ErrorType.unknown,
              message: 'Operation failed',
              details: e.toString(),
              stackTrace: stackTrace,
            );

      setState(ProviderState.error, error: error.message);
      debugPrint('BaseProviderMixin error: ${error.debugDescription}');
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
    return executeWithState<T>(operation, isRefresh: isRefresh).onError((
      e,
      stackTrace,
    ) {
      // Convert the error to an AppError with the custom message
      final error = e is AppError
          ? AppError(
              type: e.type,
              message: '$errorMessage: ${e.message}',
              details: e.details,
              statusCode: e.statusCode,
              stackTrace: e.stackTrace ?? stackTrace,
            )
          : AppError(
              type: ErrorType.unknown,
              message: errorMessage,
              details: e.toString(),
              stackTrace: stackTrace,
            );

      setState(ProviderState.error, error: error.message);
      debugPrint('BaseProviderMixin error: ${error.debugDescription}');
      return null;
    });
  }

  /// Execute an operation with automatic loading and error state management
  /// Returns a boolean indicating success or failure
  ///
  /// This is useful for operations where you only care about success/failure
  /// and don't need the result value.
  Future<bool> executeWithStateForSuccess(
    Future<void> Function() operation, {
    bool isUpdate = false,
  }) async {
    final result = await executeWithRetry(() async {
      await operation();
      return true;
    }, isUpdate: isUpdate);
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
  /// - isUpdate: Whether this is an update operation (affects the loading state)
  /// - shouldRetry: Optional callback to determine if a failed operation should be retried
  ///
  /// Returns: The result of the operation, or null if all retries failed
  Future<T?> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    Duration maxDelay = const Duration(seconds: 10),
    bool isUpdate = false,
    bool Function(dynamic error, int attempt)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    // Set initial state
    setState(isUpdate ? ProviderState.updating : ProviderState.loading);

    while (true) {
      try {
        final result = await operation();
        setState(ProviderState.loaded);
        return result;
      } catch (e, stackTrace) {
        attempt++;

        // Create appropriate error object
        final error = e is AppError
            ? e
            : AppError(
                type: ErrorType.unknown,
                message: 'Operation failed',
                details: e.toString(),
                stackTrace: stackTrace,
              );

        // Check if we should retry
        final bool willRetry =
            (shouldRetry?.call(error, attempt) ?? error.isRetryable) &&
            attempt <= maxRetries;

        if (!willRetry) {
          // No more retries or error is not retryable
          setState(ProviderState.error, error: error.message);
          debugPrint(
            'BaseProviderMixin error (attempt $attempt/$maxRetries): ${error.debugDescription}',
          );
          return null;
        }

        // Log the retry
        debugPrint(
          'BaseProviderMixin: Retrying operation (attempt $attempt/$maxRetries). Error: ${error.message}',
        );

        // Wait before retrying with exponential backoff
        await Future.delayed(delay);

        // Update delay for next retry (exponential backoff with jitter)
        delay = Duration(
          milliseconds: (delay.inMilliseconds * 1.5).toInt().clamp(
            initialDelay.inMilliseconds,
            maxDelay.inMilliseconds,
          ),
        );

        // Add some jitter to prevent thundering herd
        final jitter =
            (delay.inMilliseconds * 0.2 * (0.5 - math.Random().nextDouble()))
                .toInt();
        delay = Duration(
          milliseconds: (delay.inMilliseconds + jitter).clamp(
            initialDelay.inMilliseconds,
            maxDelay.inMilliseconds,
          ),
        );
      }
    }
  }
}
