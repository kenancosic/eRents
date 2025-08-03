# eRents Desktop Application Property Feature Documentation

## Overview

This document provides detailed documentation for the property management feature in the eRents desktop application. This feature allows users to view, create, edit, and delete property listings with comprehensive data management capabilities.

## Feature Structure

The property feature is organized in the `lib/features/properties/` directory with the following structure:

```
lib/features/properties/
├── providers/
│   ├── property_provider.dart
│   └── property_form_provider.dart
├── screens/
│   ├── property_list_screen.dart
│   ├── property_detail_screen.dart
│   └── property_form_screen.dart
├── widgets/
│   ├── property_list_item.dart
│   ├── property_detail_header.dart
│   └── property_form_fields.dart
└── models/
    └── property.dart
```

## Core Components

### Property Model

The `Property` model represents a rental property with the following key properties:

- `id`: Unique identifier
- `name`: Property name
- `description`: Detailed description
- `address`: Address information
- `propertyType`: Type of property
- `bedrooms`: Number of bedrooms
- `bathrooms`: Number of bathrooms
- `squareFootage`: Size in square feet
- `rentalPrice`: Monthly rental price
- `amenities`: List of amenities
- `images`: List of image URLs
- `status`: Current status (available, rented, maintenance)
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp

### Property Provider

The `PropertyProvider` extends `BaseProvider` and manages property data with caching and state management:

#### Properties

- `properties`: List of properties
- `selectedProperty`: Currently selected property
- `filter`: Current filter criteria
- `sortColumn`: Current sort column
- `sortAscending`: Sort direction

#### Methods

- `loadProperties()`: Load properties with caching
- `loadProperty(int id)`: Load a specific property
- `createProperty(Property property)`: Create a new property
- `updateProperty(Property property)`: Update an existing property
- `deleteProperty(int id)`: Delete a property
- `applyFilter(String filter)`: Apply filter criteria
- `sortProperties(String column)`: Sort properties by column

### Property Form Provider

The `PropertyFormProvider` extends `BaseProvider` and manages property form state:

#### Properties

- `property`: Property being edited/created
- `isEditing`: Whether in edit mode
- `formKey`: Form validation key

#### Methods

- `initializeForm([Property? property])`: Initialize form with existing property
- `updatePropertyField(String field, dynamic value)`: Update a property field
- `validateAndSave()`: Validate and save the form
- `resetForm()`: Reset form to initial state

## Screens

### Property List Screen

Displays a paginated, sortable, and filterable list of properties using the `DesktopDataTable` widget.

#### Features

- Desktop-optimized data table
- Column sorting
- Text filtering
- Pagination
- Loading and error states
- Create new property button
- Property detail navigation

#### Implementation

```dart
// PropertyListScreen widget
@override
Widget build(BuildContext context) {
  return Consumer<PropertyProvider>(
    builder: (context, provider, child) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Properties'),
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => _navigateToForm(context),
            ),
          ],
        ),
        body: ContentWrapper(
          child: Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: DesktopDataTable<Property>(
                  data: provider.properties,
                  columns: _buildColumns(),
                  onRowTap: (property) => _navigateToDetail(context, property),
                  onSort: provider.sortProperties,
                  sortColumn: provider.sortColumn,
                  sortAscending: provider.sortAscending,
                  isLoading: provider.isLoading,
                  error: provider.error,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
```

### Property Detail Screen

Displays detailed information about a specific property using the generic `DetailScreen` template.

#### Features

- Property information display
- Image gallery
- Address information
- Amenities list
- Edit and delete actions
- Navigation back to list

#### Implementation

```dart
// PropertyDetailScreen widget
@override
Widget build(BuildContext context) {
  return Consumer2<PropertyProvider, PropertyFormProvider>(
    builder: (context, propertyProvider, formProvider, child) {
      return DetailScreen<Property>(
        title: 'Property Details',
        item: propertyProvider.selectedProperty,
        onEdit: () => _navigateToForm(context, propertyProvider.selectedProperty),
        onDelete: () => _confirmDelete(context, propertyProvider.selectedProperty!),
        isLoading: propertyProvider.isLoading,
        error: propertyProvider.error,
        itemBuilder: (property) => [
          _buildPropertyHeader(property),
          _buildPropertyDetails(property),
          _buildPropertyAmenities(property),
        ],
      );
    },
  );
}
```

### Property Form Screen

Provides a form for creating or editing properties using the generic `FormScreen` template.

#### Features

- Form validation
- Field validation
- Image upload
- Address input
- Amenity selection
- Save and cancel actions

#### Implementation

```dart
// PropertyFormScreen widget
@override
Widget build(BuildContext context) {
  return Consumer<PropertyFormProvider>(
    builder: (context, provider, child) {
      return FormScreen(
        title: provider.isEditing ? 'Edit Property' : 'New Property',
        formKey: provider.formKey,
        onSave: _saveProperty,
        onCancel: _cancelForm,
        isLoading: provider.isLoading,
        error: provider.error,
        children: [
          _buildBasicInfoFields(),
          _buildAddressFields(),
          _buildPropertyDetailsFields(),
          _buildAmenitiesField(),
          _buildImageUploadField(),
        ],
      );
    },
  );
}
```

## Widgets

### Property List Item

A custom widget for displaying property information in the list view.

### Property Detail Header

A custom widget for displaying the property header in the detail view with image and basic info.

### Property Form Fields

Custom form field widgets for property-specific inputs like address, amenities, and images.

## Integration with Base Provider Architecture

The property feature fully leverages the base provider architecture:

```dart
// PropertyProvider using base provider features
class PropertyProvider extends BaseProvider<PropertyProvider> {
  final ApiService _apiService;
  List<Property>? _properties;
  Property? _selectedProperty;
  
  PropertyProvider(this._apiService);
  
  // Cached property list
  Future<void> loadProperties() async {
    _properties = await executeWithCache(
      'properties_list',
      () => executeWithState(() async {
        return await _apiService.getListAndDecode<Property>(
          '/api/properties',
          Property.fromJson,
        );
      }),
      ttl: const Duration(minutes: 5),
    );
    notifyListeners();
  }
  
  // Uncached property detail
  Future<void> loadProperty(int propertyId) async {
    _selectedProperty = await executeWithState(() async {
      return await _apiService.getAndDecode<Property>(
        '/api/properties/$propertyId',
        Property.fromJson,
      );
    });
    notifyListeners();
  }
  
  // Create with cache invalidation
  Future<Property?> createProperty(Property property) async {
    final createdProperty = await executeWithState(() async {
      return await _apiService.postAndDecode<Property>(
        '/api/properties',
        property.toJson(),
        Property.fromJson,
      );
    });
    
    if (createdProperty != null) {
      // Invalidate cache after creation
      invalidateCache('properties_list');
    }
    
    notifyListeners();
    return createdProperty;
  }
  
  // Update with cache invalidation
  Future<Property?> updateProperty(Property property) async {
    final updatedProperty = await executeWithState(() async {
      return await _apiService.putAndDecode<Property>(
        '/api/properties/${property.id}',
        property.toJson(),
        Property.fromJson,
      );
    });
    
    if (updatedProperty != null) {
      // Invalidate relevant caches
      invalidateCache('properties_list');
      invalidateCache('property_${property.id}');
    }
    
    notifyListeners();
    return updatedProperty;
  }
  
  // Delete with cache invalidation
  Future<bool> deleteProperty(int propertyId) async {
    final success = await executeWithStateForSuccess(() async {
      await _apiService.delete('/api/properties/$propertyId');
      // Invalidate relevant caches
      invalidateCache('properties_list');
      invalidateCache('property_$propertyId');
    });
    
    if (success) {
      // Clear selected property if it's the one being deleted
      if (_selectedProperty?.id == propertyId) {
        _selectedProperty = null;
      }
    }
    
    notifyListeners();
    return success;
  }
}
```

## Best Practices

1. **Use Caching Strategically**: Cache list data with shorter TTL, detail data with longer TTL
2. **Invalidate Cache Appropriately**: Clear relevant cache entries after create/update/delete operations
3. **Handle Loading States**: Show loading indicators during API operations
4. **Error Handling**: Use AppError for structured error handling
5. **Form Validation**: Implement comprehensive form validation
6. **Responsive Design**: Ensure UI works well on different screen sizes
7. **Image Management**: Handle image uploads and display efficiently
8. **Navigation**: Use consistent navigation patterns between screens

## Testing

When testing the property feature:

```dart
// Test property provider
void main() {
  late PropertyProvider provider;
  late MockApiService mockApiService;
  
  setUp(() {
    mockApiService = MockApiService();
    provider = PropertyProvider(mockApiService);
  });
  
  test('loadProperties uses caching', () async {
    final properties = [
      Property(id: 1, name: 'Test Property 1'),
      Property(id: 2, name: 'Test Property 2'),
    ];
    
    when(() => mockApiService.getListAndDecode<Property>(
      any(),
      any(),
    )).thenAnswer((_) async => properties);
    
    // First call should hit the API
    await provider.loadProperties();
    verify(() => mockApiService.getListAndDecode<Property>(
      '/api/properties',
      any(),
    )).called(1);
    
    // Second call should use cache
    await provider.loadProperties();
    // API should still only be called once
    verify(() => mockApiService.getListAndDecode<Property>(
      '/api/properties',
      any(),
    )).called(1);
    
    expect(provider.properties, equals(properties));
  });
  
  test('createProperty invalidates cache', () async {
    final newProperty = Property(id: 1, name: 'New Property');
    
    when(() => mockApiService.postAndDecode<Property>(
      any(),
      any(),
      any(),
    )).thenAnswer((_) async => newProperty);
    
    await provider.createProperty(newProperty);
    
    // Cache should be invalidated
    final stats = provider.getCacheStats();
    expect(stats['properties_list']?.invalidationCount, equals(1));
  });
}
```

This documentation ensures consistent implementation of the property feature and provides a solid foundation for future development.
