import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/services/secure_storage_service.dart';

/// Simplified authentication service replacing complex AuthProvider
/// Uses simple async methods instead of Provider pattern for basic auth operations
class SimpleAuthService {
  final ApiService _apiService;
  final SecureStorageService _storageService;

  SimpleAuthService(this._apiService, this._storageService);

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    final token = await _storageService.getToken();
    return token != null;
  }

  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    try {
      final response = await _apiService.post(
        '/auth/login',
        {
          // Support both username or email on backend
          'username': email,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data.containsKey('token')) {
          await _storageService.storeToken(data['token']);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Sign in error: $e');
      return false;
    }
  }

  /// Register new user account
  Future<bool> register(Map<String, dynamic> userData) async {
    try {
      final response = await _apiService.post(
        '/auth/register',
        userData,
      );
      
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    }
  }

  /// Send password reset email
  Future<bool> forgotPassword(String email) async {
    try {
      final response = await _apiService.post(
        '/auth/forgot-password',
        {'email': email},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Forgot password error: $e');
      return false;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _storageService.clearToken();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }
}