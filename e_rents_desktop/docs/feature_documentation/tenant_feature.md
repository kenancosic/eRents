# eRents Desktop Application Tenant Feature Documentation

## Overview

This document provides detailed documentation for the tenant management feature in the eRents desktop application. This feature allows property managers to view, create, edit, and manage tenant information and rental agreements.

## Feature Structure

The tenant feature is organized in the `lib/features/tenants/` directory with the following structure:

```
lib/features/tenants/
├── providers/
│   ├── tenant_provider.dart
│   └── tenant_form_provider.dart
├── screens/
│   ├── tenant_list_screen.dart
│   ├── tenant_detail_screen.dart
│   └── tenant_form_screen.dart
├── widgets/
│   ├── tenant_list_item.dart
│   ├── tenant_detail_header.dart
│   └── tenant_form_fields.dart
└── models/
    └── tenant.dart
```

## Core Components

### Tenant Model

The `Tenant` model represents a rental tenant with the following key properties:

- `id`: Unique identifier
- `firstName`: Tenant's first name
- `lastName`: Tenant's last name
- `email`: Contact email
- `phone`: Contact phone number
- `dateOfBirth`: Tenant's date of birth
- `address`: Current address
- `emergencyContact`: Emergency contact information
- `idNumber`: Government ID number
- `idType`: Type of government ID
- `status`: Tenant status (active, inactive, blacklisted)
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp

### Tenant Provider

The `TenantProvider` extends `BaseProvider` and manages tenant data with caching and state management:

#### Properties

- `tenants`: List of tenants
- `selectedTenant`: Currently selected tenant
- `filter`: Current filter criteria
- `sortColumn`: Current sort column
- `sortAscending`: Sort direction

#### Methods

- `loadTenants()`: Load tenants with caching
- `loadTenant(int id)`: Load a specific tenant
- `createTenant(Tenant tenant)`: Create a new tenant
- `updateTenant(Tenant tenant)`: Update an existing tenant
- `deleteTenant(int id)`: Delete a tenant
- `applyFilter(String filter)`: Apply filter criteria
- `sortTenants(String column)`: Sort tenants by column

### Tenant Form Provider

The `TenantFormProvider` extends `BaseProvider` and manages tenant form state:

#### Properties

- `tenant`: Tenant being edited/created
- `isEditing`: Whether in edit mode
- `formKey`: Form validation key

#### Methods

- `initializeForm([Tenant? tenant])`: Initialize form with existing tenant
- `updateTenantField(String field, dynamic value)`: Update a tenant field
- `validateAndSave()`: Validate and save the form
- `resetForm()`: Reset form to initial state

## Screens

### Tenant List Screen

Displays a paginated, sortable, and filterable list of tenants using the `DesktopDataTable` widget.

#### Features

- Desktop-optimized data table
- Column sorting
- Text filtering
- Pagination
- Loading and error states
- Create new tenant button
- Tenant detail navigation

#### Implementation

```dart
// TenantListScreen widget
@override
Widget build(BuildContext context) {
  return Consumer<TenantProvider>(
    builder: (context, provider, child) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Tenants'),
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
                child: DesktopDataTable<Tenant>(
                  data: provider.tenants,
                  columns: _buildColumns(),
                  onRowTap: (tenant) => _navigateToDetail(context, tenant),
                  onSort: provider.sortTenants,
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

### Tenant Detail Screen

Displays detailed information about a specific tenant using the generic `DetailScreen` template.

#### Features

- Tenant information display
- Contact information
- Emergency contact details
- Status information
- Edit and delete actions
- Navigation back to list

#### Implementation

```dart
// TenantDetailScreen widget
@override
Widget build(BuildContext context) {
  return Consumer2<TenantProvider, TenantFormProvider>(
    builder: (context, tenantProvider, formProvider, child) {
      return DetailScreen<Tenant>(
        title: 'Tenant Details',
        item: tenantProvider.selectedTenant,
        onEdit: () => _navigateToForm(context, tenantProvider.selectedTenant),
        onDelete: () => _confirmDelete(context, tenantProvider.selectedTenant!),
        isLoading: tenantProvider.isLoading,
        error: tenantProvider.error,
        itemBuilder: (tenant) => [
          _buildTenantHeader(tenant),
          _buildTenantDetails(tenant),
          _buildEmergencyContact(tenant),
        ],
      );
    },
  );
}
```

### Tenant Form Screen

Provides a form for creating or editing tenants using the generic `FormScreen` template.

#### Features

- Form validation
- Field validation
- Contact information input
- Emergency contact input
- ID verification fields
- Save and cancel actions

#### Implementation

```dart
// TenantFormScreen widget
@override
Widget build(BuildContext context) {
  return Consumer<TenantFormProvider>(
    builder: (context, provider, child) {
      return FormScreen(
        title: provider.isEditing ? 'Edit Tenant' : 'New Tenant',
        formKey: provider.formKey,
        onSave: _saveTenant,
        onCancel: _cancelForm,
        isLoading: provider.isLoading,
        error: provider.error,
        children: [
          _buildBasicInfoFields(),
          _buildContactFields(),
          _buildIdVerificationFields(),
          _buildEmergencyContactFields(),
        ],
      );
    },
  );
}
```

## Widgets

### Tenant List Item

A custom widget for displaying tenant information in the list view.

### Tenant Detail Header

A custom widget for displaying the tenant header in the detail view with basic info.

### Tenant Form Fields

Custom form field widgets for tenant-specific inputs like contact information and ID verification.

## Integration with Base Provider Architecture

The tenant feature fully leverages the base provider architecture:

```dart
// TenantProvider using base provider features
class TenantProvider extends BaseProvider<TenantProvider> {
  final ApiService _apiService;
  List<Tenant>? _tenants;
  Tenant? _selectedTenant;
  
  TenantProvider(this._apiService);
  
  // Cached tenant list
  Future<void> loadTenants() async {
    _tenants = await executeWithCache(
      'tenants_list',
      () => executeWithState(() async {
        return await _apiService.getListAndDecode<Tenant>(
          '/api/tenants',
          Tenant.fromJson,
        );
      }),
      ttl: const Duration(minutes: 5),
    );
    notifyListeners();
  }
  
  // Uncached tenant detail
  Future<void> loadTenant(int tenantId) async {
    _selectedTenant = await executeWithState(() async {
      return await _apiService.getAndDecode<Tenant>(
        '/api/tenants/$tenantId',
        Tenant.fromJson,
      );
    });
    notifyListeners();
  }
  
  // Create with cache invalidation
  Future<Tenant?> createTenant(Tenant tenant) async {
    final createdTenant = await executeWithState(() async {
      return await _apiService.postAndDecode<Tenant>(
        '/api/tenants',
        tenant.toJson(),
        Tenant.fromJson,
      );
    });
    
    if (createdTenant != null) {
      // Invalidate cache after creation
      invalidateCache('tenants_list');
    }
    
    notifyListeners();
    return createdTenant;
  }
  
  // Update with cache invalidation
  Future<Tenant?> updateTenant(Tenant tenant) async {
    final updatedTenant = await executeWithState(() async {
      return await _apiService.putAndDecode<Tenant>(
        '/api/tenants/${tenant.id}',
        tenant.toJson(),
        Tenant.fromJson,
      );
    });
    
    if (updatedTenant != null) {
      // Invalidate relevant caches
      invalidateCache('tenants_list');
      invalidateCache('tenant_${tenant.id}');
    }
    
    notifyListeners();
    return updatedTenant;
  }
  
  // Delete with cache invalidation
  Future<bool> deleteTenant(int tenantId) async {
    final success = await executeWithStateForSuccess(() async {
      await _apiService.delete('/api/tenants/$tenantId');
      // Invalidate relevant caches
      invalidateCache('tenants_list');
      invalidateCache('tenant_$tenantId');
    });
    
    if (success) {
      // Clear selected tenant if it's the one being deleted
      if (_selectedTenant?.id == tenantId) {
        _selectedTenant = null;
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
6. **Data Privacy**: Handle tenant personal information securely
7. **Contact Information**: Validate and format contact information properly
8. **ID Verification**: Implement proper ID verification processes

## Testing

When testing the tenant feature:

```dart
// Test tenant provider
void main() {
  late TenantProvider provider;
  late MockApiService mockApiService;
  
  setUp(() {
    mockApiService = MockApiService();
    provider = TenantProvider(mockApiService);
  });
  
  test('loadTenants uses caching', () async {
    final tenants = [
      Tenant(id: 1, firstName: 'John', lastName: 'Doe', email: 'john@example.com'),
      Tenant(id: 2, firstName: 'Jane', lastName: 'Smith', email: 'jane@example.com'),
    ];
    
    when(() => mockApiService.getListAndDecode<Tenant>(
      any(),
      any(),
    )).thenAnswer((_) async => tenants);
    
    // First call should hit the API
    await provider.loadTenants();
    verify(() => mockApiService.getListAndDecode<Tenant>(
      '/api/tenants',
      any(),
    )).called(1);
    
    // Second call should use cache
    await provider.loadTenants();
    // API should still only be called once
    verify(() => mockApiService.getListAndDecode<Tenant>(
      '/api/tenants',
      any(),
    )).called(1);
    
    expect(provider.tenants, equals(tenants));
  });
  
  test('createTenant invalidates cache', () async {
    final newTenant = Tenant(id: 1, firstName: 'New', lastName: 'Tenant', email: 'new@example.com');
    
    when(() => mockApiService.postAndDecode<Tenant>(
      any(),
      any(),
      any(),
    )).thenAnswer((_) async => newTenant);
    
    await provider.createTenant(newTenant);
    
    // Cache should be invalidated
    final stats = provider.getCacheStats();
    expect(stats['tenants_list']?.invalidationCount, equals(1));
  });
}
```

This documentation ensures consistent implementation of the tenant feature and provides a solid foundation for future development.
