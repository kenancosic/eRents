import 'dart:convert';
import 'dart:io';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/auth/change_password_request_model.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:http/http.dart' as http;

class ProfileService extends ApiService {
  ProfileService(super.baseUrl, super.secureStorageService);

  /// Get current user's profile
  Future<User> getMyProfile() async {
    try {
      final response = await get('/profile/me', authenticated: true);
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final user = User.fromJson(jsonResponse);
      return user;
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  /// Update current user's profile
  Future<User> updateMyProfile(User user) async {
    try {
      // Create UserUpdateRequest format expected by backend
      final updateData = {
        'firstName': user.firstName,
        'lastName': user.lastName,
        'phoneNumber': user.phone,
        'addressDetail': user.addressDetail?.toJson(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final response = await put(
        '/profile/me',
        updateData,
        authenticated: true,
      );
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final updatedUser = User.fromJson(jsonResponse);
      return updatedUser;
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Change current user's password
  Future<void> changePassword(ChangePasswordRequestModel request) async {
    try {
      await post(
        '/profile/change-password',
        request.toJson(),
        authenticated: true,
      );
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  /// Upload profile image (multipart file upload)
  Future<User> uploadProfileImage(String imagePath) async {
    try {
      final uri = Uri.parse('$baseUrl/profile/upload-profile-image');
      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      final token = await secureStorageService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add platform header
      request.headers['Client-Type'] = 'Desktop';

      // Add the image file
      final file = await http.MultipartFile.fromPath('image', imagePath);
      request.files.add(file);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final user = User.fromJson(jsonResponse);
        return user;
      } else {
        throw Exception(
          'Upload failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Link PayPal account
  Future<User> linkPaypal(String paypalEmail) async {
    try {
      final response = await post('/profile/link-paypal', {
        'email': paypalEmail,
      }, authenticated: true);

      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final user = User.fromJson(jsonResponse);
      return user;
    } catch (e) {
      throw Exception('Failed to link PayPal account: $e');
    }
  }

  /// Unlink PayPal account
  Future<User> unlinkPaypal() async {
    try {
      final response = await post(
        '/profile/unlink-paypal',
        {},
        authenticated: true,
      );

      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final user = User.fromJson(jsonResponse);
      return user;
    } catch (e) {
      throw Exception('Failed to unlink PayPal account: $e');
    }
  }
}
