import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'base_provider_mixin.dart';
import 'cacheable_provider_mixin.dart';

/// Base provider class that combines common functionality
/// 
/// This class provides:
/// - State management (loading, error) via BaseProviderMixin
/// - Caching functionality via CacheableProviderMixin
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
abstract class BaseProvider extends ChangeNotifier 
    with BaseProviderMixin, CacheableProviderMixin {
  
  /// ApiService instance for making HTTP requests
  final ApiService api;
  
  /// Constructor requiring ApiService dependency
  BaseProvider(this.api);
  
  @override
  void dispose() {
    // Clean up cache when provider is disposed
    invalidateCache();
    super.dispose();
  }
  
  /// Convenience method for cached API operations
  /// 
  /// This combines caching with state management for common use cases.
  /// 
  /// Usage:
  /// ```dart
  /// final data = await executeWithCache(
  ///   'users_list',
  ///   () => api.getListAndDecode('/users', User.fromJson),
  /// );
  /// ```
  Future<T?> executeWithCache<T>(
    String cacheKey,
    Future<T> Function() operation, {
    Duration? cacheTtl,
    String? errorMessage,
  }) async {
    return executeWithState(() async {
      return getCachedOrExecute(cacheKey, operation, ttl: cacheTtl);
    });
  }
  
  /// Convenience method for cached API operations with custom error message
  Future<T?> executeWithCacheAndMessage<T>(
    String cacheKey,
    Future<T> Function() operation,
    String errorMessage, {
    Duration? cacheTtl,
  }) async {
    return executeWithStateAndMessage(() async {
      return getCachedOrExecute(cacheKey, operation, ttl: cacheTtl);
    }, errorMessage);
  }
  
  /// Refresh cached data by invalidating cache and re-executing operation
  Future<T?> refreshCachedData<T>(
    String cacheKey,
    Future<T> Function() operation, {
    Duration? cacheTtl,
    String? errorMessage,
  }) async {
    // Invalidate the specific cache entry
    invalidateCache(cacheKey);
    
    // Execute with cache (which will now fetch fresh data)
    return executeWithCache(cacheKey, operation, 
        cacheTtl: cacheTtl, errorMessage: errorMessage);
  }
}
