# Provider Quick Start Guide

This guide provides a quick reference for working with providers in the eRents Desktop application.

## Table of Contents
- [Accessing Providers](#accessing-providers)
- [Listening to Changes](#listening-to-changes)
- [Common Patterns](#common-patterns)
- [Best Practices](#best-practices)

## Accessing Providers

### Basic Access
```dart
// Get a provider without listening to changes
final authProvider = Provider.of<AuthProvider>(context, listen: false);

// Using extension (recommended)
final authProvider = context.providers.auth;
```

### Common Providers
```dart
// Auth
final auth = context.providers.auth;
final user = auth.user;

// Properties
final properties = context.providers.properties;
final propertyList = properties.allProperties;

// Lookups
final lookups = context.providers.lookups;
final propertyTypes = lookups.propertyTypes;

// Rents
final rents = context.providers.rents;
final activeRentals = rents.activeRentals;
```

## Listening to Changes

### Consumer Widget
```dart
return Consumer<AuthProvider>(
  builder: (context, auth, _) {
    return Text('Welcome, ${auth.user?.name ?? 'Guest'}');
  },
);
```

### Selector Widget (for performance)
```dart
return Selector<AuthProvider, User?>(
  selector: (_, provider) => provider.user,
  builder: (context, user, _) {
    return Text(user?.name ?? 'Loading...');
  },
);
```

## Common Patterns

### Loading State
```dart
if (provider.isLoading) {
  return const Center(child: CircularProgressIndicator());
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
    await provider.loadData();
  } catch (e) {
    // Handle error
  }
}
```

## Best Practices

1. **Provider Access**
   - Use `listen: false` when only calling methods
   - Prefer `Consumer` over `Provider.of` for listening to changes
   - Use `Selector` for complex widgets to minimize rebuilds

2. **State Management**
   - Keep UI logic in widgets, business logic in providers
   - Update state using `notifyListeners()` after changes
   - Handle loading and error states consistently

3. **Performance**
   - Use `const` constructors where possible
   - Implement `==` and `hashCode` for model classes
   - Use `ValueNotifier` for simple state

4. **Testing**
   - Mock dependencies in tests
   - Test provider state changes
   - Test error conditions

## Common Issues

### Provider Not Found
```
Error: Could not find the correct Provider<...> above this Widget
```
**Solution**: Wrap your widget with the required provider or check the widget tree.

### Unnecessary Rebuilds
**Solution**: Use `const` constructors and `Selector` widgets to optimize rebuilds.

### Memory Leaks
**Solution**: Cancel subscriptions and close controllers in `dispose()` method.

## Examples

### Login Button
```dart
ElevatedButton(
  onPressed: () async {
    try {
      await context.providers.auth.login(email, password);
      // Navigate on success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  },
  child: const Text('Login'),
)
```

### Data Loading
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.providers.properties.loadProperties();
  });
}
```
