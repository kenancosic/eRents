# Provider Architecture

This document outlines the provider architecture used in the eRents Desktop application for state management.

## Overview

The application uses the `provider` package for state management, following a clean architecture pattern. The provider system is designed to be maintainable, testable, and scalable.

## Core Components

### 1. Base Provider
- Located in `lib/base/base_provider.dart`
- Provides common functionality like state management (loading, error states)
- Implements `ChangeNotifier` for state updates
- Includes API call utilities and error handling

### 2. Provider Configuration
- Located in `lib/providers/providers_config.dart`
- Centralized configuration for all providers
- Handles dependency injection and provider initialization
- Ensures proper provider scoping and lifecycle

### 3. Provider Extensions
- Located in `lib/providers/provider_extensions.dart`
- Provides convenient access to providers via BuildContext
- Type-safe provider accessors
- Reduces boilerplate code in widgets

## Provider Types

### Auth Provider
- Manages user authentication state
- Handles login, logout, and session management
- Provides access to the current user

### Property Provider
- Manages property-related state
- Handles fetching, filtering, and sorting properties
- Manages property CRUD operations

### Lookup Provider
- Manages reference data and enums
- Handles dropdown options and static data
- Implements caching for better performance

### Rents Provider
- Manages rental agreements and bookings
- Handles rental lifecycle (create, update, cancel)
- Manages rental-related state

## Usage Examples

### Accessing a Provider

```dart
// Basic provider access
final authProvider = Provider.of<AuthProvider>(context, listen: false);

// Using the extension (if enabled)
final authProvider = context.providers.auth;
```

### Listening to Changes

```dart
return Consumer<AuthProvider>(
  builder: (context, auth, _) {
    return Text('Welcome, ${auth.user?.name ?? 'Guest'}');
  },
);
```

### Performing Actions

```dart
onPressed: () {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  await auth.login(email, password);
}
```

## Best Practices

1. **Provider Initialization**
   - Initialize providers at the appropriate level in the widget tree
   - Use `MultiProvider` to group related providers
   - Initialize heavy providers lazily when possible

2. **State Management**
   - Keep business logic in providers, not in widgets
   - Use `Consumer` for fine-grained rebuilds
   - Prefer `listen: false` when only calling methods

3. **Error Handling**
   - Handle errors in providers, not in UI components
   - Provide meaningful error messages
   - Update error state appropriately

4. **Testing**
   - Mock dependencies for unit testing
   - Test provider state changes
   - Test error conditions

## Common Patterns

### Loading States
```dart
if (provider.isLoading) {
  return CircularProgressIndicator();
}
```

### Error Handling
```dart
if (provider.error != null) {
  return ErrorWidget(provider.error!);
}
```

### Data Fetching
```dart
Future<void> loadData() async {
  try {
    setLoading(true);
    final data = await _api.getData();
    _data = data;
    setError(null);
  } catch (e) {
    setError(e.toString());
  } finally {
    setLoading(false);
    notifyListeners();
  }
}
```
