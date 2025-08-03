# eRents Desktop Application App State Providers Documentation

## Overview

This document provides detailed documentation for the application state providers used in the eRents desktop application. These providers manage global application state including navigation, user preferences, and error handling using the provider state management system.

## Providers Structure

The application state providers are located in the `lib/base/app_state_providers.dart` file and include:

1. `NavigationStateProvider` - Navigation state management
2. `PreferencesStateProvider` - User preferences management
3. `AppErrorProvider` - Global error state management

## Navigation State Provider

Manages the current navigation state of the application using a cleaner state-based approach.

### Properties

#### currentPath

```dart
String get currentPath;
```

The current navigation path.

#### isOnAuthPath

```dart
bool get isOnAuthPath;
```

Whether the current path is an authentication-related path.

### Methods

#### updateCurrentPath

```dart
void updateCurrentPath(String path);
```

Updates the current navigation path.

**Parameters:**
- `path`: The new navigation path

#### isOnPath

```dart
bool isOnPath(String path);
```

Checks if currently on a specific path.

**Parameters:**
- `path`: The path to check

**Returns:**
- `bool`: Whether currently on the specified path

### Usage Example

```dart
// In a widget
final navigationProvider = Provider.of<NavigationStateProvider>(context, listen: false);

// Update the current path
navigationProvider.updateCurrentPath('/properties');

// Check if on a specific path
if (navigationProvider.isOnPath('/properties')) {
  // Do something
}

// Check if on auth path
if (navigationProvider.isOnAuthPath) {
  // Handle auth-specific UI
}
```

## Preferences State Provider

Manages user preferences and settings.

### Properties

#### isDarkMode

```dart
bool get isDarkMode;
```

Whether dark mode is enabled.

#### language

```dart
String get language;
```

The current language setting.

### Methods

#### toggleDarkMode

```dart
void toggleDarkMode();
```

Toggles dark mode on or off.

#### setLanguage

```dart
void setLanguage(String language);
```

Sets the current language.

**Parameters:**
- `language`: The language code to set

### Usage Example

```dart
// In a widget
final preferencesProvider = Provider.of<PreferencesStateProvider>(context, listen: false);

// Toggle dark mode
preferencesProvider.toggleDarkMode();

// Set language
preferencesProvider.setLanguage('en');

// Listen to changes in a widget
@override
Widget build(BuildContext context) {
  return Consumer<PreferencesStateProvider>(
    builder: (context, preferencesProvider, child) {
      return MaterialApp(
        theme: preferencesProvider.isDarkMode ? darkTheme : lightTheme,
        // ...
      );
    },
  );
}
```

## App Error Provider

Manages the global error state of the application.

### Properties

#### error

```dart
AppError? get error;
```

The current error, if any.

#### hasError

```dart
bool get hasError;
```

Whether there is currently an error.

### Methods

#### setError

```dart
void setError(AppError error);
```

Sets the current error.

**Parameters:**
- `error`: The error to set

#### clearError

```dart
void clearError();
```

Clears the current error.

#### showNetworkError

```dart
void showNetworkError([String? context]);
```

Shows a network error.

**Parameters:**
- `context`: Optional context for the error

#### showAuthError

```dart
void showAuthError([String? context]);
```

Shows an authentication error.

**Parameters:**
- `context`: Optional context for the error

#### showValidationError

```dart
void showValidationError([String? context]);
```

Shows a validation error.

**Parameters:**
- `context`: Optional context for the error

### Usage Example

```dart
// In a provider
final appErrorProvider = Provider.of<AppErrorProvider>(context, listen: false);

try {
  await apiService.get('/properties');
} catch (e, s) {
  final error = AppError.fromException(e, s, 'Loading properties');
  appErrorProvider.setError(error);
}

// In a widget to display errors
@override
Widget build(BuildContext context) {
  return Consumer<AppErrorProvider>(
    builder: (context, errorProvider, child) {
      if (errorProvider.hasError) {
        return ErrorDisplayWidget(error: errorProvider.error);
      }
      return child!;
    },
    child: MyContentWidget(),
  );
}

// Clearing errors
appErrorProvider.clearError();
```

## Integration with Base Provider Architecture

The app state providers work seamlessly with the base provider architecture:

```dart
// Example of a feature provider using app state providers
class PropertyProvider extends BaseProvider<PropertyProvider> {
  final ApiService _apiService;
  final AppErrorProvider _appErrorProvider;
  final NavigationStateProvider _navigationProvider;
  
  PropertyProvider(
    this._apiService,
    this._appErrorProvider,
    this._navigationProvider,
  );
  
  Future<List<Property>?> loadProperties() async {
    try {
      return await _apiService.getListAndDecode<Property>(
        '/api/properties',
        Property.fromJson,
      );
    } catch (e, s) {
      // Set global error
      final error = AppError.fromException(e, s, 'Loading properties');
      _appErrorProvider.setError(error);
      rethrow;
    }
  }
  
  Future<void> navigateToPropertyDetail(int propertyId) async {
    _navigationProvider.updateCurrentPath('/properties/$propertyId');
    // Navigation logic
  }
}
```

## Best Practices

1. **Use Appropriate Providers**: Use the right provider for the right type of state
2. **Listen Selectively**: Use `listen: false` when you only need to read state, not listen to changes
3. **Clear Errors**: Clear errors when appropriate to avoid stale error states
4. **Update Navigation**: Keep navigation state updated for proper UI behavior
5. **Handle Preferences**: Respect user preferences in UI components
6. **Error Context**: Provide context when setting errors for better debugging
7. **Provider Injection**: Inject providers properly in constructors
8. **State Consistency**: Maintain consistent state across the application

## Testing

When testing components that use app state providers:

```dart
// Test a widget that uses app state providers
void main() {
  late NavigationStateProvider navigationProvider;
  late PreferencesStateProvider preferencesProvider;
  
  setUp(() {
    navigationProvider = NavigationStateProvider();
    preferencesProvider = PreferencesStateProvider();
  });
  
  test('NavigationStateProvider updates path correctly', () {
    expect(navigationProvider.currentPath, '/');
    
    navigationProvider.updateCurrentPath('/properties');
    expect(navigationProvider.currentPath, '/properties');
    expect(navigationProvider.isOnPath('/properties'), true);
  });
  
  test('PreferencesStateProvider toggles dark mode', () {
    expect(preferencesProvider.isDarkMode, false);
    
    preferencesProvider.toggleDarkMode();
    expect(preferencesProvider.isDarkMode, true);
    
    preferencesProvider.toggleDarkMode();
    expect(preferencesProvider.isDarkMode, false);
  });
  
  testWidgets('Widget responds to provider changes', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: navigationProvider),
          ChangeNotifierProvider.value(value: preferencesProvider),
        ],
        child: MyApp(),
      ),
    );
    
    // Test initial state
    expect(find.text('Light Mode'), findsOneWidget);
    
    // Trigger dark mode
    preferencesProvider.toggleDarkMode();
    await tester.pumpAndSettle();
    
    // Test updated state
    expect(find.text('Dark Mode'), findsOneWidget);
  });
}
```

This documentation ensures consistent implementation of application state providers and provides a solid foundation for future development.
