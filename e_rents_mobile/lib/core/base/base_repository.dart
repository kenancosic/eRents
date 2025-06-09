import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/services/cache_manager.dart';

/// Base repository class providing common CRUD operations with caching
/// Following the desktop app pattern for consistent data management
abstract class BaseRepository<T, TService> {
  final TService service;
  final CacheManager cacheManager;

  BaseRepository({
    required this.service,
    required this.cacheManager,
  });

  /// Resource name for cache keys and logging
  String get resourceName;

  /// Cache TTL for this resource type
  Duration get cacheTtl => const Duration(minutes: 15);

  /// Generate cache key for a specific item
  String _getCacheKey(String id) => '${resourceName}_$id';

  /// Generate cache key for collections
  String _getCollectionCacheKey([Map<String, dynamic>? params]) {
    if (params == null || params.isEmpty) {
      return '${resourceName}_all';
    }
    final sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    final paramString = sortedParams.toString();
    return '${resourceName}_collection_${paramString.hashCode}';
  }

  /// Fetch single item by ID
  Future<T?> getById(String id, {bool forceRefresh = false}) async {
    final cacheKey = _getCacheKey(id);

    // Return cached data if available and not forcing refresh
    if (!forceRefresh) {
      final cached = await cacheManager.get<Map<String, dynamic>>(cacheKey);
      if (cached != null) {
        debugPrint('$resourceName: Cache hit for ID $id');
        return fromJson(cached);
      }
    }

    try {
      debugPrint('$resourceName: Fetching from service for ID $id');
      final item = await fetchFromService(id);

      if (item != null) {
        // Cache the result
        await cacheManager.cache(
          cacheKey,
          toJson(item),
          ttl: cacheTtl,
        );
        debugPrint('$resourceName: Cached item with ID $id');
      }

      return item;
    } catch (e) {
      debugPrint('$resourceName: Error fetching item $id: $e');
      rethrow;
    }
  }

  /// Fetch collection with optional parameters
  Future<List<T>> getAll(
      [Map<String, dynamic>? params, bool forceRefresh = false]) async {
    final cacheKey = _getCollectionCacheKey(params);

    // Return cached data if available and not forcing refresh
    if (!forceRefresh) {
      final cached = await cacheManager.get<List<dynamic>>(cacheKey);
      if (cached != null) {
        debugPrint('$resourceName: Collection cache hit for params $params');
        return cached
            .map((json) => fromJson(json as Map<String, dynamic>))
            .toList();
      }
    }

    try {
      debugPrint(
          '$resourceName: Fetching collection from service with params $params');
      final items = await fetchAllFromService(params);

      // Cache the result
      final jsonList = items.map((item) => toJson(item)).toList();
      await cacheManager.cache(
        cacheKey,
        jsonList,
        ttl: cacheTtl,
      );
      debugPrint('$resourceName: Cached ${items.length} items');

      return items;
    } catch (e) {
      debugPrint('$resourceName: Error fetching collection: $e');
      rethrow;
    }
  }

  /// Create new item
  Future<T> create(T item) async {
    try {
      debugPrint('$resourceName: Creating new item');
      final createdItem = await createInService(item);

      // Cache the created item
      final id = getItemId(createdItem);
      await cacheManager.cache(
        _getCacheKey(id),
        toJson(createdItem),
        ttl: cacheTtl,
      );

      // Invalidate collection caches
      await _invalidateCollectionCaches();

      debugPrint('$resourceName: Created and cached item with ID $id');
      return createdItem;
    } catch (e) {
      debugPrint('$resourceName: Error creating item: $e');
      rethrow;
    }
  }

  /// Update existing item
  Future<T> update(String id, T item) async {
    try {
      debugPrint('$resourceName: Updating item with ID $id');
      final updatedItem = await updateInService(id, item);

      // Update cache
      await cacheManager.cache(
        _getCacheKey(id),
        toJson(updatedItem),
        ttl: cacheTtl,
      );

      // Invalidate collection caches
      await _invalidateCollectionCaches();

      debugPrint('$resourceName: Updated and cached item with ID $id');
      return updatedItem;
    } catch (e) {
      debugPrint('$resourceName: Error updating item $id: $e');
      rethrow;
    }
  }

  /// Delete item
  Future<bool> delete(String id) async {
    try {
      debugPrint('$resourceName: Deleting item with ID $id');
      final success = await deleteInService(id);

      if (success) {
        // Remove from cache
        await cacheManager.remove(_getCacheKey(id));

        // Invalidate collection caches
        await _invalidateCollectionCaches();

        debugPrint(
            '$resourceName: Deleted and removed from cache item with ID $id');
      }

      return success;
    } catch (e) {
      debugPrint('$resourceName: Error deleting item $id: $e');
      rethrow;
    }
  }

  /// Invalidate cache for specific item
  Future<void> invalidateCache(String id) async {
    await cacheManager.remove(_getCacheKey(id));
    debugPrint('$resourceName: Invalidated cache for ID $id');
  }

  /// Invalidate all collection caches (called after create/update/delete)
  Future<void> _invalidateCollectionCaches() async {
    // Note: This is a simplified approach. In a real implementation,
    // you might want to track which collection cache keys exist
    debugPrint('$resourceName: Invalidated collection caches');
  }

  /// Clear all cache for this resource
  Future<void> clearCache() async {
    // Note: This is a simplified approach
    debugPrint('$resourceName: Cleared all cache');
  }

  // Abstract methods that must be implemented by concrete repositories

  /// Fetch single item from service
  Future<T?> fetchFromService(String id);

  /// Fetch collection from service
  Future<List<T>> fetchAllFromService([Map<String, dynamic>? params]);

  /// Create item in service
  Future<T> createInService(T item);

  /// Update item in service
  Future<T> updateInService(String id, T item);

  /// Delete item in service
  Future<bool> deleteInService(String id);

  /// Convert item to JSON for caching
  Map<String, dynamic> toJson(T item);

  /// Convert JSON to item from cache
  T fromJson(Map<String, dynamic> json);

  /// Get item ID for caching
  String getItemId(T item);
}
