import 'package:flutter/foundation.dart';

/// Base mixin for provider state management
/// 
/// Provides common state management functionality that all providers need:
/// - Loading state management
/// - Error state management
/// - Convenient methods for state updates
/// - Generic operation wrapper with automatic state handling
mixin BaseProviderMixin on ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Current loading state
  bool get isLoading => _isLoading;

  /// Current error message (null if no error)
  String? get error => _error;

  /// Whether there is currently an error
  bool get hasError => _error != null;

  /// Set loading state and notify listeners
  void setLoading(bool value) {
    if (_disposed) return;
    _isLoading = value;
    if (value) {
      _error = null;
    }
    notifyListeners();
  }

  /// Set error state and notify listeners
  void setError(String? error) {
    if (_disposed) return;
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  /// Clear error state and notify listeners if there was an error
  void clearError() {
    if (_disposed) return;
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
  
  /// Execute an operation with automatic loading and error state management
  /// 
  /// This method:
  /// 1. Sets loading to true
  /// 2. Clears any existing error
  /// 3. Executes the operation
  /// 4. Handles any errors by setting error state
  /// 5. Always sets loading to false when done
  /// 
  /// Usage:
  /// ```dart
  /// await executeWithState(() async {
  ///   final data = await api.get('/endpoint');
  ///   _processData(data);
  /// });
  /// ```
  Future<T?> executeWithState<T>(Future<T> Function() operation) async {
    setLoading(true);
    try {
      final result = await operation();
      return result;
    } catch (e, stackTrace) {
      setError('Operation failed: $e');
      debugPrint('BaseProviderMixin error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    } finally {
      setLoading(false);
    }
  }
  
  /// Execute an operation with automatic loading and error state management
  /// but with custom error message
  Future<T?> executeWithStateAndMessage<T>(
    Future<T> Function() operation,
    String errorMessage,
  ) async {
    setLoading(true);
    try {
      final result = await operation();
      return result;
    } catch (e, stackTrace) {
      setError('$errorMessage: $e');
      debugPrint('BaseProviderMixin error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    } finally {
      setLoading(false);
    }
  }
  
  /// Execute an operation with automatic loading and error state management
  /// Returns success status instead of result
  Future<bool> executeWithStateForSuccess(Future<void> Function() operation) async {
    setLoading(true);
    try {
      await operation();
      return true;
    } catch (e, stackTrace) {
      setError('Operation failed: $e');
      debugPrint('BaseProviderMixin error: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    } finally {
      setLoading(false);
    }
  }
}
