# eRents Desktop Application Secure Storage Service Documentation

## Overview

This document provides documentation for the secure storage service used in the eRents desktop application. The secure storage service is a wrapper around the `flutter_secure_storage` package that provides secure storage of sensitive data like authentication tokens and user preferences.

## Service Structure

The secure storage service is located in the `lib/services/secure_storage_service.dart` file and provides:

1. Authentication token storage and management
2. Generic secure data storage
3. Data retrieval and clearing operations
4. Complete data clearing functionality

## Core Features

### Authentication Token Management

Specialized methods for handling authentication tokens:

- `storeToken()` - Store authentication token securely
- `getToken()` - Retrieve authentication token
- `clearToken()` - Clear authentication token

### Generic Data Storage

Methods for storing and retrieving any key-value pairs:

- `storeData()` - Store any string data with a key
- `getData()` - Retrieve string data by key
- `clearData()` - Clear data by key

### Complete Data Management

- `clearAll()` - Clear all stored data

## Implementation Details

### Constructor

```dart
class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  // ...
}
```

The service uses the `FlutterSecureStorage` package for platform-specific secure storage:
- Android: Keystore system
- iOS: Keychain services
- Windows: Windows Credential Manager
- macOS: Keychain services
- Linux: libsecret

### Token Management

```dart
Future<void> storeToken(String token) async {
  await _storage.write(key: 'auth_token', value: token);
}

Future<String?> getToken() async {
  return await _storage.read(key: 'auth_token');
}

Future<void> clearToken() async {
  await _storage.delete(key: 'auth_token');
}
```

### Generic Data Storage

```dart
Future<void> storeData(String key, String value) async {
  await _storage.write(key: key, value: value);
}

Future<String?> getData(String key) async {
  return await _storage.read(key: key);
}

Future<void> clearData(String key) async {
  await _storage.delete(key: key);
}
```

### Complete Data Clearing

```dart
Future<void> clearAll() async {
  await _storage.deleteAll();
}
```

## Usage Examples

### Authentication Flow

```dart
final secureStorage = SecureStorageService();

// Store token after successful login
await secureStorage.storeToken('user-jwt-token');

// Retrieve token for authenticated requests
final token = await secureStorage.getToken();

// Clear token on logout
await secureStorage.clearToken();
```

### User Preferences

```dart
// Store user preferences
await secureStorage.storeData('theme', 'dark');
await secureStorage.storeData('language', 'en');

// Retrieve user preferences
final theme = await secureStorage.getData('theme');
final language = await secureStorage.getData('language');

// Clear specific preference
await secureStorage.clearData('theme');
```

### Session Management

```dart
// Clear all stored data on account deletion or app reset
await secureStorage.clearAll();
```

## Integration with Other Services

### API Service Integration

The secure storage service integrates with the API service for authentication:

```dart
// In ApiService constructor
ApiService(this.baseUrl, this.secureStorageService);

// In getHeaders method
Future<Map<String, String>> getHeaders({
  Map<String, String>? customHeaders,
}) async {
  final token = await secureStorageService.getToken();
  final headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Client-Type': 'Desktop',
  };
  if (token != null) {
    headers['Authorization'] = 'Bearer $token';
  }
  // ...
}
```

### Provider Integration

Providers use secure storage for authentication state:

```dart
// In AuthProvider
Future<bool> login(String email, String password) async {
  try {
    final response = await api.post('/auth/login', {
      'email': email,
      'password': password,
    });
    
    final data = jsonDecode(response.body);
    final token = data['token'];
    
    // Store token securely
    await secureStorageService.storeToken(token);
    
    // Update provider state
    _isAuthenticated = true;
    notifyListeners();
    
    return true;
  } catch (e) {
    // Handle error
    return false;
  }
}

Future<void> logout() async {
  // Clear token securely
  await secureStorageService.clearToken();
  
  // Update provider state
  _isAuthenticated = false;
  notifyListeners();
}
```

## Security Considerations

1. **Platform Security**: Uses platform-specific secure storage mechanisms
2. **Data Encryption**: Automatic encryption of stored data
3. **Access Control**: Platform-level access restrictions
4. **Token Handling**: Secure storage of authentication tokens
5. **Data Sensitivity**: Only store sensitive data that needs protection
6. **Key Management**: Use consistent key names for data access
7. **Error Handling**: Handle storage errors gracefully
8. **Data Validation**: Validate data before storage and after retrieval

## Best Practices

1. **Token Storage**: Always use secure storage for authentication tokens
2. **Data Sensitivity**: Only store sensitive data that requires protection
3. **Key Consistency**: Use consistent key names across the application
4. **Error Handling**: Implement proper error handling for storage operations
5. **Memory Management**: Don't keep sensitive data in memory longer than needed
6. **Clearing Data**: Clear data appropriately on logout or account deletion
7. **Testing**: Test storage operations on all target platforms
8. **Backup Considerations**: Understand platform backup implications
9. **Performance**: Be aware that secure storage operations may be slower
10. **Fallback**: Consider fallback mechanisms for storage failures

## Extensibility

The secure storage service supports easy extension:

1. **Custom Keys**: Add new key constants for different data types
2. **Typed Storage**: Add typed storage methods for specific data types
3. **Encryption Options**: Extend with additional encryption layers if needed
4. **Storage Validation**: Add validation for stored data integrity
5. **Migration Support**: Add support for data format migrations
6. **Backup Control**: Add options for controlling backup behavior
7. **Access Logging**: Add logging for security auditing
8. **Multi-account Support**: Extend for multiple account support

This secure storage service documentation ensures consistent implementation of secure data storage and provides a solid foundation for future development.
