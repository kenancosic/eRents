import 'dart:convert';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/auth/change_password_request_model.dart';
import 'package:e_rents_desktop/services/api_service.dart';

class ProfileService extends ApiService {
  ProfileService(super.baseUrl, super.storageService);

  Future<User> getMyProfile() async {
    final response = await get('/profile/me', authenticated: true);
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    return User.fromJson(jsonResponse);
  }

  Future<User> updateMyProfile(Map<String, dynamic> userData) async {
    final response = await put('/profile/me', userData, authenticated: true);
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    return User.fromJson(jsonResponse);
  }

  Future<void> changePassword(ChangePasswordRequestModel request) async {
    await post(
      '/profile/change-password',
      request.toJson(),
      authenticated: true,
    );
  }

  Future<User> uploadProfileImage(String imagePath) async {
    // In a real app, this would be a multipart request.
    // For now, simulating by sending the path and expecting the updated User object.
    final response = await post('/profile/upload-profile-image', {
      'imagePath': imagePath,
    }, authenticated: true);
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    return User.fromJson(jsonResponse);
  }

  Future<User> linkPaypal(String paypalEmail) async {
    final response = await post('/profile/link-paypal', {
      'email': paypalEmail,
    }, authenticated: true);
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    return User.fromJson(jsonResponse);
  }

  Future<User> unlinkPaypal() async {
    final response = await post(
      '/profile/unlink-paypal',
      {},
      authenticated: true,
    );
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    return User.fromJson(jsonResponse);
  }
}
