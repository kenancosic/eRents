import 'dart:convert';
import 'dart:io';

import 'package:e_rents_mobile/config.dart';
import 'package:e_rents_mobile/core/models/user.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/services/secure_storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final ApiService _apiService;
  final String _userKey = 'user_data';

  UserService(this._apiService);

  // Get user profile from local storage or API
  Future<User?> getUserProfile() async {
    try {
      // First try to get from local storage
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);

      if (userData != null) {
        return User.fromJson(json.decode(userData));
      }

      // If not in local storage, fetch from API (when backend is ready)
      // final response = await _apiService.get('/api/users/profile', authenticated: true);
      // if (response.statusCode == 200) {
      //   final user = User.fromJson(json.decode(response.body));
      //   // Save to local storage
      //   await saveUserToLocal(user);
      //   return user;
      // }

      // For now, return mock data
      return User(
        userId: 1,
        username: 'johndoe',
        email: 'johnDoe@gmail.com',
        name: 'John',
        lastName: 'Doe',
        phoneNumber: '+1234567890',
      );
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<User?> updateUserProfile(User updatedUser) async {
    try {
      // When backend is ready
      // final response = await _apiService.put(
      //   '/api/users/profile',
      //   updatedUser.toJson(),
      //   authenticated: true
      // );

      // if (response.statusCode == 200) {
      //   final user = User.fromJson(json.decode(response.body));
      //   await saveUserToLocal(user);
      //   return user;
      // }

      // For now, just update local
      await saveUserToLocal(updatedUser);
      return updatedUser;
    } catch (e) {
      print('Error updating user profile: $e');
      return null;
    }
  }

  // Upload profile image
  Future<bool> uploadProfileImage(File imageFile) async {
    try {
      // When backend is ready
      // var request = http.MultipartRequest(
      //   'POST',
      //   Uri.parse('${_apiService.baseUrl}/api/users/profile/image'),
      // );

      // // Add auth token
      // final token = await _apiService.secureStorageService.getToken();
      // if (token != null) {
      //   request.headers['Authorization'] = 'Bearer $token';
      // }

      // request.files.add(await http.MultipartFile.fromPath(
      //   'image',
      //   imageFile.path,
      // ));
      // var response = await request.send();
      // return response.statusCode == 200;

      // For now, just return success
      return true;
    } catch (e) {
      print('Error uploading profile image: $e');
      return false;
    }
  }

  // Save user to local storage
  Future<void> saveUserToLocal(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  // Clear user data from local storage
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // Get payment methods (for future implementation)
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      // When backend is ready
      // final response = await _apiService.get('/api/users/payment-methods', authenticated: true);
      // if (response.statusCode == 200) {
      //   final List<dynamic> data = json.decode(response.body);
      //   return List<Map<String, dynamic>>.from(data);
      // }

      // For now, return mock data
      return [
        {
          'id': '1',
          'type': 'paypal',
          'email': 'john.doe@example.com',
          'isDefault': true
        }
      ];
    } catch (e) {
      print('Error getting payment methods: $e');
      return [];
    }
  }

  // Add payment method (for future implementation)
  Future<bool> addPaymentMethod(Map<String, dynamic> paymentData) async {
    try {
      // When backend is ready
      // final response = await _apiService.post(
      //   '/api/users/payment-methods',
      //   paymentData,
      //   authenticated: true
      // );
      // return response.statusCode == 200 || response.statusCode == 201;

      // For now, return success
      return true;
    } catch (e) {
      print('Error adding payment method: $e');
      return false;
    }
  }
}
