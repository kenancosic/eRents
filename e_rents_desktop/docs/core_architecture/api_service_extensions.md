# eRents Desktop Application API Service Extensions Documentation

## Overview

This document provides detailed documentation for the API service extensions used in the eRents desktop application. These extensions enhance the base `ApiService` with type-safe methods for common API operations, automatic JSON decoding, and streamlined error handling.

## Extensions Structure

The API service extensions are located in the `lib/base/api_service_extensions.dart` file and provide:

1. Type-safe API call methods
2. Automatic JSON decoding
3. Standardized error handling
4. Integration with the base provider architecture

## Core Extension Methods

### getListAndDecode<T>

Fetches a list of items from an API endpoint and automatically decodes the JSON response into a list of typed objects.

```dart
Future<List<T>?> getListAndDecode<T>(
  String endpoint,
  T Function(Map<String, dynamic>) decoder, {
  Map<String, String>? customHeaders,
})
```

**Parameters:**
- `endpoint`: The API endpoint to call
- `decoder`: A function that converts a JSON map to a typed object
- `customHeaders`: Optional custom headers to include in the request

**Returns:**
- `Future<List<T>?>`: A future that resolves to a list of typed objects or null if an error occurs

**Usage Example:**
```dart
final properties = await apiService.getListAndDecode<Property>(
  '/api/properties',
  (json) => Property.fromJson(json),
);
```

### getAndDecode<T>

Fetches a single item from an API endpoint and automatically decodes the JSON response into a typed object.

```dart
Future<T?> getAndDecode<T>(
  String endpoint,
  T Function(Map<String, dynamic>) decoder, {
  Map<String, String>? customHeaders,
})
```

**Parameters:**
- `endpoint`: The API endpoint to call
- `decoder`: A function that converts a JSON map to a typed object
- `customHeaders`: Optional custom headers to include in the request

**Returns:**
- `Future<T?>`: A future that resolves to a typed object or null if an error occurs

**Usage Example:**
```dart
final property = await apiService.getAndDecode<Property>(
  '/api/properties/1',
  (json) => Property.fromJson(json),
);
```

### postAndDecode<T>

Sends a POST request to an API endpoint with data and automatically decodes the JSON response into a typed object.

```dart
Future<T?> postAndDecode<T>(
  String endpoint,
  Map<String, dynamic> data,
  T Function(Map<String, dynamic>) decoder, {
  Map<String, String>? customHeaders,
})
```

**Parameters:**
- `endpoint`: The API endpoint to call
- `data`: The data to send in the request body
- `decoder`: A function that converts a JSON map to a typed object
- `customHeaders`: Optional custom headers to include in the request

**Returns:**
- `Future<T?>`: A future that resolves to a typed object or null if an error occurs

**Usage Example:**
```dart
final newProperty = Property(name: 'New Property', price: 1000);
final createdProperty = await apiService.postAndDecode<Property>(
  '/api/properties',
  newProperty.toJson(),
  (json) => Property.fromJson(json),
);
```

### putAndDecode<T>

Sends a PUT request to an API endpoint with data and automatically decodes the JSON response into a typed object.

```dart
Future<T?> putAndDecode<T>(
  String endpoint,
  Map<String, dynamic> data,
  T Function(Map<String, dynamic>) decoder, {
  Map<String, String>? customHeaders,
})
```

**Parameters:**
- `endpoint`: The API endpoint to call
- `data`: The data to send in the request body
- `decoder`: A function that converts a JSON map to a typed object
- `customHeaders`: Optional custom headers to include in the request

**Returns:**
- `Future<T?>`: A future that resolves to a typed object or null if an error occurs

**Usage Example:**
```dart
final updatedProperty = Property(id: 1, name: 'Updated Property', price: 1500);
final result = await apiService.putAndDecode<Property>(
  '/api/properties/1',
  updatedProperty.toJson(),
  (json) => Property.fromJson(json),
);
```

### deleteAndDecode<T>

Sends a DELETE request to an API endpoint and automatically decodes the JSON response into a typed object.

```dart
Future<T?> deleteAndDecode<T>(
  String endpoint,
  T Function(Map<String, dynamic>) decoder, {
  Map<String, String>? customHeaders,
})
```

**Parameters:**
- `endpoint`: The API endpoint to call
- `decoder`: A function that converts a JSON map to a typed object
- `customHeaders`: Optional custom headers to include in the request

**Returns:**
- `Future<T?>`: A future that resolves to a typed object or null if an error occurs

**Usage Example:**
```dart
final deletedProperty = await apiService.deleteAndDecode<Property>(
  '/api/properties/1',
  (json) => Property.fromJson(json),
);
```

## Integration with Base Provider Architecture

The API service extensions are designed to work seamlessly with the base provider architecture:

```dart
// In a provider that extends BaseProvider
class PropertyProvider extends BaseProvider<PropertyProvider> {
  final ApiService _apiService;
  
  PropertyProvider(this._apiService);
  
  // Using getListAndDecode with state management
  Future<List<Property>?> loadProperties() async {
    return await executeWithState(() async {
      return await _apiService.getListAndDecode<Property>(
        '/api/properties',
        Property.fromJson,
      );
    });
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
  
  // Using delete with state management
  Future<bool> deleteProperty(int propertyId) async {
    return await executeWithStateForSuccess(() async {
      await _apiService.delete('/api/properties/$propertyId');
      return true;
    });
  }
}
```

## Error Handling

The API service extensions automatically handle errors by:

1. Converting HTTP errors to `AppError` instances
2. Providing user-friendly error messages
3. Maintaining detailed error information for debugging
4. Supporting retry mechanisms through the base provider architecture

```dart
// Error handling in a provider
Future<List<Property>?> loadProperties() async {
  try {
    return await _apiService.getListAndDecode<Property>(
      '/api/properties',
      Property.fromJson,
    );
  } catch (e) {
    // Errors are automatically converted to AppError and handled by BaseProvider
    rethrow;
  }
}
```

## Best Practices

1. **Use Type-Safe Methods**: Always use the extension methods for type safety
2. **Handle State Properly**: Use `executeWithState` for operations that change UI state
3. **Error Handling**: Let the base provider architecture handle errors automatically
6. **Decoder Functions**: Create reusable decoder functions for complex objects
7. **Custom Headers**: Use custom headers only when necessary for special cases

## Example Decoder Functions

```dart
// Simple decoder
Property Property.fromJson(Map<String, dynamic> json) {
  return Property(
    id: json['id'] as int,
    name: json['name'] as String,
    price: json['price'] as double,
  );
}

// Complex decoder with nested objects
User User.fromJson(Map<String, dynamic> json) {
  return User(
    id: json['id'] as int,
    name: json['name'] as String,
    address: json['address'] != null 
        ? Address.fromJson(json['address'] as Map<String, dynamic>)
        : null,
    properties: (json['properties'] as List<dynamic>?)
        ?.map((e) => Property.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
```

## Testing

When testing providers that use API service extensions:

```dart
// Mock the API service and its extensions
class MockApiService extends Mock implements ApiService {
  @override
  Future<List<T>?> getListAndDecode<T>(
    String endpoint,
    T Function(Map<String, dynamic>) decoder, {
    Map<String, String>? customHeaders,
  }) async {
    // Return mock data
    return [
      // Mock objects
    ];
  }
}

// Test the provider
void main() {
  late PropertyProvider provider;
  late MockApiService mockApiService;
  
  setUp(() {
    mockApiService = MockApiService();
    provider = PropertyProvider(mockApiService);
  });
  
  test('loadProperties fetches properties', () async {
    // Test implementation
  });
}
```

This documentation ensures consistent implementation of API service extensions and provides a solid foundation for future development.
