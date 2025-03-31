import 'dart:convert';

import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';

class AuthService {
  final ApiService apiService;
  final SecureStorageService _storageService;

  AuthService(this.apiService, this._storageService);

  Future<bool> login(String usernameOrEmail, String password) async {
    final response = await apiService.post('/Auth/Login', {
      'usernameOrEmail': usernameOrEmail,
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _storageService.storeToken(data['token']);
      return true;
    } else {
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    final response = await apiService.post('/Auth/Register', userData);
    return response.statusCode == 200;
  }

  Future<void> logout() async {
    await _storageService.clearToken();
  }

  Future<String?> getToken() async {
    return await _storageService.getToken();
  }

  Future<bool> forgotPassword(String email) async {
    final response = await apiService.post('/Auth/ForgotPassword', {
      'email': email,
    });
    return response.statusCode == 200;
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    final response = await apiService.post('/Auth/ResetPassword', {
      'token': token,
      'newPassword': newPassword,
    });
    return response.statusCode == 200;
  }
}
