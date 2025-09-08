import 'dart:convert';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/services/secure_storage_service.dart';
import 'package:flutter/material.dart';

class AuthProvider extends BaseProvider {
  final SecureStorageService _secureStorageService;
  String? _accessToken;
  String? _refreshToken;

  AuthProvider(super.api, this._secureStorageService) {
    // Initialize the access token from secure storage
    _initializeToken();
  }

  /// Initialize the access token from secure storage
  Future<void> _initializeToken() async {
    _accessToken = await _secureStorageService.getToken();
  }

  // Use inherited loading/error state from BaseProvider
  // isLoading, error, hasError are available

  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  Future<bool> login(String identifier, String password) async {
    final result = await executeWithStateAndMessage(() async {
      // Determine if the identifier is an email or username
      final isEmail = identifier.contains('@');
      final requestBody = {
        'password': password,
      };
      
      // Add either email or username field based on the identifier type
      if (isEmail) {
        requestBody['email'] = identifier;
      } else {
        requestBody['username'] = identifier;
      }
      
      // Use direct post method since login returns custom token structure
      final response = await api.post(
        'Auth/login',
        requestBody,
        authenticated: false,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _accessToken = data['accessToken'] as String?;
        _refreshToken = data['refreshToken'] as String?;
        
        // Store tokens securely
        if (_accessToken != null) {
          await _secureStorageService.storeToken(_accessToken!);
        }
        
        debugPrint('AuthProvider: Login successful for $identifier');
        return true;
      }
      
      throw Exception('Invalid response from server');
    }, 'Login failed. Please check your credentials.');
    
    return result ?? false;
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    final result = await executeWithStateAndMessage(() async {
      final response = await api.post(
        'Auth/register',
        userData,
        authenticated: false,
      );
      
      if (response.statusCode == 201) {
        debugPrint('AuthProvider: Registration successful for ${userData['email']}');
        return true;
      }
      
      throw Exception('Registration failed');
    }, 'Registration failed. Please try again.');
    
    return result ?? false;
  }

  Future<void> logout() async {
    await executeWithStateAndMessage(() async {
      await _secureStorageService.clearToken();
      _accessToken = null;
      _refreshToken = null;
      debugPrint('AuthProvider: User logged out successfully');
    }, 'Failed to logout');
  }

  Future<bool> forgotPassword(String email) async {
    final result = await executeWithStateAndMessage(() async {
      final response = await api.post(
        'Auth/forgot-password',
        {'email': email},
        authenticated: false,
      );
      
      if (response.statusCode == 200) {
        debugPrint('AuthProvider: Password reset email sent to $email');
        return true;
      }
      
      throw Exception('Failed to send reset email');
    }, 'Failed to send password reset email.');
    
    return result ?? false;
  }

  Future<bool> resetPassword(String email, String code, String newPassword) async {
    final result = await executeWithStateAndMessage(() async {
      final response = await api.post(
        'Auth/reset-password',
        {
          'email': email,
          'resetCode': code,
          'newPassword': newPassword,
          'confirmPassword': newPassword,
        },
        authenticated: false,
      );
      
      if (response.statusCode == 200) {
        debugPrint('AuthProvider: Password reset successful');
        return true;
      }
      
      throw Exception('Password reset failed');
    }, 'Failed to reset password.');
    
    return result ?? false;
  }

  /// Verifies a reset code sent to the user's email
  Future<bool> verifyCode(String email, String code) async {
    final result = await executeWithStateAndMessage(() async {
      final response = await api.post(
        'Auth/verify',
        {
          'email': email,
          'code': code,
        },
        authenticated: false,
      );
      
      if (response.statusCode == 200) {
        debugPrint('AuthProvider: Code verification successful');
        return true;
      }
      
      throw Exception('Invalid verification code');
    }, 'Invalid verification code.');
    
    return result ?? false;
  }

  /// Refreshes the authentication token
  Future<bool> refreshToken() async {
    if (_refreshToken == null) {
      throw Exception('No refresh token available');
    }
    
    final result = await executeWithStateAndMessage(() async {
      final response = await api.post(
        'Auth/refresh-token',
        {
          'refreshToken': _refreshToken,
        },
        authenticated: false,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['accessToken'] as String?;
        _refreshToken = data['refreshToken'] as String?;
        notifyListeners();
        
        // Save tokens securely
        if (_accessToken != null) {
          await _secureStorageService.storeToken(_accessToken!);
        }
        
        debugPrint('AuthProvider: Token refresh successful');
        return true;
      }
      
      // Clear tokens if refresh fails
      await logout();
      throw Exception('Failed to refresh token');
    }, 'Session expired. Please login again.');
    
    return result ?? false;
  }
  
  /// Checks if token needs refresh (more frequent checks to avoid expiration)
  bool shouldRefreshToken() {
    // Always return false to effectively disable token expiration
    return false;
  }
}
