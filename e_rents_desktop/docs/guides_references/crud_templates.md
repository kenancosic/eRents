# eRents Desktop Application CRUD Templates Documentation

## Overview

This document provides documentation for the CRUD (Create, Read, Update, Delete) templates used in the eRents desktop application. These generic templates provide reusable UI components for common CRUD operations, following Material 3 design principles optimized for desktop UI.

## Template Structure

The CRUD templates are located in the `lib/base/crud/` directory and include:

1. `list_screen.dart` - Generic list screen template
2. `detail_screen.dart` - Generic detail screen template
3. `form_screen.dart` - Generic form screen template

## List Screen Template

A generic list screen template that provides common functionality for displaying lists of items with sorting, filtering, pagination, and navigation capabilities.

### Features

1. **Generic Implementation**: Works with any data type T
2. **Pagination Support**: Built-in pagination with infinite scrolling
3. **Search Functionality**: Dialog-based search with filtering
4. **Filter Support**: Custom filter panels
5. **Sorting**: Client-side sorting capabilities
6. **Loading States**: Built-in loading indicators
7. **Error Handling**: Error display with retry functionality
8. **Empty States**: Customizable empty messages
9. **Refresh**: Pull-to-refresh and toolbar refresh
10. **Navigation**: Item tap navigation support

### Usage

```dart
ListScreen<MyModel>(
  title: 'My Items',
  fetchItems: (page, pageSize, filters) async {
    // Fetch items from provider or API
    return await myProvider.loadItems();
  },
  itemBuilder: (context, item) {
    return ListTile(
      title: Text(item.name),
      subtitle: Text(item.description),
    );
  },
  onItemTap: (item) => _navigateToDetail(item),
  enablePagination: true,
  pageSize: 20,
  showSearch: true,
  showFilters: true,
  filterWidget: MyFilterWidget(),
)
```

### Parameters

- `title`: The title to display in the app bar
- `itemBuilder`: Function to build individual list items
- `fetchItems`: Function to fetch items with optional pagination parameters
- `onItemTap`: Function to navigate to the detail view for an item
- `sortFunction`: Optional function to sort items client-side
- `filterFunction`: Optional function to filter items client-side
- `enablePagination`: Whether to enable pagination
- `pageSize`: Page size for pagination
- `showSearch`: Whether to show search functionality
- `showFilters`: Whether to show filter functionality
- `filterWidget`: Custom filter widget to display in the filter panel

## Form Screen Template

A generic form screen template that provides common functionality for creating and editing items with comprehensive validation and submission lifecycle management.

### Features

1. **Generic Implementation**: Works with any data type T
2. **Create/Edit Mode**: Automatic mode detection based on initial item
3. **Form Validation**: Built-in form validation with autovalidate
4. **Loading States**: Submission loading indicators
5. **Error Handling**: Validation and submission error display
6. **Reset Functionality**: Form reset capability
7. **Custom Actions**: Configurable action buttons
8. **Focus Management**: Focus traversal support
9. **Lifecycle Management**: Complete form submission lifecycle

### Usage

```dart
FormScreen<MyModel>(
  title: isEditing ? 'Edit Item' : 'Create Item',
  initialItem: isEditing ? existingItem : null,
  formBuilder: (context, item, formKey) {
    return MyFormFields(item: item, onUpdate: _updateItem);
  },
  validator: (item) {
    if (item.name.isEmpty) return 'Name is required';
    return null;
  },
  onSubmit: (item) async {
    return await myProvider.saveItem(item);
  },
  createNewItem: () => MyModel(),
  updateItem: (item) => item.copyWith(),
  showSaveButton: true,
  showResetButton: true,
)
```

### Parameters

- `title`: The title to display in the app bar
- `initialItem`: The initial item for the form (null for create mode)
- `formBuilder`: Function to build the form fields
- `validator`: Function to validate the form
- `onSubmit`: Function to submit the form data
- `createNewItem`: Function to build a new item from form data
- `updateItem`: Function to update an existing item with form data
- `showSaveButton`: Whether to show a save button
- `saveButtonText`: Custom save button text
- `showResetButton`: Whether to show a reset button
- `resetButtonText`: Custom reset button text
- `autovalidate`: Whether to automatically validate the form
- `enableFocusTraversal`: Whether to enable form field focus traversal
- `submitButtonBuilder`: Custom submit button builder
- `onValidationError`: Custom validation error handler

## Detail Screen Template

A generic detail screen template that provides common functionality for displaying detailed information about an item with a master-detail layout pattern.

### Features

1. **Generic Implementation**: Works with any data type T
2. **Master-Detail Layout**: Optional master-detail layout for desktop
3. **Refresh Functionality**: Item refresh capability
4. **Edit Navigation**: Direct navigation to edit screen
5. **Loading States**: Built-in loading indicators
6. **Error Handling**: Error display with retry functionality
7. **Custom Actions**: Additional action button support
8. **Flexible Layout**: Support for both simple and master-detail layouts

### Usage

```dart
DetailScreen<MyModel>(
  title: 'Item Details',
  item: myItem,
  detailBuilder: (context, item) {
    return MyDetailView(item: item);
  },
  onEdit: (item) => _navigateToEdit(item),
  fetchItem: (id) async {
    return await myProvider.loadItem(int.parse(id));
  },
  itemId: myItem.id.toString(),
  useMasterDetailLayout: true,
  masterWidget: MyMasterWidget(),
)
```

### Parameters

- `title`: The title to display in the app bar
- `item`: The item to display details for
- `fetchItem`: Function to fetch an item by ID (for refresh functionality)
- `itemId`: The ID of the item (for refresh functionality)
- `detailBuilder`: Function to build the detail view
- `onEdit`: Function to navigate to the edit view
- `showActions`: Whether to show action buttons
- `additionalActions`: Additional action buttons to display
- `useMasterDetailLayout`: Whether to use a master-detail layout
- `masterWidget`: Master widget for master-detail layout

## Template Integration

### With Providers

The CRUD templates integrate seamlessly with the base provider architecture:

```dart
// In a feature provider
Future<List<Property>?> loadProperties() async {
  return executeWithCache(
    'properties_list',
    () => api.getListAndDecode('/api/properties', Property.fromJson),
    cacheTtl: const Duration(minutes: 5),
  );
}

Future<Property?> saveProperty(Property property) async {
  return executeWithState(() async {
    if (property.propertyId == 0) {
      return await api.postAndDecode(
        '/api/properties',
        property.toJson(),
        Property.fromJson,
      );
    } else {
      return await api.putAndDecode(
        '/api/properties/${property.propertyId}',
        property.toJson(),
        Property.fromJson,
      );
    }
  });
}
```

### In Screens

Features use the templates in their screens:

```dart
// List screen using the template
class PropertyListScreen extends StatelessWidget {
  const PropertyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListScreen<Property>(
      title: 'Properties',
      fetchItems: (page, pageSize, filters) async {
        final provider = Provider.of<PropertyProvider>(context, listen: false);
        return await provider.loadProperties() ?? [];
      },
      itemBuilder: (context, property) {
        return PropertyCard(property: property);
      },
      onItemTap: (property) {
        context.pushNamed(AppRoutes.propertyDetail, extra: property);
      },
    );
  }
}

// Form screen using the template
class PropertyFormScreen extends StatelessWidget {
  final Property? property;
  
  const PropertyFormScreen({super.key, this.property});

  @override
  Widget build(BuildContext context) {
    return FormScreen<Property>(
      title: property == null ? 'Add Property' : 'Edit Property',
      initialItem: property,
      formBuilder: (context, item, formKey) {
        return PropertyFormFields(
          property: item!,
          onChanged: (updatedProperty) {
            // Update the form item
          },
        );
      },
      validator: (property) {
        if (property.name.isEmpty) return 'Name is required';
        if (property.price <= 0) return 'Price must be greater than 0';
        return null;
      },
      onSubmit: (property) async {
        final provider = Provider.of<PropertyProvider>(context, listen: false);
        final result = await provider.createProperty(property);
        return result != null;
      },
      createNewItem: () => Property(),
    );
  }
}
```

## Best Practices

1. **Template Usage**: Use templates for consistent CRUD operations
2. **Customization**: Customize templates with parameters rather than inheritance
3. **Validation**: Implement comprehensive form validation
4. **Error Handling**: Provide user-friendly error messages
5. **Loading States**: Show visual feedback during operations
6. **Pagination**: Use pagination for large datasets
7. **Search/Filter**: Implement search and filter for better UX
8. **Master-Detail**: Use master-detail layout for complex data relationships
9. **Provider Integration**: Integrate templates with provider architecture
10. **Navigation**: Implement consistent navigation patterns

## Extensibility

The CRUD templates support easy extension:

1. **Custom Templates**: Create feature-specific template variations
2. **Template Parameters**: Add new parameters for additional functionality
3. **Widget Composition**: Combine templates with custom widgets
4. **Provider Integration**: Extend provider integration patterns
5. **Layout Variations**: Create new layout templates
6. **Functionality Extensions**: Add new features to existing templates

This CRUD template documentation ensures consistent implementation of common CRUD operations across the application and provides a solid foundation for future development.
