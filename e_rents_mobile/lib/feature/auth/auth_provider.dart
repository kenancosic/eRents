import 'dart:convert';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/services/secure_storage_service.dart';
import 'package:flutter/material.dart';

class AuthProvider extends BaseProvider {
  final SecureStorageService _secureStorageService;

  AuthProvider(ApiService apiService, this._secureStorageService) : super(apiService);

  // Use inherited loading/error state from BaseProvider
  // isLoading, error, hasError are available

  bool get isAuthenticated => _secureStorageService.getToken() != null;

  Future<bool> login(String email, String password) async {
    return await executeWithStateAndMessage(() async {
      // Use direct post method since login returns custom token structure
      final response = await api.post(
        '/auth/login',
        {
          'email': email,
          'password': password,
        },
        authenticated: false,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data.containsKey('token')) {
          await _secureStorageService.storeToken(data['token']);
          debugPrint('AuthProvider: Login successful for $email');
          return true;
        }
      }
      
      throw Exception('Invalid response from server');
    }, 'Login failed. Please check your credentials.') ?? false;
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    return await executeWithStateAndMessage(() async {
      final response = await api.post(
        '/auth/register',
        userData,
        authenticated: false,
      );
      
      if (response.statusCode == 201) {
        debugPrint('AuthProvider: Registration successful for ${userData['email']}');
        return true;
      }
      
      throw Exception('Registration failed');
    }, 'Registration failed. Please try again.') ?? false;
  }

  Future<void> logout() async {
    await executeWithStateAndMessage(() async {
      await _secureStorageService.clearToken();
      debugPrint('AuthProvider: User logged out successfully');
    }, 'Failed to logout');
  }

  Future<bool> forgotPassword(String email) async {
    return await executeWithStateAndMessage(() async {
      final response = await api.post(
        '/auth/forgot-password',
        {'email': email},
        authenticated: false,
      );
      
      if (response.statusCode == 200) {
        debugPrint('AuthProvider: Password reset email sent to $email');
        return true;
      }
      
      throw Exception('Failed to send reset email');
    }, 'Failed to send password reset email.') ?? false;
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    return await executeWithStateAndMessage(() async {
      final response = await api.post(
        '/auth/reset-password',
        {
          'token': token,
          'password': newPassword,
        },
        authenticated: false,
      );
      
      if (response.statusCode == 200) {
        debugPrint('AuthProvider: Password reset successful');
        return true;
      }
      
      throw Exception('Password reset failed');
    }, 'Failed to reset password.') ?? false;
  }
}
