import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'base_provider_mixin.dart';

/// Base provider class that combines common functionality
/// 
/// This class provides:
/// - State management (loading, error) via BaseProviderMixin
/// - ApiService access
/// - Automatic cleanup on dispose
/// 
/// Usage:
/// ```dart
/// class MyProvider extends BaseProvider {
///   MyProvider(super.api);
///   
///   Future<void> loadData() async {
///     await executeWithState(() async {
///       final data = await api.getListAndDecode('/data', DataModel.fromJson);
///       _processData(data);
///     });
///   }
/// }
/// ```
abstract class BaseProvider extends ChangeNotifier with BaseProviderMixin {
  /// ApiService instance for making HTTP requests
  final ApiService api;
  
  /// Initialize the base provider with required ApiService
  BaseProvider(this.api);
  
  /// Clean up resources when the provider is disposed
  @override
  void dispose() {
    super.dispose();
  }
  
  /// Execute an operation with automatic state management
  /// 
  /// This method wraps the operation with loading/error state management.
  /// It's a convenience method that delegates to the mixin's implementation.
  /// 
  /// Usage:
  /// ```dart
  /// final data = await executeWithState(
  ///   () => api.getListAndDecode('/users', User.fromJson),
  ///   errorMessage: 'Failed to load users',
  /// );
  /// ```
  @override
  Future<T?> executeWithState<T>(
    Future<T> Function() operation, {
    bool isRefresh = false,
    String? errorMessage,
  }) async {
    if (errorMessage != null) {
      return super.executeWithStateAndMessage(operation, errorMessage, isRefresh: isRefresh);
    }
    return super.executeWithState(operation, isRefresh: isRefresh);
  }
}
