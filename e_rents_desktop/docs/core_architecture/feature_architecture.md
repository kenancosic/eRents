# eRents Desktop Application Feature Architecture Documentation

## Overview

This document provides documentation for the feature architecture used in the eRents desktop application. The application follows a modular feature-first architecture with clear separation of concerns, consistent patterns, and reusable components.

## Feature Structure

Each feature in the application follows a consistent directory structure:

```
lib/features/feature_name/
├── feature_name.dart          # Feature entry point
├── providers/                 # Feature-specific providers
│   └── feature_provider.dart  # Data and business logic providers
├── screens/                   # Feature screens (UI)
│   ├── feature_list_screen.dart
│   ├── feature_detail_screen.dart
│   └── feature_form_screen.dart
└── widgets/                   # Feature-specific widgets
    └── feature_components.dart
```

## Feature Implementation Patterns

### Provider Pattern

Features use the base provider architecture for consistent data management:

```dart
class FeatureProvider extends BaseProvider {
  FeatureProvider(super.api);
  
  // Load data
  Future<List<FeatureModel>?> loadFeatures() async {
    return executeWithState(() async {
      return await api.getListAndDecode('/api/features', FeatureModel.fromJson);
    });
  }
  
  // Create new item
  Future<FeatureModel?> createFeature(FeatureModel model) async {
    return executeWithState(() async {
      invalidateCache('features_list');
      return await api.postAndDecode(
        '/api/features',
        model.toJson(),
        FeatureModel.fromJson,
      );
    });
  }
  
  // Update existing item
  Future<FeatureModel?> updateFeature(FeatureModel model) async {
    return executeWithState(() async {

      return await api.putAndDecode(
        '/api/features/${model.id}',
        model.toJson(),
        FeatureModel.fromJson,
      );
    });
  }
  
  // Delete item
  Future<bool> deleteFeature(int id) async {
    final success = await executeWithStateForSuccess(() async {

      await api.deleteAndConfirm('/api/features/$id');
    });
    return success;
  }
}
```

### Form Provider Pattern

Complex forms use a separate form provider to separate concerns:

```dart
class FeatureFormProvider extends BaseProvider {
  FeatureFormProvider(super.api);
  
  // Load item for editing
  Future<FeatureModel?> loadFeature(int id) async {
    return executeWithState(() async {
      return await api.getAndDecode('/api/features/$id', FeatureModel.fromJson);
    });
  }
  
  // Save item (create or update)
  Future<FeatureModel?> saveFeature(FeatureModel model) async {
    return executeWithState(() async {
      if (model.id == 0) {
        // Create new
        return await api.postAndDecode(
          '/api/features',
          model.toJson(),
          FeatureModel.fromJson,
        );
      } else {
        // Update existing
        return await api.putAndDecode(
          '/api/features/${model.id}',
          model.toJson(),
          FeatureModel.fromJson,
        );
      }
    });
  }
}
```

### Screen Pattern

Features implement consistent screen patterns using generic templates:

```dart
class FeatureListScreen extends StatefulWidget {
  const FeatureListScreen({super.key});

  @override
  State<FeatureListScreen> createState() => _FeatureListScreenState();
}

class _FeatureListScreenState extends State<FeatureListScreen> {
  int? _sortColumnIndex;
  bool _sortAscending = true;
  List<FeatureModel> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems({String? sortBy, bool? ascending}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = Provider.of<FeatureProvider>(context, listen: false);
      final result = sortBy != null
          ? await provider.loadItemsSorted(sortBy: sortBy, ascending: ascending)
          : await provider.loadItems();

      setState(() {
        _items = result ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Features'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: DesktopDataTable<FeatureModel>(
        items: _items,
        loading: _isLoading,
        errorMessage: _errorMessage,
        onRefresh: _refresh,
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        onSort: _handleSort,
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Status')),
        ],
        rowsBuilder: (context, items) {
          return items.map((item) => DataRow(
            cells: [
              DataCell(Text(item.name)),
              DataCell(Text(item.status)),
            ],
            onSelectChanged: (_) => _handleItemTap(item),
          )).toList();
        },
      ),
    );
  }
}
```

## Feature Examples

### Properties Feature

The properties feature demonstrates the complete feature architecture:

1. **Providers**:
   - `PropertyProvider`: Main data provider with caching
   - `PropertyFormProvider`: Form-specific provider

2. **Screens**:
   - `PropertyListScreen`: List view with sorting and filtering
   - `PropertyDetailScreen`: Detail view with master-detail layout
   - `PropertyFormScreen`: Create/edit form with validation

3. **Widgets**:
   - `PropertyCard`: Reusable property display component
   - `PropertyFilterPanel`: Filtering controls
   - `PropertyFormFields`: Form input components
   - `PropertyImagesGrid`: Image display grid
   - `PropertyInfoDisplay`: Information display component
   - `PropertyInfoRow`: Row-based information display
   - `PropertyTypeSelection`: Property type selector

### Key Implementation Details

1. **Caching Strategy**: 5-minute TTL for property lists, specific cache keys for individual items
2. **Cache Invalidation**: Automatic invalidation on create/update/delete operations
3. **Sorting**: API-based sorting with column mapping
4. **Error Handling**: Consistent error display with retry functionality
5. **Loading States**: Visual loading indicators
6. **State Management**: Provider-based state management
7. **Navigation**: GoRouter integration for consistent routing

## Feature Integration

### Provider Registration

Features register their providers in the main application:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),
    ChangeNotifierProvider(create: (_) => PropertyProvider(apiService)),
    // ... other feature providers
  ],
  child: const App(),
)
```

### Routing Integration

Features integrate with the routing system:

```dart
GoRoute(
  path: '/properties',
  name: AppRoutes.properties,
  builder: (context, state) => const PropertyListScreen(),
  routes: [
    GoRoute(
      path: ':id',
      name: AppRoutes.propertyDetail,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return PropertyDetailScreen(propertyId: id);
      },
    ),
    GoRoute(
      path: 'new',
      name: AppRoutes.addProperty,
      builder: (context, state) => const PropertyFormScreen(),
    ),
    GoRoute(
      path: ':id/edit',
      name: AppRoutes.editProperty,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return PropertyFormScreen(propertyId: id);
      },
    ),
  ],
)
```

## Best Practices

1. **Modular Structure**: Keep features self-contained with clear boundaries
2. **Consistent Patterns**: Follow established provider and screen patterns
3. **Caching**: Implement appropriate caching with clear invalidation
4. **Error Handling**: Provide user-friendly error messages with retry options
5. **Loading States**: Show visual feedback during operations
6. **Reusability**: Create reusable widgets within features
7. **Separation of Concerns**: Separate data, business logic, and UI concerns
8. **State Management**: Use providers for consistent state management
9. **Navigation**: Integrate with the routing system properly
10. **Testing**: Write tests for providers and complex business logic

## Extensibility

The feature architecture supports easy extension:

1. **New Features**: Create new feature directories following the pattern
2. **Feature Enhancement**: Add new providers, screens, or widgets to existing features
3. **Cross-feature Integration**: Use dependency injection for feature interactions
4. **Shared Components**: Promote reusable components to the main widgets directory
5. **API Extensions**: Extend API service extensions for new endpoint patterns

This feature architecture documentation ensures consistent implementation across all features and provides a solid foundation for future development.
