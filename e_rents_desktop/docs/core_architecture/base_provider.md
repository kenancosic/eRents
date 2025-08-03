# eRents Desktop Application BaseProvider Documentation

## Overview

This document provides detailed documentation for the `BaseProvider` class used in the eRents desktop application. The `BaseProvider` is a foundational class that provides core state management functionality for all providers in the application.

## Class Structure

The `BaseProvider` is located in the `lib/base/base_provider.dart` file and provides:

1. Core state management functionality
2. Simplified inheritance for feature providers
3. Consistent interface for all providers
4. Extensibility for feature-specific needs

## Core Properties

The `BaseProvider` provides the following properties through `BaseProviderMixin`:

- `state`: Current state of the provider (initial, loading, loaded, error, etc.)
- `error`: Error message string if an error occurred
- `isLoading`: Boolean indicating if the provider is currently loading data
- `isRefreshing`: Boolean indicating if the provider is refreshing data
- `isUpdating`: Boolean indicating if the provider is updating data
- `isLoaded`: Boolean indicating if the provider has successfully loaded data
- `hasError`: Boolean indicating if an error occurred
- `isBusy`: Boolean indicating if the provider is in a busy state (loading, refreshing, or updating)

## Core Methods

The `BaseProvider` inherits all methods from `BaseProviderMixin`:

- `executeWithState<T>()`: Execute operations with automatic state management
- `executeWithStateForSuccess()`: Execute operations with success tracking
- `clearError()`: Clear the current error state
- `setError()`: Set an error message
- `setLoading()`: Set the loading state

## Usage Examples

### Basic Provider Implementation

```dart
// A simple provider extending BaseProvider
class SimplePropertyProvider extends BaseProvider<SimplePropertyProvider> {
  final ApiService _apiService;
  List<Property>? _properties;
  
  SimplePropertyProvider(this._apiService);
  
  List<Property>? get properties => _properties;
  
  Future<void> loadProperties() async {
    _properties = await executeWithState(() async {
      return await _apiService.getListAndDecode<Property>(
        '/api/properties',
        Property.fromJson,
      );
    });
    notifyListeners();
  }
  
  Future<bool> deleteProperty(int propertyId) async {
    final success = await executeWithStateForSuccess(() async {
      await _apiService.delete('/api/properties/$propertyId');
    });
    
    if (success) {
      // Refresh the list
      await loadProperties();
    }
    
    return success;
  }
}
```

### Complex Provider Implementation

```dart
// A more complex provider with multiple operations
class ComplexPropertyProvider extends BaseProvider<ComplexPropertyProvider> {
  final ApiService _apiService;
  List<Property>? _properties;
  Property? _selectedProperty;
  
  ComplexPropertyProvider(this._apiService);
  
  List<Property>? get properties => _properties;
  Property? get selectedProperty => _selectedProperty;
  
  Future<void> loadProperties({String? filter, String? sort}) async {
    _properties = await executeWithState(() async {
      return await _apiService.getListAndDecode<Property>(
        '/api/properties',
        Property.fromJson,
      );
    });
    notifyListeners();
  }
  
  Future<void> loadProperty(int propertyId) async {
    _selectedProperty = await executeWithState(() async {
      return await _apiService.getAndDecode<Property>(
        '/api/properties/$propertyId',
        Property.fromJson,
      );
    });
    notifyListeners();
  }
  
  Future<Property?> createProperty(Property property) async {
    final createdProperty = await executeWithState(() async {
      return await _apiService.postAndDecode<Property>(
        '/api/properties',
        property.toJson(),
        Property.fromJson,
      );
    });
    
    if (createdProperty != null) {

    }
    
    notifyListeners();
    return createdProperty;
  }
  
  Future<Property?> updateProperty(Property property) async {
    final updatedProperty = await executeWithState(() async {
      return await _apiService.putAndDecode<Property>(
        '/api/properties/${property.id}',
        property.toJson(),
        Property.fromJson,
      );
    });
    
    if (updatedProperty != null) {
      // Update the selected property if it's the same
      if (_selectedProperty?.id == updatedProperty.id) {
        _selectedProperty = updatedProperty;
      }

    }
    
    notifyListeners();
    return updatedProperty;
  }
  
  Future<bool> deleteProperty(int propertyId) async {
    final success = await executeWithStateForSuccess(() async {
      await _apiService.delete('/api/properties/$propertyId');

    });
    
    if (success) {
      // Clear selected property if it's the one being deleted
      if (_selectedProperty?.id == propertyId) {
        _selectedProperty = null;
      }
      // Refresh the list
      await loadProperties();
    }
    
    notifyListeners();
    return success;
  }
}
```

## Integration with AppError

The `BaseProvider` works seamlessly with the `AppError` class for structured error handling:

```dart
// In a provider
Future<List<Property>?> loadProperties() async {
  try {
    return await executeWithCache(
      'properties_list',
      () => executeWithState(() async {
        return await _apiService.getListAndDecode<Property>(
          '/api/properties',
          Property.fromJson,
        );
      }),
      ttl: const Duration(minutes: 5),
    );
  } catch (e, s) {
    // Errors are automatically converted to AppError and handled
    rethrow;
  }
}
```

## Integration with API Service Extensions

The `BaseProvider` is designed to work seamlessly with API service extensions:

```dart
// A provider using API service extensions
class PropertyProvider extends BaseProvider<PropertyProvider> {
  final ApiService _apiService;
  
  PropertyProvider(this._apiService);
  
  // Using getListAndDecode with caching
  Future<List<Property>?> loadProperties() async {
    return await executeWithCache(
      'properties_list',
      () => _apiService.getListAndDecode<Property>(
        '/api/properties',
        Property.fromJson,
      ),
      ttl: const Duration(minutes: 5),
    );
  }
  
  // Using postAndDecode with state management
  Future<Property?> createProperty(Property property) async {
    return await executeWithState(() async {
      return await _apiService.postAndDecode<Property>(
        '/api/properties',
        property.toJson(),
        Property.fromJson,
      );
    });
  }
  
  // Using putAndDecode with state management
  Future<Property?> updateProperty(Property property) async {
    return await executeWithState(() async {
      return await _apiService.putAndDecode<Property>(
        '/api/properties/${property.id}',
        property.toJson(),
        Property.fromJson,
      );
    });
  }
  
  // Using delete with state management and cache invalidation
  Future<bool> deleteProperty(int propertyId) async {
    return await executeWithStateForSuccess(() async {
      await _apiService.delete('/api/properties/$propertyId');
      // Invalidate cache after successful deletion
      invalidateCache('properties_list');
      return true;
    });
  }
}

## Best Practices

### State Management
1. **Use executeWithState**: Always wrap operations that change state
2. **Clear Errors**: Reset error state before new operations
3. **Loading States**: Use appropriate loading states for different operations
4. **Notify Listeners**: Call `notifyListeners()` after state changes

### Error Handling
1. **User-Friendly Messages**: Provide clear error messages
2. **Error Recovery**: Allow retrying failed operations
3. **Logging**: Log errors for debugging
4. **Error States**: Clearly indicate error states in the UI

### Operation Patterns
1. **Null Safety**: Handle null return values appropriately
2. **Operation Types**: Use `executeWithStateForSuccess` for operations that don't return data
3. **State Transitions**: Ensure smooth transitions between states
4. **Cleanup**: Properly dispose of resources when no longer needed
