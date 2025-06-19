import 'app_error.dart';
import 'cache_manager.dart';
import '../models/paged_result.dart';

/// Abstract repository interface for data access
abstract class Repository<T> {
  /// Get all items, optionally filtered by parameters
  Future<List<T>> getAll([Map<String, dynamic>? params]);

  /// Get a single item by ID
  Future<T> getById(String id);

  /// Create a new item
  Future<T> create(T item);

  /// Update an existing item
  Future<T> update(String id, T item);

  /// Delete an item by ID
  Future<void> delete(String id);

  /// Get paginated items
  Future<PagedResult<T>> getPaged([Map<String, dynamic>? params]);

  /// Check if an item exists
  Future<bool> exists(String id);

  /// Get the total count of items (optionally filtered)
  Future<int> count([Map<String, dynamic>? params]);

  /// Clear all cache entries for this repository
  Future<void> clearCache();

  /// Refresh a specific item in cache
  Future<T> refreshItem(String id);
}

/// Base repository implementation with caching support
abstract class BaseRepository<T, TService> implements Repository<T> {
  /// The service used for API calls
  final TService service;

  /// Cache manager for storing data
  final CacheManager cacheManager;

  /// Resource name for cache key generation (e.g., 'properties', 'users')
  String get resourceName;

  /// Default cache TTL for this repository
  Duration get defaultCacheTtl => const Duration(minutes: 15);

  /// Whether to use caching for this repository
  bool get enableCaching => true;

  BaseRepository({required this.service, required this.cacheManager});

  @override
  Future<List<T>> getAll([Map<String, dynamic>? params]) async {
    try {
      final cacheKey = _buildCacheKey('all', params);

      // Try cache first if enabled
      if (enableCaching) {
        final cached = await cacheManager.get<List<T>>(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      // Fetch from service
      final items = await fetchAllFromService(params);

      // Cache the result if enabled
      if (enableCaching) {
        await cacheManager.set(cacheKey, items, duration: defaultCacheTtl);
      }

      return items;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  @override
  Future<T> getById(String id) async {
    try {
      final cacheKey = _buildCacheKey('item', {'id': id});

      // Try cache first if enabled
      if (enableCaching) {
        final cached = await cacheManager.get<T>(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      // Fetch from service
      final item = await fetchByIdFromService(id);

      // Cache the result if enabled
      if (enableCaching) {
        await cacheManager.set(cacheKey, item, duration: defaultCacheTtl);
      }

      return item;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  @override
  Future<T> create(T item) async {
    try {
      final createdItem = await createInService(item);

      // Invalidate relevant cache entries
      await _invalidateCache();

      // Cache the new item
      if (enableCaching) {
        final id = extractIdFromItem(createdItem);
        if (id != null) {
          final cacheKey = _buildCacheKey('item', {'id': id});
          await cacheManager.set(
            cacheKey,
            createdItem,
            duration: defaultCacheTtl,
          );
        }
      }

      return createdItem;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  @override
  Future<T> update(String id, T item) async {
    try {
      final updatedItem = await updateInService(id, item);

      // Update cache
      if (enableCaching) {
        final cacheKey = _buildCacheKey('item', {'id': id});
        await cacheManager.set(
          cacheKey,
          updatedItem,
          duration: defaultCacheTtl,
        );

        // Invalidate list caches since they might contain old data
        await _invalidateListCaches();
      }

      return updatedItem;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await deleteInService(id);

      // Remove from cache
      if (enableCaching) {
        final cacheKey = _buildCacheKey('item', {'id': id});
        await cacheManager.remove(cacheKey);

        // Invalidate list caches since they might contain the deleted item
        await _invalidateListCaches();
      }
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  @override
  Future<bool> exists(String id) async {
    try {
      // Check cache first
      if (enableCaching) {
        final cacheKey = _buildCacheKey('item', {'id': id});
        final cached = await cacheManager.get<T>(cacheKey);
        if (cached != null) {
          return true;
        }
      }

      // Check service
      return await existsInService(id);
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  @override
  Future<int> count([Map<String, dynamic>? params]) async {
    try {
      final cacheKey = _buildCacheKey('count', params);

      // Try cache first if enabled
      if (enableCaching) {
        final cached = await cacheManager.get<int>(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      // Fetch from service
      final count = await countInService(params);

      // Cache the result with shorter TTL (counts change more frequently)
      if (enableCaching) {
        await cacheManager.set(
          cacheKey,
          count,
          duration: Duration(minutes: defaultCacheTtl.inMinutes ~/ 2),
        );
      }

      return count;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Clear all cache entries for this repository
  @override
  Future<void> clearCache() async {
    await cacheManager.clear(resourceName);
  }

  /// Refresh a specific item in cache
  @override
  Future<T> refreshItem(String id) async {
    if (enableCaching) {
      final cacheKey = _buildCacheKey('item', {'id': id});
      await cacheManager.remove(cacheKey);
    }
    return await getById(id);
  }

  /// Refresh all items in cache
  Future<List<T>> refreshAll([Map<String, dynamic>? params]) async {
    if (enableCaching) {
      await _invalidateListCaches();
    }
    return await getAll(params);
  }

  /// Build a cache key for this repository
  String _buildCacheKey(String operation, [Map<String, dynamic>? params]) {
    final buffer = StringBuffer();
    buffer.write('${resourceName}_$operation');

    if (params != null && params.isNotEmpty) {
      final sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );

      for (final entry in sortedParams.entries) {
        buffer.write('_${entry.key}:${entry.value}');
      }
    }

    return buffer.toString();
  }

  /// Invalidate all cache entries for this repository
  Future<void> _invalidateCache() async {
    await cacheManager.clear(resourceName);
  }

  /// Invalidate only list-related cache entries
  Future<void> _invalidateListCaches() async {
    await cacheManager.clearByRegex(RegExp('^${resourceName}_(all|count)'));
  }

  /// Get paginated items
  @override
  Future<PagedResult<T>> getPaged([Map<String, dynamic>? params]) async {
    try {
      // Caching for paginated results is often disabled to ensure freshness,
      // but can be enabled if the data is static.
      final cacheKey = _buildCacheKey('paged', params);
      if (enableCaching) {
        final cached = await cacheManager.get<PagedResult<T>>(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      final result = await fetchPagedFromService(params);

      if (enableCaching) {
        await cacheManager.set(cacheKey, result, duration: defaultCacheTtl);
      }

      return result;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  // Abstract methods that concrete repositories must implement

  /// Fetch all items from the service layer
  Future<List<T>> fetchAllFromService([Map<String, dynamic>? params]);

  /// Fetch a paginated list of items from the service layer
  Future<PagedResult<T>> fetchPagedFromService([Map<String, dynamic>? params]);

  /// Fetch a single item by ID from the service layer
  Future<T> fetchByIdFromService(String id);

  /// Create an item in the service layer
  Future<T> createInService(T item);

  /// Update an item in the service layer
  Future<T> updateInService(String id, T item);

  /// Delete an item in the service layer
  Future<void> deleteInService(String id);

  /// Check if an item exists in the service layer
  Future<bool> existsInService(String id);

  /// Get count from the service layer
  Future<int> countInService([Map<String, dynamic>? params]);

  /// Extract ID from an item (needed for caching)
  String? extractIdFromItem(T item);
}

/// Repository for read-only data
abstract class ReadOnlyRepository<T, TService> {
  /// The service used for API calls
  final TService service;

  /// Cache manager for storing data
  final CacheManager cacheManager;

  /// Resource name for cache key generation
  String get resourceName;

  /// Default cache TTL for this repository
  Duration get defaultCacheTtl => const Duration(minutes: 15);

  /// Whether to use caching for this repository
  bool get enableCaching => true;

  ReadOnlyRepository({required this.service, required this.cacheManager});

  /// Get all items, optionally filtered by parameters
  Future<List<T>> getAll([Map<String, dynamic>? params]) async {
    try {
      final cacheKey = _buildCacheKey('all', params);

      // Try cache first if enabled
      if (enableCaching) {
        final cached = await cacheManager.get<List<T>>(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      // Fetch from service
      final items = await fetchAllFromService(params);

      // Cache the result if enabled
      if (enableCaching) {
        await cacheManager.set(cacheKey, items, duration: defaultCacheTtl);
      }

      return items;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Get a single item by ID
  Future<T> getById(String id) async {
    try {
      final cacheKey = _buildCacheKey('item', {'id': id});

      // Try cache first if enabled
      if (enableCaching) {
        final cached = await cacheManager.get<T>(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      // Fetch from service
      final item = await fetchByIdFromService(id);

      // Cache the result if enabled
      if (enableCaching) {
        await cacheManager.set(cacheKey, item, duration: defaultCacheTtl);
      }

      return item;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Clear all cache entries for this repository
  Future<void> clearCache() async {
    await cacheManager.clear(resourceName);
  }

  /// Refresh a specific item in cache
  Future<T> refreshItem(String id) async {
    final cacheKey = _buildCacheKey('item', {'id': id});
    await cacheManager.remove(cacheKey);
    return await getById(id);
  }

  /// Build a cache key for this repository
  String _buildCacheKey(String operation, [Map<String, dynamic>? params]) {
    final buffer = StringBuffer();
    buffer.write('${resourceName}_$operation');

    if (params != null && params.isNotEmpty) {
      final sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );

      for (final entry in sortedParams.entries) {
        buffer.write('_${entry.key}:${entry.value}');
      }
    }

    return buffer.toString();
  }

  // Abstract methods that concrete repositories must implement

  /// Fetch all items from the service layer
  Future<List<T>> fetchAllFromService([Map<String, dynamic>? params]);

  /// Fetch a single item by ID from the service layer
  Future<T> fetchByIdFromService(String id);
}
