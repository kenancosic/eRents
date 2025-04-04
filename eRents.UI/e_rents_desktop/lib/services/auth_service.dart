import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';

class AuthService extends ApiService {
  AuthService(String baseUrl, SecureStorageService storageService)
    : super(baseUrl, storageService);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await post('/auth/login', {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['token'] != null) {
        await secureStorageService.storeToken(data['token']);
      }
      return data;
    }
    throw Exception('Login failed');
  }

  Future<void> logout() async {
    await secureStorageService.clearToken();
  }

  Future<bool> isAuthenticated() async {
    final token = await secureStorageService.getToken();
    return token != null;
  }

  @override
  Future<Map<String, String>> getHeaders() async {
    final token = await secureStorageService.getToken();
    final headers = await super.getHeaders();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    final response = await post('/Auth/Register', userData);
    return response.statusCode == 200;
  }

  Future<bool> forgotPassword(String email) async {
    final response = await post('/Auth/ForgotPassword', {'email': email});
    return response.statusCode == 200;
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    final response = await post('/Auth/ResetPassword', {
      'token': token,
      'newPassword': newPassword,
    });
    return response.statusCode == 200;
  }
}
