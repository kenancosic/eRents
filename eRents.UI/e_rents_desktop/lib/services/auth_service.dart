import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';

class AuthService extends ApiService {
  // Development mode flag
  static bool isDevelopmentMode = true;
  // In-memory token storage for development
  static String? _devToken;
  static Map<String, dynamic>? _devUser;

  // Add getter to check token existence
  static bool get hasToken => isDevelopmentMode ? _devToken != null : false;

  AuthService(super.baseUrl, super.storageService);

  Future<Map<String, dynamic>> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Get mock users
    final mockUsers = MockDataService.getMockUsers();

    try {
      // Find matching user
      final user = mockUsers.firstWhere(
        (user) => user.email == email && user.email.split('@')[0] == password,
      );

      // Generate mock token
      final token = 'mock_token_${user.id}';

      if (isDevelopmentMode) {
        // Store in memory for development
        _devToken = token;
        _devUser = user.toJson();
      } else {
        // Store in secure storage for production
        await secureStorageService.storeToken(token);
      }

      return {'token': token, 'user': user.toJson()};
    } catch (e) {
      // If no user found, throw invalid credentials error
      throw Exception('Invalid email or password');
    }
  }

  Future<void> logout() async {
    if (isDevelopmentMode) {
      // Clear in-memory storage
      _devToken = null;
      _devUser = null;
    } else {
      // Clear secure storage
      await secureStorageService.clearToken();
    }
  }

  Future<bool> isAuthenticated() async {
    if (isDevelopmentMode) {
      return _devToken != null;
    }
    final token = await secureStorageService.getToken();
    return token != null;
  }

  @override
  Future<Map<String, String>> getHeaders() async {
    String? token;
    if (isDevelopmentMode) {
      token = _devToken;
    } else {
      token = await secureStorageService.getToken();
    }

    final headers = await super.getHeaders();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return true; // Mock successful registration
  }

  Future<bool> forgotPassword(String email) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return true; // Mock successful password reset request
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return true; // Mock successful password reset
  }
}
