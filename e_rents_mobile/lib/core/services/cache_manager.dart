import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Cache entry with TTL (Time To Live) functionality
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration? ttl;

  CacheEntry({
    required this.data,
    required this.timestamp,
    this.ttl,
  });

  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().difference(timestamp) > ttl!;
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'ttl': ttl?.inMilliseconds,
    };
  }

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      ttl: json['ttl'] != null ? Duration(milliseconds: json['ttl']) : null,
    );
  }
}

/// Advanced cache manager with TTL, memory management, and automatic cleanup
/// Following the desktop app pattern for better performance
class CacheManager {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Map<String, CacheEntry> _memoryCache = {};
  final Map<String, DateTime> _lastAccessed = {};

  // Cache configuration
  static const int maxMemoryEntries = 100;
  static const Duration defaultTtl = Duration(minutes: 15);
  static const Duration cleanupInterval = Duration(minutes: 5);

  DateTime? _lastCleanup;

  /// Cache data with optional TTL
  Future<void> cache<T>(
    String key,
    T data, {
    Duration? ttl,
    bool memoryOnly = false,
  }) async {
    final entry = CacheEntry<T>(
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl ?? defaultTtl,
    );

    // Store in memory cache
    _memoryCache[key] = entry;
    _lastAccessed[key] = DateTime.now();

    // Persist to secure storage if not memory-only
    if (!memoryOnly) {
      try {
        final jsonString = jsonEncode(entry.toJson());
        await _storage.write(key: 'cache_$key', value: jsonString);
      } catch (e) {
        debugPrint('CacheManager: Failed to persist cache entry $key: $e');
      }
    }

    // Trigger cleanup if needed
    _maybeCleanup();
  }

  /// Get cached data
  Future<T?> get<T>(String key) async {
    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      final entry = _memoryCache[key]!;

      if (entry.isExpired) {
        await _remove(key);
        return null;
      }

      _lastAccessed[key] = DateTime.now();
      return entry.data as T?;
    }

    // Check persistent storage
    try {
      final jsonString = await _storage.read(key: 'cache_$key');
      if (jsonString != null) {
        final entry = CacheEntry.fromJson(jsonDecode(jsonString));

        if (entry.isExpired) {
          await _remove(key);
          return null;
        }

        // Restore to memory cache
        _memoryCache[key] = entry;
        _lastAccessed[key] = DateTime.now();

        return entry.data as T?;
      }
    } catch (e) {
      debugPrint('CacheManager: Failed to read cache entry $key: $e');
    }

    return null;
  }

  /// Check if key exists and is not expired
  Future<bool> has(String key) async {
    final data = await get(key);
    return data != null;
  }

  /// Remove specific cache entry
  Future<void> remove(String key) async {
    await _remove(key);
  }

  Future<void> _remove(String key) async {
    _memoryCache.remove(key);
    _lastAccessed.remove(key);

    try {
      await _storage.delete(key: 'cache_$key');
    } catch (e) {
      debugPrint('CacheManager: Failed to remove cache entry $key: $e');
    }
  }

  /// Clear all cache
  Future<void> clear() async {
    _memoryCache.clear();
    _lastAccessed.clear();

    try {
      // Clear all cache entries from secure storage
      final allKeys = await _storage.readAll();
      final cacheKeys = allKeys.keys.where((key) => key.startsWith('cache_'));

      for (final key in cacheKeys) {
        await _storage.delete(key: key);
      }
    } catch (e) {
      debugPrint('CacheManager: Failed to clear persistent cache: $e');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    int expiredCount = 0;

    for (final entry in _memoryCache.values) {
      if (entry.isExpired) expiredCount++;
    }

    return {
      'memoryEntries': _memoryCache.length,
      'expiredEntries': expiredCount,
      'lastCleanup': _lastCleanup?.toIso8601String(),
      'maxMemoryEntries': maxMemoryEntries,
    };
  }

  /// Cleanup expired entries and manage memory
  void _maybeCleanup() {
    final now = DateTime.now();

    // Skip if cleaned up recently
    if (_lastCleanup != null &&
        now.difference(_lastCleanup!) < cleanupInterval) {
      return;
    }

    _lastCleanup = now;

    // Remove expired entries
    final expiredKeys = <String>[];
    for (final entry in _memoryCache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _remove(key);
    }

    // Manage memory usage
    if (_memoryCache.length > maxMemoryEntries) {
      final sortedByAccess = _lastAccessed.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      final keysToRemove = sortedByAccess
          .take(_memoryCache.length - maxMemoryEntries)
          .map((e) => e.key)
          .toList();

      for (final key in keysToRemove) {
        _memoryCache.remove(key);
        _lastAccessed.remove(key);
      }
    }

    debugPrint(
        'CacheManager: Cleanup completed. Memory entries: ${_memoryCache.length}');
  }

  /// Force cleanup
  Future<void> cleanup() async {
    _lastCleanup = null;
    _maybeCleanup();
  }
}
