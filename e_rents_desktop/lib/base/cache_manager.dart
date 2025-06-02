import 'dart:async';
import 'dart:convert';
import 'app_error.dart';

/// Entry in the cache with metadata
class CacheEntry<T> {
  /// The cached data
  final T data;

  /// When this entry expires (null means no expiration)
  final DateTime? expiry;

  /// When this entry was created
  final DateTime createdAt;

  /// How many times this entry has been accessed
  int accessCount;

  /// When this entry was last accessed
  DateTime lastAccessedAt;

  /// Size of the cached data in bytes (approximate)
  final int sizeBytes;

  CacheEntry({
    required this.data,
    this.expiry,
    DateTime? createdAt,
    this.accessCount = 0,
    DateTime? lastAccessedAt,
    int? sizeBytes,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastAccessedAt = lastAccessedAt ?? DateTime.now(),
       sizeBytes = sizeBytes ?? _calculateSize(data);

  /// Checks if this cache entry has expired
  bool get isExpired {
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry!);
  }

  /// Checks if this cache entry is still valid
  bool get isValid => !isExpired;

  /// Age of the cache entry
  Duration get age => DateTime.now().difference(createdAt);

  /// Time since last access
  Duration get timeSinceLastAccess => DateTime.now().difference(lastAccessedAt);

  /// Mark this entry as accessed
  void markAccessed() {
    accessCount++;
    lastAccessedAt = DateTime.now();
  }

  /// Calculate approximate size of the data
  static int _calculateSize(dynamic data) {
    try {
      if (data is String) return data.length * 2; // Rough estimate for UTF-16
      if (data is List) return data.length * 8; // Rough estimate
      if (data is Map) return data.length * 16; // Rough estimate

      // Try to serialize to get size
      final jsonString = jsonEncode(data);
      return jsonString.length * 2;
    } catch (e) {
      return 1024; // Default 1KB if we can't calculate
    }
  }

  @override
  String toString() {
    return 'CacheEntry(data: ${data.runtimeType}, expiry: $expiry, accessCount: $accessCount)';
  }
}

/// Configuration for cache behavior
class CacheConfig {
  /// Maximum number of entries in the cache
  final int maxEntries;

  /// Maximum total size of cache in bytes
  final int maxSizeBytes;

  /// Default TTL for cache entries
  final Duration defaultTtl;

  /// Whether to enable cache statistics
  final bool enableStats;

  /// How often to run cleanup of expired entries
  final Duration cleanupInterval;

  const CacheConfig({
    this.maxEntries = 1000,
    this.maxSizeBytes = 50 * 1024 * 1024, // 50MB
    this.defaultTtl = const Duration(minutes: 15),
    this.enableStats = false,
    this.cleanupInterval = const Duration(minutes: 5),
  });
}

/// Statistics about cache performance
class CacheStats {
  int hits = 0;
  int misses = 0;
  int evictions = 0;
  int expirations = 0;
  DateTime? lastCleanup;

  double get hitRate => (hits + misses) > 0 ? hits / (hits + misses) : 0.0;

  void recordHit() => hits++;
  void recordMiss() => misses++;
  void recordEviction() => evictions++;
  void recordExpiration() => expirations++;
  void recordCleanup() => lastCleanup = DateTime.now();

  void reset() {
    hits = 0;
    misses = 0;
    evictions = 0;
    expirations = 0;
    lastCleanup = null;
  }

  @override
  String toString() {
    return 'CacheStats(hits: $hits, misses: $misses, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, evictions: $evictions)';
  }
}

/// Advanced cache manager with TTL, LRU eviction, and pattern-based invalidation
class CacheManager {
  final CacheConfig _config;
  final Map<String, CacheEntry> _cache = {};
  final CacheStats _stats = CacheStats();
  Timer? _cleanupTimer;

  CacheManager([CacheConfig? config])
    : _config = config ?? const CacheConfig() {
    _startCleanupTimer();
  }

  /// Get an item from the cache
  Future<T?> get<T>(String key) async {
    try {
      final entry = _cache[key];

      if (entry == null) {
        if (_config.enableStats) _stats.recordMiss();
        return null;
      }

      if (entry.isExpired) {
        _cache.remove(key);
        if (_config.enableStats) {
          _stats.recordMiss();
          _stats.recordExpiration();
        }
        return null;
      }

      entry.markAccessed();
      if (_config.enableStats) _stats.recordHit();

      return entry.data as T;
    } catch (e) {
      throw AppError(
        type: ErrorType.cache,
        message: 'Failed to retrieve item from cache',
        details: 'Key: $key, Error: ${e.toString()}',
      );
    }
  }

  /// Store an item in the cache
  Future<void> set<T>(
    String key,
    T data, {
    Duration? duration,
    bool overwrite = true,
  }) async {
    try {
      // Check if key exists and we shouldn't overwrite
      if (!overwrite && _cache.containsKey(key)) {
        return;
      }

      final ttl = duration ?? _config.defaultTtl;
      final expiry = ttl == Duration.zero ? null : DateTime.now().add(ttl);

      final entry = CacheEntry<T>(data: data, expiry: expiry);

      // Check cache size limits before adding
      await _ensureCacheCapacity(entry.sizeBytes);

      _cache[key] = entry;
    } catch (e) {
      throw AppError(
        type: ErrorType.cache,
        message: 'Failed to store item in cache',
        details: 'Key: $key, Error: ${e.toString()}',
      );
    }
  }

  /// Check if a key exists in the cache and is not expired
  bool contains(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  /// Remove a specific key from the cache
  Future<void> remove(String key) async {
    _cache.remove(key);
  }

  /// Clear cache entries matching a pattern
  Future<void> clear([String? pattern]) async {
    if (pattern == null) {
      _cache.clear();
      if (_config.enableStats) _stats.reset();
      return;
    }

    final keysToRemove = <String>[];
    for (final key in _cache.keys) {
      if (key.contains(pattern)) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  /// Clear cache entries matching a regex pattern
  Future<void> clearByRegex(RegExp pattern) async {
    final keysToRemove = <String>[];
    for (final key in _cache.keys) {
      if (pattern.hasMatch(key)) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  /// Clear expired entries
  Future<void> cleanup() async {
    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
      if (_config.enableStats) _stats.recordExpiration();
    }

    if (_config.enableStats) _stats.recordCleanup();
  }

  /// Get cache statistics
  CacheStats get stats => _stats;

  /// Get current cache size
  int get size => _cache.length;

  /// Get current cache size in bytes (approximate)
  int get sizeBytes {
    return _cache.values.fold(0, (sum, entry) => sum + entry.sizeBytes);
  }

  /// Get all cache keys
  List<String> get keys => _cache.keys.toList();

  /// Get cache entries for debugging
  Map<String, CacheEntry> get entries => Map.unmodifiable(_cache);

  /// Warm up the cache with predefined data
  Future<void> warmUp(Map<String, dynamic> data) async {
    for (final entry in data.entries) {
      await set(entry.key, entry.value);
    }
  }

  /// Export cache data for persistence
  Map<String, dynamic> export() {
    final result = <String, dynamic>{};

    for (final entry in _cache.entries) {
      if (entry.value.isValid) {
        result[entry.key] = {
          'data': entry.value.data,
          'expiry': entry.value.expiry?.toIso8601String(),
          'createdAt': entry.value.createdAt.toIso8601String(),
        };
      }
    }

    return result;
  }

  /// Import cache data from persistence
  Future<void> import(Map<String, dynamic> data) async {
    for (final entry in data.entries) {
      try {
        final entryData = entry.value as Map<String, dynamic>;
        final expiry =
            entryData['expiry'] != null
                ? DateTime.parse(entryData['expiry'] as String)
                : null;

        // Only import if not expired
        if (expiry == null || expiry.isAfter(DateTime.now())) {
          _cache[entry.key] = CacheEntry(
            data: entryData['data'],
            expiry: expiry,
            createdAt: DateTime.parse(entryData['createdAt'] as String),
          );
        }
      } catch (e) {
        // Skip invalid entries
        continue;
      }
    }
  }

  /// Ensure cache doesn't exceed capacity limits
  Future<void> _ensureCacheCapacity(int newEntrySize) async {
    // Check entry count limit
    while (_cache.length >= _config.maxEntries) {
      await _evictLeastRecentlyUsed();
    }

    // Check size limit
    while (sizeBytes + newEntrySize > _config.maxSizeBytes) {
      await _evictLeastRecentlyUsed();
    }
  }

  /// Evict the least recently used entry
  Future<void> _evictLeastRecentlyUsed() async {
    if (_cache.isEmpty) return;

    String? lruKey;
    DateTime? oldestAccess;

    for (final entry in _cache.entries) {
      if (oldestAccess == null ||
          entry.value.lastAccessedAt.isBefore(oldestAccess)) {
        oldestAccess = entry.value.lastAccessedAt;
        lruKey = entry.key;
      }
    }

    if (lruKey != null) {
      _cache.remove(lruKey);
      if (_config.enableStats) _stats.recordEviction();
    }
  }

  /// Start the cleanup timer
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_config.cleanupInterval, (_) => cleanup());
  }

  /// Dispose of the cache manager
  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
  }
}
