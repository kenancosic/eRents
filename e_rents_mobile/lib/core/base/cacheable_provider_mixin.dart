import 'package:flutter/foundation.dart';

/// Mixin for provider caching functionality
/// 
/// Provides in-memory caching with TTL (Time To Live) support:
/// - Cache validation based on timestamps
/// - Automatic cache expiration
/// - Cache invalidation by key or prefix
/// - Generic cache operations
mixin CacheableProviderMixin {
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  /// Default cache TTL (Time To Live)
  static const Duration defaultCacheTtl = Duration(minutes: 10);
  
  /// Check if cache entry is valid based on TTL
  bool isCacheValid(String key, [Duration? ttl]) {
    ttl ??= defaultCacheTtl;
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < ttl;
  }
  
  /// Get cached value if valid, null otherwise
  T? getCache<T>(String key, [Duration? ttl]) {
    if (!isCacheValid(key, ttl)) {
      // Clean up expired cache entry
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }
    return _cache[key] as T?;
  }
  
  /// Set cache value with timestamp
  void setCache<T>(String key, T value, [Duration? ttl]) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
    
    debugPrint('CacheableProviderMixin: Cached "$key" with TTL ${ttl ?? defaultCacheTtl}');
  }
  
  /// Get cached value or execute operation and cache result
  Future<T> getCachedOrExecute<T>(
    String key,
    Future<T> Function() operation, {
    Duration? ttl,
  }) async {
    // Try to get from cache first
    final cached = getCache<T>(key, ttl);
    if (cached != null) {
      debugPrint('CacheableProviderMixin: Cache hit for "$key"');
      return cached;
    }
    
    // Execute operation and cache result
    debugPrint('CacheableProviderMixin: Cache miss for "$key", executing operation');
    final result = await operation();
    setCache(key, result, ttl);
    return result;
  }
  
  /// Invalidate cache entries
  /// If keyPrefix is null, clears all cache
  /// If keyPrefix is provided, clears only entries with keys starting with that prefix
  void invalidateCache([String? keyPrefix]) {
    if (keyPrefix == null) {
      final count = _cache.length;
      _cache.clear();
      _cacheTimestamps.clear();
      debugPrint('CacheableProviderMixin: Cleared all cache ($count entries)');
    } else {
      final keysToRemove = _cache.keys.where((k) => k.startsWith(keyPrefix)).toList();
      for (final key in keysToRemove) {
        _cache.remove(key);
        _cacheTimestamps.remove(key);
      }
      debugPrint('CacheableProviderMixin: Cleared cache entries with prefix "$keyPrefix" (${keysToRemove.length} entries)');
    }
  }
  
  /// Get all cache keys (for debugging)
  List<String> getCacheKeys() => _cache.keys.toList();
  
  /// Get cache statistics (for debugging)
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    int validEntries = 0;
    int expiredEntries = 0;
    
    for (final key in _cache.keys) {
      final timestamp = _cacheTimestamps[key];
      if (timestamp != null && now.difference(timestamp) < defaultCacheTtl) {
        validEntries++;
      } else {
        expiredEntries++;
      }
    }
    
    return {
      'totalEntries': _cache.length,
      'validEntries': validEntries,
      'expiredEntries': expiredEntries,
      'keys': _cache.keys.toList(),
    };
  }
  
  /// Clean up expired cache entries
  void cleanupExpiredCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    for (final key in _cache.keys) {
      final timestamp = _cacheTimestamps[key];
      if (timestamp == null || now.difference(timestamp) >= defaultCacheTtl) {
        keysToRemove.add(key);
      }
    }
    
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    if (keysToRemove.isNotEmpty) {
      debugPrint('CacheableProviderMixin: Cleaned up ${keysToRemove.length} expired cache entries');
    }
  }
  
  /// Generate cache key from parameters
  String generateCacheKey(String prefix, [Map<String, dynamic>? params]) {
    if (params == null || params.isEmpty) {
      return prefix;
    }
    
    // Sort parameters for consistent key generation
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    
    final paramString = sortedParams.entries
        .map((e) => '${e.key}:${e.value}')
        .join('_');
    
    return '${prefix}_$paramString';
  }
}
