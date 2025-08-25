import 'app_error.dart';

/// Enum representing the different states a provider can be in
enum ProviderState {
  /// Initial state when provider is first created
  initial,
  
  /// Loading state during async operations
  loading,
  
  /// Success state when operation completed successfully
  success,
  
  /// Error state when operation failed
  error,
  
  /// Empty state when data exists but is empty
  empty,
}

/// Extension methods for ProviderState enum
extension ProviderStateExtension on ProviderState {
  /// Check if provider is in loading state
  bool get isLoading => this == ProviderState.loading;
  
  /// Check if provider is in success state
  bool get isSuccess => this == ProviderState.success;
  
  /// Check if provider is in error state
  bool get isError => this == ProviderState.error;
  
  /// Check if provider is in initial state
  bool get isInitial => this == ProviderState.initial;
  
  /// Check if provider is in empty state
  bool get isEmpty => this == ProviderState.empty;
  
  /// Check if provider has data (success or empty)
  bool get hasData => this == ProviderState.success || this == ProviderState.empty;
  
  /// Check if provider can perform operations (not loading)
  bool get canPerformOperations => !isLoading;
}

/// Mixin that provides common state management functionality for providers
mixin StateProviderMixin {
  ProviderState _state = ProviderState.initial;
  AppError? _error;
  String? _message;

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
  
  /// Check if provider is in initial state
  bool get isInitial => _state.isInitial;
  
  /// Check if provider is in empty state
  bool get isEmpty => _state.isEmpty;
  
  /// Check if provider has data (success or empty)
  bool get hasData => _state.hasData;
  
  /// Check if provider can perform operations (not loading)
  bool get canPerformOperations => _state.canPerformOperations;

  /// Set the provider to loading state
  void setLoading() {
    _setState(ProviderState.loading);
  }

  /// Set the provider to success state with optional message
  void setSuccess([String? message]) {
    _error = null;
    _message = message;
    _setState(ProviderState.success);
  }

  /// Set the provider to error state with error and optional message
  void setError(AppError error, [String? message]) {
    _error = error;
    _message = message ?? error.message;
    _setState(ProviderState.error);
  }

  /// Set the provider to empty state with optional message
  void setEmpty([String? message]) {
    _error = null;
    _message = message;
    _setState(ProviderState.empty);
  }

  /// Set the provider to initial state
  void setInitial() {
    _error = null;
    _message = null;
    _setState(ProviderState.initial);
  }

  /// Clear error and message
  void clearError() {
    _error = null;
    _message = null;
  }

  /// Clear message only
  void clearMessage() {
    _message = null;
  }

  /// Internal method to set state - should trigger UI updates in implementing class
  void _setState(ProviderState newState) {
    _state = newState;
  }
}

/// Result wrapper for async operations
class OperationResult<T> {
  final bool isSuccess;
  final T? data;
  final AppError? error;
  final String? message;

  const OperationResult._({
    required this.isSuccess,
    this.data,
    this.error,
    this.message,
  });

  /// Create a successful result
  factory OperationResult.success(T data, [String? message]) {
    return OperationResult._(
      isSuccess: true,
      data: data,
      message: message,
    );
  }

  /// Create a failed result
  factory OperationResult.failure(AppError error, [String? message]) {
    return OperationResult._(
      isSuccess: false,
      error: error,
      message: message,
    );
  }

  /// Check if result failed
  bool get isFailure => !isSuccess;
}