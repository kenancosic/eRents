# eRents Desktop Application User Preferences Service Documentation

## Overview

This document provides documentation for the user preferences service used in the eRents desktop application. The user preferences service is a lightweight service for managing user-specific preferences and settings using secure storage. It provides a simple interface for storing, retrieving, and removing user preferences.

## Service Structure

The user preferences service is located in the `lib/services/user_preferences_service.dart` file and provides:

1. Preference storage and retrieval
2. Preference removal
3. Secure storage using Flutter Secure Storage
4. Simple key-value preference management

## Core Features

### Preference Management

Basic key-value preference operations:

- `setPreference()` - Store a preference with a key
- `getPreference()` - Retrieve a preference by key
- `removePreference()` - Remove a preference by key

## Implementation Details

### Constructor

```dart
class UserPreferencesService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  // ...
}
```

The service uses the `FlutterSecureStorage` package for platform-specific secure storage:
- Android: Keystore system
- iOS: Keychain services
- Windows: Windows Credential Manager
- macOS: Keychain services
- Linux: libsecret

### Preference Operations

```dart
Future<void> setPreference(String key, String value) async {
  await _storage.write(key: key, value: value);
}

Future<String?> getPreference(String key) async {
  return await _storage.read(key: key);
}

Future<void> removePreference(String key) async {
  await _storage.delete(key: key);
}
```

## Usage Examples

### Basic Preference Management

```dart
final prefsService = UserPreferencesService();

// Store user preferences
await prefsService.setPreference('theme', 'dark');
await prefsService.setPreference('language', 'en');
await prefsService.setPreference('notifications', 'enabled');

// Retrieve user preferences
final theme = await prefsService.getPreference('theme');
final language = await prefsService.getPreference('language');
final notifications = await prefsService.getPreference('notifications');

// Remove specific preference
await prefsService.removePreference('theme');
```

### Application Settings

```dart
// Store application settings
await prefsService.setPreference('last_sync_time', DateTime.now().toIso8601String());
await prefsService.setPreference('max_properties_per_page', '20');
await prefsService.setPreference('default_sort_order', 'name_asc');

// Retrieve application settings
final lastSync = await prefsService.getPreference('last_sync_time');
final maxProperties = await prefsService.getPreference('max_properties_per_page');
final sortOrder = await prefsService.getPreference('default_sort_order');
```

## Integration with Global State Providers

The user preferences service integrates with the PreferencesStateProvider:

```dart
// In PreferencesStateProvider
PreferencesStateProvider(this._prefsService);

/// Load all preferences from the service
Future<void> loadPreferences() async {
  try {
    // This is a placeholder, assuming the service returns a Map.
    // You will need to implement the actual service call.
    _preferences = <String, dynamic>{}; // await _prefsService.getAllPreferences();
    notifyListeners();
  } catch (e) {
    throw AppError.fromException(e);
  }
}

/// Update a specific preference
Future<void> updatePreference(String key, dynamic value) async {
  try {
    await _prefsService.setPreference(key, value.toString());
    _preferences[key] = value;
    notifyListeners();
  } catch (e) {
    throw AppError.fromException(e);
  }
}

/// Get a preference value with optional default
T? getPreference<T>(String key, [T? defaultValue]) {
  return _preferences[key] as T? ?? defaultValue;
}

/// Remove a preference
Future<void> removePreference(String key) async {
  try {
    await _prefsService.removePreference(key);
    _preferences.remove(key);
    notifyListeners();
  } catch (e) {
    throw AppError.fromException(e);
  }
}
```

## Integration with Application Initialization

The service is used during application initialization:

```dart
// In main.dart or app initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefsService = UserPreferencesService();
  
  // Load initial preferences
  final theme = await prefsService.getPreference('theme') ?? 'light';
  final language = await prefsService.getPreference('language') ?? 'en';
  
  runApp(
    MyApp(
      initialTheme: theme,
      initialLanguage: language,
      prefsService: prefsService,
    ),
  );
}
```

## Security Considerations

1. **Platform Security**: Uses platform-specific secure storage mechanisms
2. **Data Encryption**: Automatic encryption of stored preferences
3. **Access Control**: Platform-level access restrictions
4. **Data Sensitivity**: Only store preferences that need protection
5. **Key Management**: Use consistent key names for preference access
6. **Error Handling**: Handle storage errors gracefully
7. **Data Validation**: Validate preferences before storage and after retrieval

## Best Practices

1. **Key Consistency**: Use consistent key names across the application
2. **Data Types**: Store preferences as strings and convert as needed
3. **Error Handling**: Implement proper error handling for preference operations
4. **Memory Management**: Don't keep preferences in memory longer than needed
5. **Validation**: Validate preferences after retrieval
6. **Testing**: Test preference operations on all target platforms
7. **Backup Considerations**: Understand platform backup implications
8. **Performance**: Be aware that secure storage operations may be slower
9. **Fallback**: Consider fallback mechanisms for storage failures
10. **Documentation**: Document preference keys and their purposes

## Extensibility

The user preferences service supports easy extension:

1. **Typed Preferences**: Add typed preference methods for specific data types
2. **Preference Groups**: Add support for grouping related preferences
3. **Default Values**: Add support for default preference values
4. **Preference Validation**: Add validation for preference values
5. **Migration Support**: Add support for preference format migrations
6. **Backup Control**: Add options for controlling backup behavior
7. **Access Logging**: Add logging for security auditing
8. **Preference Sync**: Add support for syncing preferences across devices

This user preferences service documentation ensures consistent implementation of user preference management and provides a solid foundation for future development.
