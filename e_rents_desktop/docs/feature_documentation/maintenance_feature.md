# eRents Desktop Application Maintenance Feature Documentation

## Overview

This document provides detailed documentation for the maintenance management feature in the eRents desktop application. This feature allows property managers to track, schedule, and manage maintenance requests and issues for properties.

## Feature Structure

The maintenance feature is organized in the `lib/features/maintenance/` directory with the following structure:

```
lib/features/maintenance/
├── providers/
│   ├── maintenance_provider.dart
│   └── maintenance_form_provider.dart
├── screens/
│   ├── maintenance_list_screen.dart
│   ├── maintenance_detail_screen.dart
│   └── maintenance_form_screen.dart
├── widgets/
│   ├── maintenance_list_item.dart
│   ├── maintenance_detail_header.dart
│   └── maintenance_form_fields.dart
└── models/
    └── maintenance_issue.dart
```

## Core Components

### Maintenance Issue Model

The `MaintenanceIssue` model represents a maintenance request or issue with the following key properties:

- `id`: Unique identifier
- `propertyId`: Associated property ID
- `tenantId`: Associated tenant ID (if applicable)
- `title`: Issue title
- `description`: Detailed description
- `priority`: Issue priority (low, medium, high, urgent)
- `status`: Issue status (open, in-progress, completed, cancelled)
- `assignedTo`: Assigned maintenance personnel
- `reportedDate`: Date issue was reported
- `dueDate`: Expected completion date
- `completedDate`: Actual completion date
- `cost`: Maintenance cost
- `notes`: Additional notes
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp

### Maintenance Provider

The `MaintenanceProvider` extends `BaseProvider` and manages maintenance data with caching and state management:

#### Properties

- `maintenanceIssues`: List of maintenance issues
- `selectedMaintenanceIssue`: Currently selected maintenance issue
- `filter`: Current filter criteria
- `sortColumn`: Current sort column
- `sortAscending`: Sort direction

#### Methods

- `loadMaintenanceIssues()`: Load maintenance issues with caching
- `loadMaintenanceIssue(int id)`: Load a specific maintenance issue
- `createMaintenanceIssue(MaintenanceIssue issue)`: Create a new maintenance issue
- `updateMaintenanceIssue(MaintenanceIssue issue)`: Update an existing maintenance issue
- `deleteMaintenanceIssue(int id)`: Delete a maintenance issue
- `applyFilter(String filter)`: Apply filter criteria
- `sortMaintenanceIssues(String column)`: Sort maintenance issues by column

### Maintenance Form Provider

The `MaintenanceFormProvider` extends `BaseProvider` and manages maintenance form state:

#### Properties

- `maintenanceIssue`: Maintenance issue being edited/created
- `isEditing`: Whether in edit mode
- `formKey`: Form validation key

#### Methods

- `initializeForm([MaintenanceIssue? issue])`: Initialize form with existing maintenance issue
- `updateMaintenanceField(String field, dynamic value)`: Update a maintenance field
- `validateAndSave()`: Validate and save the form
- `resetForm()`: Reset form to initial state

## Screens

### Maintenance List Screen

Displays a paginated, sortable, and filterable list of maintenance issues using the `DesktopDataTable` widget.

#### Features

- Desktop-optimized data table
- Column sorting
- Text filtering
- Pagination
- Loading and error states
- Create new maintenance issue button
- Maintenance issue detail navigation

#### Implementation

```dart
// MaintenanceListScreen widget
@override
Widget build(BuildContext context) {
  return Consumer<MaintenanceProvider>(
    builder: (context, provider, child) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Maintenance Issues'),
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
                child: DesktopDataTable<MaintenanceIssue>(
                  data: provider.maintenanceIssues,
                  columns: _buildColumns(),
                  onRowTap: (issue) => _navigateToDetail(context, issue),
                  onSort: provider.sortMaintenanceIssues,
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

### Maintenance Detail Screen

Displays detailed information about a specific maintenance issue using the generic `DetailScreen` template.

#### Features

- Maintenance issue information display
- Property and tenant information
- Priority and status information
- Timeline and dates
- Cost and notes
- Edit and delete actions
- Navigation back to list

#### Implementation

```dart
// MaintenanceDetailScreen widget
@override
Widget build(BuildContext context) {
  return Consumer2<MaintenanceProvider, MaintenanceFormProvider>(
    builder: (context, maintenanceProvider, formProvider, child) {
      return DetailScreen<MaintenanceIssue>(
        title: 'Maintenance Issue Details',
        item: maintenanceProvider.selectedMaintenanceIssue,
        onEdit: () => _navigateToForm(context, maintenanceProvider.selectedMaintenanceIssue),
        onDelete: () => _confirmDelete(context, maintenanceProvider.selectedMaintenanceIssue!),
        isLoading: maintenanceProvider.isLoading,
        error: maintenanceProvider.error,
        itemBuilder: (issue) => [
          _buildMaintenanceHeader(issue),
          _buildMaintenanceDetails(issue),
          _buildTimelineDetails(issue),
        ],
      );
    },
  );
}
```

### Maintenance Form Screen

Provides a form for creating or editing maintenance issues using the generic `FormScreen` template.

#### Features

- Form validation
- Issue title and description
- Priority and status selection
- Property and tenant selection
- Assignment and dates
- Cost tracking
- Save and cancel actions

#### Implementation

```dart
// MaintenanceFormScreen widget
@override
Widget build(BuildContext context) {
  return Consumer<MaintenanceFormProvider>(
    builder: (context, provider, child) {
      return FormScreen(
        title: provider.isEditing ? 'Edit Maintenance Issue' : 'New Maintenance Issue',
        formKey: provider.formKey,
        onSave: _saveMaintenanceIssue,
        onCancel: _cancelForm,
        isLoading: provider.isLoading,
        error: provider.error,
        children: [
          _buildBasicInfoFields(),
          _buildPropertyTenantFields(),
          _buildPriorityStatusFields(),
          _buildAssignmentFields(),
          _buildDateFields(),
          _buildCostNotesFields(),
        ],
      );
    },
  );
}
```

## Widgets

### Maintenance List Item

A custom widget for displaying maintenance issue information in the list view.

### Maintenance Detail Header

A custom widget for displaying the maintenance issue header in the detail view with basic info.

### Maintenance Form Fields

Custom form field widgets for maintenance-specific inputs like priority selection and assignment.

## Integration with Base Provider Architecture

The maintenance feature fully leverages the base provider architecture:

```dart
// MaintenanceProvider using base provider features
class MaintenanceProvider extends BaseProvider<MaintenanceProvider> {
  final ApiService _apiService;
  List<MaintenanceIssue>? _maintenanceIssues;
  MaintenanceIssue? _selectedMaintenanceIssue;
  
  MaintenanceProvider(this._apiService);
  
  // Cached maintenance issues list
  Future<void> loadMaintenanceIssues() async {
    _maintenanceIssues = await executeWithCache(
      'maintenance_issues_list',
      () => executeWithState(() async {
        return await _apiService.getListAndDecode<MaintenanceIssue>(
          '/api/maintenance',
          MaintenanceIssue.fromJson,
        );
      }),
      ttl: const Duration(minutes: 5),
    );
    notifyListeners();
  }
  
  // Uncached maintenance issue detail
  Future<void> loadMaintenanceIssue(int issueId) async {
    _selectedMaintenanceIssue = await executeWithState(() async {
      return await _apiService.getAndDecode<MaintenanceIssue>(
        '/api/maintenance/$issueId',
        MaintenanceIssue.fromJson,
      );
    });
    notifyListeners();
  }
  
  // Create with cache invalidation
  Future<MaintenanceIssue?> createMaintenanceIssue(MaintenanceIssue issue) async {
    final createdIssue = await executeWithState(() async {
      return await _apiService.postAndDecode<MaintenanceIssue>(
        '/api/maintenance',
        issue.toJson(),
        MaintenanceIssue.fromJson,
      );
    });
    
    if (createdIssue != null) {
      // Invalidate cache after creation
      invalidateCache('maintenance_issues_list');
    }
    
    notifyListeners();
    return createdIssue;
  }
  
  // Update with cache invalidation
  Future<MaintenanceIssue?> updateMaintenanceIssue(MaintenanceIssue issue) async {
    final updatedIssue = await executeWithState(() async {
      return await _apiService.putAndDecode<MaintenanceIssue>(
        '/api/maintenance/${issue.id}',
        issue.toJson(),
        MaintenanceIssue.fromJson,
      );
    });
    
    if (updatedIssue != null) {
      // Invalidate relevant caches
      invalidateCache('maintenance_issues_list');
      invalidateCache('maintenance_issue_${issue.id}');
    }
    
    notifyListeners();
    return updatedIssue;
  }
  
  // Delete with cache invalidation
  Future<bool> deleteMaintenanceIssue(int issueId) async {
    final success = await executeWithStateForSuccess(() async {
      await _apiService.delete('/api/maintenance/$issueId');
      // Invalidate relevant caches
      invalidateCache('maintenance_issues_list');
      invalidateCache('maintenance_issue_$issueId');
    });
    
    if (success) {
      // Clear selected issue if it's the one being deleted
      if (_selectedMaintenanceIssue?.id == issueId) {
        _selectedMaintenanceIssue = null;
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
6. **Priority Management**: Implement proper priority levels and escalation
7. **Status Transitions**: Implement proper maintenance issue status transitions
8. **Assignment Tracking**: Track maintenance personnel assignments

## Testing

When testing the maintenance feature:

```dart
// Test maintenance provider
void main() {
  late MaintenanceProvider provider;
  late MockApiService mockApiService;
  
  setUp(() {
    mockApiService = MockApiService();
    provider = MaintenanceProvider(mockApiService);
  });
  
  test('loadMaintenanceIssues uses caching', () async {
    final issues = [
      MaintenanceIssue(id: 1, propertyId: 1, title: 'Leaky faucet', priority: 'medium', status: 'open'),
      MaintenanceIssue(id: 2, propertyId: 2, title: 'Broken window', priority: 'high', status: 'in-progress'),
    ];
    
    when(() => mockApiService.getListAndDecode<MaintenanceIssue>(
      any(),
      any(),
    )).thenAnswer((_) async => issues);
    
    // First call should hit the API
    await provider.loadMaintenanceIssues();
    verify(() => mockApiService.getListAndDecode<MaintenanceIssue>(
      '/api/maintenance',
      any(),
    )).called(1);
    
    // Second call should use cache
    await provider.loadMaintenanceIssues();
    // API should still only be called once
    verify(() => mockApiService.getListAndDecode<MaintenanceIssue>(
      '/api/maintenance',
      any(),
    )).called(1);
    
    expect(provider.maintenanceIssues, equals(issues));
  });
  
  test('createMaintenanceIssue invalidates cache', () async {
    final newIssue = MaintenanceIssue(id: 1, propertyId: 1, title: 'New issue', priority: 'medium', status: 'open');
    
    when(() => mockApiService.postAndDecode<MaintenanceIssue>(
      any(),
      any(),
      any(),
    )).thenAnswer((_) async => newIssue);
    
    await provider.createMaintenanceIssue(newIssue);
    
    // Cache should be invalidated
    final stats = provider.getCacheStats();
    expect(stats['maintenance_issues_list']?.invalidationCount, equals(1));
  });
}
```

This documentation ensures consistent implementation of the maintenance feature and provides a solid foundation for future development.
