# Base Provider Architecture

This directory contains the foundation classes and mixins for reducing redundant code across all providers in the eRents desktop application.

## 📁 Files Overview

### Core Components
- **`base_provider_mixin.dart`** - State management mixin (loading, error, operations)
- **`cacheable_provider_mixin.dart`** - Caching functionality with TTL support
- **`base_provider.dart`** - Combined base class extending both mixins
- **`api_service_extensions.dart`** - Extensions for cleaner API calls

### Examples
- **`lookup_provider_refactored.dart`** - Example refactored provider
- **`auth_provider_refactored.dart`** - Complex provider refactoring example

## 🎯 Problem Solved

### Before (Redundant Code)
Every provider had duplicate code for:
```dart
// Repeated in ALL 14 providers
bool _isLoading = false;
String? _error;
void _setLoading(bool value) { /* ... */ }
void _setError(String? error) { /* ... */ }

// Manual try-catch-finally everywhere
try {
  _setLoading(true);
  _clearError();
  // API call
} catch (e) {
  _setError('Failed: $e');
} finally {
  _setLoading(false);
}

// Duplicate caching logic
final Map<String, dynamic> _cache = {};
bool _isCacheValid(String key, Duration ttl) { /* ... */ }
```

### After (Clean Architecture)
```dart
class MyProvider extends BaseProvider {
  MyProvider(super.api);
  
  Future<void> loadData() async {
    final data = await executeWithCache(
      'data_key',
      () => api.getListAndDecode('/data', DataModel.fromJson),
    );
    _processData(data);
  }
}
```

## 🚀 Usage Guide

### 1. Basic Provider
```dart
import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';

class MyProvider extends BaseProvider {
  MyProvider(super.api);
  
  List<MyModel> _items = [];
  List<MyModel> get items => _items;
  
  Future<void> loadItems() async {
    final items = await executeWithState(() async {
      return await api.getListAndDecode('/items', MyModel.fromJson);
    });
    
    if (items != null) {
      _items = items;
      notifyListeners();
    }
  }
}
```

### 2. Provider with Caching
```dart
class MyCachedProvider extends BaseProvider {
  static const String _itemsCacheKey = 'items_list';
  static const Duration _cacheTtl = Duration(minutes: 15);
  
  Future<void> loadItems({bool forceRefresh = false}) async {
    if (forceRefresh) {
      invalidateCache(_itemsCacheKey);
    }
    
    final items = await executeWithCache(
      _itemsCacheKey,
      () => api.getListAndDecode('/items', MyModel.fromJson),
      cacheTtl: _cacheTtl,
      errorMessage: 'Failed to load items',
    );
    
    if (items != null) {
      _items = items;
      notifyListeners();
    }
  }
}
```

### 3. Complex Operations
```dart
Future<bool> saveItem(MyModel item) async {
  return await executeWithStateForSuccess(() async {
    if (item.id == null) {
      // Create new
      final created = await api.postAndDecode('/items', item.toJson(), MyModel.fromJson);
      _items.add(created);
    } else {
      // Update existing
      final updated = await api.putAndDecode('/items/${item.id}', item.toJson(), MyModel.fromJson);
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) _items[index] = updated;
    }
    
    // Invalidate related cache
    invalidateCache('items_');
    notifyListeners();
  });
}
```

## 📊 Migration Benefits

### Code Reduction
- **AuthProvider**: 216 → 120 lines (44% reduction)
- **PropertiesProvider**: 721 → ~500 lines (30% reduction)
- **TenantsProvider**: 621 → ~400 lines (35% reduction)
- **Overall**: ~200-300 lines saved per provider

### Consistency Improvements
- ✅ Standardized state management
- ✅ Consistent error handling
- ✅ Unified caching strategy
- ✅ Predictable loading states
- ✅ Better testability

## 🔄 Migration Steps

### Step 1: Update Imports
```dart
// Add these imports
import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
```

### Step 2: Change Class Declaration
```dart
// Before
class MyProvider extends ChangeNotifier {
  final ApiService _api;
  bool _isLoading = false;
  String? _error;
  // ... manual state management

// After
class MyProvider extends BaseProvider {
  MyProvider(super.api);
  // State management is automatic!
```

### Step 3: Replace Manual State Management
```dart
// Before
Future<void> loadData() async {
  _setLoading(true);
  _clearError();
  try {
    final response = await _api.get('/data');
    final data = json.decode(response.body);
    _processData(data);
  } catch (e) {
    _setError('Failed to load: $e');
  } finally {
    _setLoading(false);
  }
}

// After
Future<void> loadData() async {
  final data = await executeWithState(() async {
    return await api.getListAndDecode('/data', DataModel.fromJson);
  });
  
  if (data != null) {
    _processData(data);
  }
}
```

### Step 4: Replace Manual Caching
```dart
// Before
final Map<String, dynamic> _cache = {};
final Map<String, DateTime> _cacheTimestamps = {};
bool _isCacheValid(String key, Duration ttl) { /* ... */ }

// After
// Caching is built-in! Just use:
await executeWithCache('cache_key', () => fetchOperation());
```

## 🧪 Testing

The new architecture makes testing much easier:

```dart
// Mock the ApiService
final mockApi = MockApiService();
final provider = MyProvider(mockApi);

// Test loading state
expect(provider.isLoading, false);
provider.loadData();
expect(provider.isLoading, true);

// Test error handling
when(mockApi.get(any)).thenThrow(Exception('Network error'));
await provider.loadData();
expect(provider.hasError, true);
expect(provider.error, contains('Network error'));
```

## 🔍 Debugging

### Cache Information
```dart
// Get cache statistics
final stats = provider.getCacheStats();
print('Cache entries: ${stats['totalEntries']}');
print('Valid entries: ${stats['validEntries']}');

// Clear specific cache
provider.invalidateCache('items_');

// Clear all cache
provider.invalidateCache();
```

### State Monitoring
```dart
// All providers automatically have:
print('Loading: ${provider.isLoading}');
print('Error: ${provider.error}');
print('Has Error: ${provider.hasError}');
```

## 📝 Best Practices

1. **Cache Keys**: Use descriptive, consistent naming
   ```dart
   static const String _usersCacheKey = 'users_list';
   static const String _userDetailsCacheKey = 'user_details';
   ```

2. **Cache TTL**: Choose appropriate durations
   ```dart
   static const Duration _shortCacheTtl = Duration(minutes: 5);   // Frequently changing data
   static const Duration _mediumCacheTtl = Duration(minutes: 30); // Moderate changes
   static const Duration _longCacheTtl = Duration(hours: 1);      // Rarely changing data
   ```

3. **Error Messages**: Provide user-friendly messages
   ```dart
   await executeWithCacheAndMessage(
     'data_key',
     () => fetchData(),
     'Unable to load data. Please check your connection.',
   );
   ```

4. **Cache Invalidation**: Invalidate related cache on updates
   ```dart
   // After creating/updating/deleting items
   invalidateCache('items_');
   ```

## 🎯 Next Steps

1. **Migrate Small Providers First**: Start with `lookup_provider.dart`
2. **Test Thoroughly**: Ensure behavior is identical
3. **Update Large Providers**: `properties_provider.dart`, `tenants_provider.dart`
4. **Remove Old Code**: Delete redundant state management code
5. **Update Tests**: Adapt tests to new architecture

This architecture provides a solid foundation for maintainable, consistent, and efficient provider code across the entire application.
