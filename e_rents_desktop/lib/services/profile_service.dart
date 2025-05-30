import 'dart:convert';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/auth/change_password_request_model.dart';
import 'package:e_rents_desktop/services/api_service.dart';

// TODO: Full backend integration for all profile features is pending.
// Ensure all endpoints are functional (especially multipart for image upload) and error handling is robust.
class ProfileService extends ApiService {
  ProfileService(super.baseUrl, super.storageService);

  Future<User> getMyProfile() async {
    print('ProfileService: Attempting to fetch user profile...');
    try {
      final response = await get('/profile/me', authenticated: true);
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final user = User.fromJson(jsonResponse);
      print(
        'ProfileService: Successfully fetched user profile for ${user.username}.',
      );
      return user;
    } catch (e) {
      print(
        'ProfileService: Error fetching user profile: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to fetch user profile. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<User> updateMyProfile(Map<String, dynamic> userData) async {
    print('ProfileService: Attempting to update user profile...');
    try {
      final response = await put('/profile/me', userData, authenticated: true);
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final updatedUser = User.fromJson(jsonResponse);
      print(
        'ProfileService: Successfully updated user profile for ${updatedUser.username}.',
      );
      return updatedUser;
    } catch (e) {
      print(
        'ProfileService: Error updating user profile: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to update user profile. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<void> changePassword(ChangePasswordRequestModel request) async {
    print('ProfileService: Attempting to change password...');
    try {
      await post(
        '/profile/change-password',
        request.toJson(),
        authenticated: true,
      );
      print('ProfileService: Change password request sent successfully.');
    } catch (e) {
      print(
        'ProfileService: Error changing password: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to change password. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<User> uploadProfileImage(String imagePath) async {
    print(
      'ProfileService: Attempting to upload profile image (simulated as path)...',
    );
    // TODO: Implement actual multipart file upload for profile image.
    try {
      final response = await post('/profile/upload-profile-image', {
        'imagePath': imagePath, // This is a placeholder for actual file upload
      }, authenticated: true);
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final user = User.fromJson(jsonResponse);
      print(
        'ProfileService: Profile image upload request completed for ${user.username}.',
      );
      return user;
    } catch (e) {
      print(
        'ProfileService: Error uploading profile image: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to upload profile image. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<User> linkPaypal(String paypalEmail) async {
    print('ProfileService: Attempting to link PayPal account...');
    try {
      final response = await post('/profile/link-paypal', {
        'email': paypalEmail,
      }, authenticated: true);
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final user = User.fromJson(jsonResponse);
      print(
        'ProfileService: PayPal link request completed for ${user.username}.',
      );
      return user;
    } catch (e) {
      print(
        'ProfileService: Error linking PayPal account: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to link PayPal account. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<User> unlinkPaypal() async {
    print('ProfileService: Attempting to unlink PayPal account...');
    try {
      final response = await post(
        '/profile/unlink-paypal',
        {},
        authenticated: true,
      );
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final user = User.fromJson(jsonResponse);
      print(
        'ProfileService: PayPal unlink request completed for ${user.username}.',
      );
      return user;
    } catch (e) {
      print(
        'ProfileService: Error unlinking PayPal account: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to unlink PayPal account. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }
}
