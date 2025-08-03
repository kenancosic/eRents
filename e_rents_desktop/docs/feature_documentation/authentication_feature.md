# eRents Desktop Application Authentication Feature Documentation

## Overview

This document provides detailed documentation for the authentication feature in the eRents desktop application. This feature handles user authentication including login, registration, password reset, and token management using secure storage.

## Feature Structure

The authentication feature is organized in the `lib/features/auth/` directory with the following structure:

```
lib/features/auth/
├── providers/
│   └── auth_provider.dart
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── forgot_password_screen.dart
│   └── reset_password_screen.dart
├── widgets/
│   ├── login_form.dart
│   ├── register_form.dart
│   └── auth_button.dart
└── services/
    └── auth_service.dart
```

## Core Components

### Auth Provider

The `AuthProvider` extends `BaseProvider` and manages authentication state:

#### Properties

- `isLoggedIn`: Whether user is currently logged in
- `user`: Currently authenticated user
- `authToken`: Current authentication token

#### Methods

- `login(String email, String password)`: Authenticate user
- `register(UserRegistration registration)`: Register new user
- `logout()`: Log out current user
- `forgotPassword(String email)`: Initiate password reset
- `resetPassword(String token, String newPassword)`: Reset password
- `refreshToken()`: Refresh authentication token
- `checkAuthStatus()`: Check current authentication status

### Auth Service

The `AuthService` handles low-level authentication operations:

#### Methods

- `authenticate(LoginRequest request)`: Authenticate with credentials
- `registerUser(UserRegistration registration)`: Register new user
- `requestPasswordReset(String email)`: Request password reset
- `confirmPasswordReset(String token, String newPassword)`: Confirm password reset
- `refreshAuthToken(String refreshToken)`: Refresh authentication token

### Secure Storage Integration

Authentication tokens are securely stored using the `SecureStorageService`:

```dart
// In AuthService
final SecureStorageService _secureStorage;

Future<void> _storeTokens(AuthResponse response) async {
  await _secureStorage.writeSecureData('auth_token', response.token);
  await _secureStorage.writeSecureData('refresh_token', response.refreshToken);
  await _secureStorage.writeSecureData('token_expiry', response.expiresAt.toIso8601String());
}

Future<String?> _getAuthToken() async {
  return await _secureStorage.readSecureData('auth_token');
}

Future<void> _clearTokens() async {
  await _secureStorage.deleteSecureData('auth_token');
  await _secureStorage.deleteSecureData('refresh_token');
  await _secureStorage.deleteSecureData('token_expiry');
}
```

## Screens

### Login Screen

Provides user authentication with email and password.

#### Features

- Email and password input validation
- Loading state during authentication
- Error handling for invalid credentials
- Navigation to registration screen
- Password reset functionality
- Remember me option

#### Implementation

```dart
// LoginScreen widget
@override
Widget build(BuildContext context) {
  return Consumer<AuthProvider>(
    builder: (context, authProvider, child) {
      return Scaffold(
        appBar: AppBar(title: Text('Login')),
        body: ContentWrapper(
          child: LoginForm(
            onLogin: _handleLogin,
            isLoading: authProvider.isLoading,
            error: authProvider.error,
          ),
        ),
      );
    },
  );
}
```

### Register Screen

Allows new users to create an account.

#### Features

- User registration form with validation
- Name, email, and password input
- Password confirmation
- Terms and conditions agreement
- Loading state during registration
- Error handling for registration issues
- Navigation to login screen

### Forgot Password Screen

Initiates the password reset process.

#### Features

- Email input for password reset
- Validation of email format
- Loading state during request
- Success and error feedback
- Navigation to login screen

### Reset Password Screen

Allows users to set a new password using a reset token.

#### Features

- New password and confirmation input
- Password strength validation
- Loading state during reset
- Error handling for invalid tokens
- Navigation to login screen after success

## Widgets

### Login Form

A custom form widget for login functionality with validation.

### Register Form

A custom form widget for registration functionality with validation.

### Auth Button

A reusable authentication-themed button widget.

## Integration with Base Provider Architecture

The authentication feature fully leverages the base provider architecture:

```dart
// AuthProvider using base provider features
class AuthProvider extends BaseProvider<AuthProvider> {
  final ApiService _apiService;
  final SecureStorageService _secureStorage;
  User? _user;
  String? _authToken;
  
  AuthProvider(this._apiService, this._secureStorage);
  
  bool get isLoggedIn => _authToken != null && _user != null;
  User? get user => _user;
  String? get authToken => _authToken;
  
  // Login with state management
  Future<bool> login(String email, String password) async {
    return await executeWithStateForSuccess(() async {
      final response = await _apiService.postAndDecode<AuthResponse>(
        '/api/auth/login',
        {
          'email': email,
          'password': password,
        },
        AuthResponse.fromJson,
      );
      
      if (response != null) {
        await _storeAuthData(response);
        return true;
      }
      
      return false;
    });
  }
  
  // Registration with state management
  Future<bool> register(UserRegistration registration) async {
    return await executeWithStateForSuccess(() async {
      final response = await _apiService.postAndDecode<AuthResponse>(
        '/api/auth/register',
        registration.toJson(),
        AuthResponse.fromJson,
      );
      
      if (response != null) {
        await _storeAuthData(response);
        return true;
      }
      
      return false;
    });
  }
  
  // Logout with state management
  Future<void> logout() async {
    await executeWithState(() async {
      try {
        // Notify server of logout
        await _apiService.post('/api/auth/logout', {});
      } catch (e) {
        // Ignore logout errors
        logger.warning('Error during logout: $e');
      } finally {
        // Always clear local data
        await _clearAuthData();
      }
    });
  }
  
  // Password reset initiation
  Future<bool> forgotPassword(String email) async {
    return await executeWithStateForSuccess(() async {
      await _apiService.post('/api/auth/forgot-password', {
        'email': email,
      });
      return true;
    });
  }
  
  // Password reset confirmation
  Future<bool> resetPassword(String token, String newPassword) async {
    return await executeWithStateForSuccess(() async {
      final response = await _apiService.postAndDecode<AuthResponse>(
        '/api/auth/reset-password',
        {
          'token': token,
          'newPassword': newPassword,
        },
        AuthResponse.fromJson,
      );
      
      if (response != null) {
        await _storeAuthData(response);
        return true;
      }
      
      return false;
    });
  }
  
  // Check authentication status
  Future<void> checkAuthStatus() async {
    await executeWithState(() async {
      final token = await _secureStorage.readSecureData('auth_token');
      final userJson = await _secureStorage.readSecureData('user_data');
      
      if (token != null && userJson != null) {
        try {
          final user = User.fromJson(jsonDecode(userJson));
          _authToken = token;
          _user = user;
        } catch (e) {
          // Invalid stored data, clear it
          await _clearAuthData();
        }
      }
    });
    
    notifyListeners();
  }
  
  // Store authentication data securely
  Future<void> _storeAuthData(AuthResponse response) async {
    _authToken = response.token;
    _user = response.user;
    
    await _secureStorage.writeSecureData('auth_token', response.token);
    await _secureStorage.writeSecureData('refresh_token', response.refreshToken);
    await _secureStorage.writeSecureData('user_data', jsonEncode(response.user.toJson()));
  }
  
  // Clear authentication data
  Future<void> _clearAuthData() async {
    _authToken = null;
    _user = null;
    
    await _secureStorage.deleteSecureData('auth_token');
    await _secureStorage.deleteSecureData('refresh_token');
    await _secureStorage.deleteSecureData('user_data');
  }
}
```

## API Service Integration

The authentication feature integrates with the API service using extensions:

```dart
// API service extensions for authentication
extension AuthApiExtensions on ApiService {
  Future<AuthResponse?> login(LoginRequest request) {
    return postAndDecode<AuthResponse>(
      '/api/auth/login',
      request.toJson(),
      AuthResponse.fromJson,
    );
  }
  
  Future<AuthResponse?> register(UserRegistration registration) {
    return postAndDecode<AuthResponse>(
      '/api/auth/register',
      registration.toJson(),
      AuthResponse.fromJson,
    );
  }
  
  Future<void> logout() {
    return post('/api/auth/logout', {});
  }
  
  Future<void> forgotPassword(String email) {
    return post('/api/auth/forgot-password', {
      'email': email,
    });
  }
  
  Future<AuthResponse?> resetPassword(String token, String newPassword) {
    return postAndDecode<AuthResponse>(
      '/api/auth/reset-password',
      {
        'token': token,
        'newPassword': newPassword,
      },
      AuthResponse.fromJson,
    );
  }
}
```

## Error Handling

Authentication errors are handled using the `AppError` system:

```dart
// In AuthProvider
Future<bool> login(String email, String password) async {
  try {
    return await executeWithStateForSuccess(() async {
      final response = await _apiService.login(LoginRequest(
        email: email,
        password: password,
      ));
      
      if (response != null) {
        await _storeAuthData(response);
        return true;
      }
      
      return false;
    });
  } on AppError catch (e) {
    // Handle specific authentication errors
    if (e.type == AppErrorType.authentication) {
      // Show user-friendly authentication error
      setError(AppError(
        type: AppErrorType.authentication,
        userMessage: 'Invalid email or password. Please try again.',
        technicalMessage: e.technicalMessage,
      ));
    } else {
      rethrow;
    }
    
    return false;
  }
}
```

## Best Practices

1. **Secure Token Storage**: Always use secure storage for authentication tokens
2. **Token Refresh**: Implement automatic token refresh before expiry
3. **Error Handling**: Provide user-friendly error messages for authentication failures
4. **Form Validation**: Implement comprehensive form validation
5. **Loading States**: Show loading indicators during authentication operations
6. **Session Management**: Properly manage user sessions and logout
7. **Password Security**: Enforce strong password requirements
8. **Navigation**: Use proper navigation patterns for authentication flows

## Testing

When testing the authentication feature:

```dart
// Test auth provider
void main() {
  late AuthProvider provider;
  late MockApiService mockApiService;
  late MockSecureStorageService mockSecureStorage;
  
  setUp(() {
    mockApiService = MockApiService();
    mockSecureStorage = MockSecureStorageService();
    provider = AuthProvider(mockApiService, mockSecureStorage);
  });
  
  test('login successful stores tokens', () async {
    final authResponse = AuthResponse(
      token: 'test-token',
      refreshToken: 'refresh-token',
      user: User(id: 1, email: 'test@example.com', name: 'Test User'),
    );
    
    when(() => mockApiService.postAndDecode<AuthResponse>(
      any(),
      any(),
      any(),
    )).thenAnswer((_) async => authResponse);
    
    final result = await provider.login('test@example.com', 'password');
    
    expect(result, true);
    expect(provider.isLoggedIn, true);
    expect(provider.user?.email, 'test@example.com');
    
    // Verify tokens were stored
    verify(() => mockSecureStorage.writeSecureData('auth_token', 'test-token')).called(1);
    verify(() => mockSecureStorage.writeSecureData('refresh_token', 'refresh-token')).called(1);
  });
  
  test('logout clears tokens', () async {
    // Set up logged in state
    provider.testSetLoggedIn(); // Helper method for testing
    
    await provider.logout();
    
    expect(provider.isLoggedIn, false);
    expect(provider.user, null);
    
    // Verify tokens were cleared
    verify(() => mockSecureStorage.deleteSecureData('auth_token')).called(1);
    verify(() => mockSecureStorage.deleteSecureData('refresh_token')).called(1);
  });
}
```

This documentation ensures consistent implementation of the authentication feature and provides a solid foundation for future development.
