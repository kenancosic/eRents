# eRents Desktop Application Quick Start Guide

## Overview

This guide provides a quick introduction to the eRents desktop application for new developers. It covers the essential architecture concepts, key components, and getting started instructions to help you become productive quickly.

## Prerequisites

Before you begin, ensure you have the following installed:

1. **Flutter SDK** (Latest stable version)
2. **IDE** (Visual Studio Code or Android Studio with Flutter plugins)
3. **Git** for version control
4. **Backend API** (Running eRents .NET Core API)

## Project Structure

```
e_rents_desktop/
├── lib/
│   ├── base/           # Base provider architecture
│   ├── features/       # Feature modules (auth, properties, etc.)
│   ├── models/         # Data models
│   ├── services/       # Business services
│   ├── utils/          # Utility functions
│   ├── widgets/        # Reusable UI components
│   ├── theme/          # Theming and styling
│   └── main.dart       # Application entry point
├── docs/              # Comprehensive documentation
├── test/              # Unit and widget tests
├── pubspec.yaml       # Dependencies and configuration
└── .env               # Environment variables
```

## Key Architecture Concepts

### 1. Feature-First Organization

The application is organized by features rather than layers:

```
features/
├── auth/
│   ├── providers/
│   ├── screens/
│   └── widgets/
├── properties/
│   ├── providers/
│   ├── screens/
│   ├── widgets/
│   └── models/
└── ... (other features)
```

### 2. Base Provider Architecture

All providers extend `BaseProvider` which provides:
- State management (loading, error states)
- TTL-based caching
- Standardized error handling
- Common utility methods

```dart
// Example provider implementation
class PropertyProvider extends BaseProvider<PropertyProvider> {
  final PropertyService _propertyService;
  
  PropertyProvider(this._propertyService);
  
  Future<void> loadProperties() async {
    await executeWithState(() async {
      final properties = await _propertyService.getProperties();
      // Update state
    });
  }
}
```

### 3. Service Layer with Extensions

Services handle business logic and API communication:

```dart
// ApiService extensions for cleaner API calls
final properties = await apiService.getListAndDecode<Property>(
  '/api/properties',
  (json) => Property.fromJson(json),
);
```

## Getting Started

### 1. Environment Setup

1. Clone the repository
2. Create a `.env` file in the root directory:

```
API_BASE_URL=http://localhost:5000
```

3. Run `flutter pub get` to install dependencies

### 2. Running the Application

```bash
flutter run -d windows
```

### 3. Understanding the Entry Point

The `main.dart` file sets up:
- Environment loading
- Dependency injection with `MultiProvider`
- Routing with `GoRouter`
- Global error handling

```dart
void main() async {
  // Load environment
  await dotenv.load(fileName: ".env");
  
  // Run app with providers
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        // Other providers...
      ],
      child: AppWithRouter(),
    ),
  );
}
```

## Key Components to Understand

### 1. Routing (`lib/router/app_router.dart`)

- Uses `GoRouter` for navigation
- Shell layout for consistent UI
- Route guards for authentication
- Provider injection per route

### 2. Theming (`lib/theme/theme.dart`)

- Material 3 design system
- Centralized color palette
- Text styles and widget themes
- Responsive design principles

### 3. CRUD Templates (`lib/widgets/templates/`)

Reusable screen templates:
- `ListScreen` - Data tables with sorting/pagination
- `FormScreen` - Validated forms with save/cancel
- `DetailScreen` - Master-detail views

### 4. Error Handling

- `AppError` for structured error information
- `AppErrorProvider` for global error state
- `GlobalErrorDialog` for user-friendly error display

## Development Workflow

### 1. Adding a New Feature

1. Create a new feature directory in `lib/features/`
2. Implement models in `features/your_feature/models/`
3. Create services in `features/your_feature/services/`
4. Implement providers extending `BaseProvider`
5. Create screens and widgets
6. Add routes to `app_router.dart`
7. Register providers in `main.dart`

### 2. Using Base Provider

```dart
// Extend BaseProvider for consistent state management
class YourFeatureProvider extends BaseProvider<YourFeatureProvider> {
  final YourFeatureService _service;
  
  YourFeatureProvider(this._service);
  
  // Use executeWithState for automatic loading/error handling
  Future<void> loadData() async {
    await executeWithState(() async {
      // Your logic here
    });
  }
  
  // Use executeWithCache for cached data
  Future<List<YourModel>> loadCachedData() async {
    return await executeWithCache(
      cacheKey: 'your_feature_data',
      fetchFunction: () => _service.fetchData(),
      ttl: Duration(minutes: 5),
    );
  }
}
```

### 3. API Service Usage

```dart
// Use ApiService extensions for cleaner API calls
final result = await apiService.postAndDecode<ResponseType>(
  '/api/endpoint',
  data: requestData,
  decoder: (json) => ResponseType.fromJson(json),
);
```

## Best Practices

### 1. State Management

- Always extend `BaseProvider` for consistent behavior
- Use `executeWithState` for automatic loading/error handling
- Use `executeWithCache` for performance optimization
- Invalidate cache when data changes

### 2. UI Development

- Use CRUD templates for consistent screens
- Follow Material 3 design guidelines
- Implement responsive layouts
- Use centralized theming

### 3. Error Handling

- Always handle errors at the provider level
- Provide user-friendly error messages
- Implement retry mechanisms where appropriate
- Log errors for debugging

### 4. Testing

- Write unit tests for providers and services
- Test widget behavior with widget tests
- Use mock services for isolation
- Test error scenarios

## Common Tasks

### 1. Adding a New API Endpoint

1. Add method to appropriate service class
2. Use ApiService extensions for type-safe calls
3. Handle errors appropriately
4. Add unit tests

### 2. Creating a New Screen

1. Use existing CRUD templates when possible
2. Create feature-specific widgets
3. Connect to appropriate providers
4. Add navigation from other screens

### 3. Adding Lookup Data

1. Add to `LookupService` if it's reference data
2. Create appropriate enum mappings
3. Use `LookupProvider` for state management
4. Implement caching strategy

## Troubleshooting

### 1. Provider Not Found

Ensure the provider is registered in `main.dart` and injected in the route.

### 2. API Calls Failing

Check `.env` configuration and ensure backend is running.

### 3. Caching Issues

Use `invalidateCache` method to clear cached data when needed.

### 4. Theming Problems

Check `theme/theme.dart` for consistent styling implementation.

## Next Steps

1. Read the [Architecture Overview](architecture_overview.md) for detailed system understanding
2. Review the [Base Provider Architecture](base_provider_architecture.md) documentation
3. Study existing feature implementations in `lib/features/`
4. Check the [Final Summary](final_summary.md) for comprehensive best practices

## Useful Documentation References

- [Final Summary](final_summary.md) - Complete documentation overview
- [Architecture Diagram](architecture_diagram.md) - Visual system representation
- [Feature Architecture](feature_architecture.md) - Feature organization patterns
- [Migration and Testing Strategies](migration_and_testing_strategies.md) - Provider migration guide
- [Error Handling Patterns](error_handling_patterns.md) - Structured error management

This quick start guide should help you get up and running with the eRents desktop application development. For more detailed information on specific components, refer to the individual documentation files listed above.
