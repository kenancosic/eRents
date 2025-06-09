import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/models/tenant_preference_model.dart';
import 'package:e_rents_mobile/core/models/user.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final ApiService _apiService;
  final String _userKey = 'user_data';
  final String _tenantPreferencesKey = 'tenant_preferences_data';

  UserService(this._apiService);

  /// Get user profile from API with local storage fallback
  Future<User?> getUserProfile() async {
    try {
      // Try to fetch from API first
      final response =
          await _apiService.get('/Users/profile', authenticated: true);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final user = User.fromJson(data);

        // Save to local storage for offline access
        await saveUserToLocal(user);
        return user;
      } else if (response.statusCode == 401) {
        // Unauthorized - clear local data
        await clearUserData();
        return null;
      } else {
        debugPrint(
            'UserService: Failed to load profile from API: ${response.statusCode} ${response.body}');

        // Fallback to local storage
        return await _getUserFromLocal();
      }
    } catch (e) {
      debugPrint('UserService.getUserProfile API error: $e');

      // Fallback to local storage on network error
      return await _getUserFromLocal();
    }
  }

  /// Get user from local storage
  Future<User?> _getUserFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);

      if (userData != null) {
        debugPrint('UserService: Loaded user from local storage');
        return User.fromJson(jsonDecode(userData));
      }
    } catch (e) {
      debugPrint('UserService: Error loading from local storage: $e');
    }

    return null;
  }

  /// Update user profile
  Future<User?> updateUserProfile(User updatedUser) async {
    try {
      final response = await _apiService.put(
        '/Users/profile',
        updatedUser.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final user = User.fromJson(data);

        // Update local storage
        await saveUserToLocal(user);
        return user;
      } else {
        debugPrint(
            'UserService: Failed to update profile: ${response.statusCode} ${response.body}');
        throw Exception(
            'Failed to update profile: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('UserService.updateUserProfile: $e');
      if (e is Exception) rethrow;
      throw Exception('An error occurred while updating profile: $e');
    }
  }

  /// Upload profile image
  Future<bool> uploadProfileImage(File imageFile) async {
    try {
      // For now, use a simple implementation
      // In a real implementation, you'd use multipart upload
      final response = await _apiService.post(
        '/Users/profile/image',
        {
          'fileName': imageFile.path.split('/').last,
          'contentType': 'image/jpeg', // You'd detect this properly
        },
        authenticated: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint(
            'UserService: Failed to upload image: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('UserService.uploadProfileImage: $e');
      return false;
    }
  }

  /// Save user to local storage
  Future<void> saveUserToLocal(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      debugPrint('UserService: Saved user to local storage');
    } catch (e) {
      debugPrint('UserService: Error saving to local storage: $e');
    }
  }

  /// Clear user data from local storage
  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      debugPrint('UserService: Cleared local user data');
    } catch (e) {
      debugPrint('UserService: Error clearing local storage: $e');
    }
  }

  /// Get payment methods
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      final response =
          await _apiService.get('/Users/payment-methods', authenticated: true);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        debugPrint(
            'UserService: Failed to load payment methods: ${response.statusCode} ${response.body}');

        // Return mock data as fallback
        return [
          {
            'id': '1',
            'type': 'paypal',
            'email': 'user@example.com',
            'isDefault': true
          }
        ];
      }
    } catch (e) {
      debugPrint('UserService.getPaymentMethods: $e');

      // Return mock data as fallback
      return [
        {
          'id': '1',
          'type': 'paypal',
          'email': 'user@example.com',
          'isDefault': true
        }
      ];
    }
  }

  /// Add payment method
  Future<bool> addPaymentMethod(Map<String, dynamic> paymentData) async {
    try {
      final response = await _apiService.post(
        '/Users/payment-methods',
        paymentData,
        authenticated: true,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('UserService.addPaymentMethod: $e');
      return false;
    }
  }

  /// Get tenant preferences
  Future<TenantPreferenceModel?> getTenantPreferences(String userId) async {
    try {
      final response = await _apiService.get('/Users/$userId/preferences',
          authenticated: true);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final preferences = TenantPreferenceModel.fromJson(data);

        // Save to local storage
        await _saveTenantPreferencesToLocal(userId, preferences);
        return preferences;
      } else if (response.statusCode == 404) {
        // No preferences found - this is normal for new users
        return null;
      } else {
        debugPrint(
            'UserService: Failed to load preferences: ${response.statusCode} ${response.body}');

        // Fallback to local storage
        return await _getTenantPreferencesFromLocal(userId);
      }
    } catch (e) {
      debugPrint('UserService.getTenantPreferences: $e');

      // Fallback to local storage
      return await _getTenantPreferencesFromLocal(userId);
    }
  }

  /// Get tenant preferences from local storage
  Future<TenantPreferenceModel?> _getTenantPreferencesFromLocal(
      String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesData =
          prefs.getString('${_tenantPreferencesKey}_$userId');

      if (preferencesData != null) {
        return TenantPreferenceModel.fromJson(jsonDecode(preferencesData));
      }
    } catch (e) {
      debugPrint(
          'UserService: Error loading preferences from local storage: $e');
    }

    return null;
  }

  /// Save tenant preferences to local storage
  Future<void> _saveTenantPreferencesToLocal(
      String userId, TenantPreferenceModel preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          '${_tenantPreferencesKey}_$userId', jsonEncode(preferences.toJson()));
    } catch (e) {
      debugPrint('UserService: Error saving preferences to local storage: $e');
    }
  }

  /// Update/Create tenant preferences
  Future<bool> updateTenantPreferences(
      TenantPreferenceModel preferences) async {
    try {
      final response = await _apiService.put(
        '/Users/${preferences.userId}/preferences',
        preferences.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Save to local storage
        await _saveTenantPreferencesToLocal(preferences.userId, preferences);
        return true;
      } else {
        debugPrint(
            'UserService: Failed to update preferences: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('UserService.updateTenantPreferences: $e');
      return false;
    }
  }

  /// Get user by ID (for admin/search features)
  Future<User?> getUserById(int userId) async {
    try {
      final response =
          await _apiService.get('/Users/$userId', authenticated: true);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return User.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        debugPrint(
            'UserService: Failed to load user: ${response.statusCode} ${response.body}');
        throw Exception('Failed to load user: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('UserService.getUserById: $e');
      if (e is Exception) rethrow;
      throw Exception('An error occurred while fetching user: $e');
    }
  }

  /// Search users (for admin features)
  Future<List<User>> searchUsers([Map<String, dynamic>? params]) async {
    try {
      String endpoint = '/Users/search';

      // Add query parameters if provided
      if (params != null && params.isNotEmpty) {
        final queryParams = params.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        endpoint += '?$queryParams';
      }

      final response = await _apiService.get(endpoint, authenticated: true);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        debugPrint(
            'UserService: Failed to search users: ${response.statusCode} ${response.body}');
        throw Exception('Failed to search users: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('UserService.searchUsers: $e');
      if (e is Exception) rethrow;
      throw Exception('An error occurred while searching users: $e');
    }
  }
}
