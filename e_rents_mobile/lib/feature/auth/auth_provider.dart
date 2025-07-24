import 'dart:convert';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/services/secure_storage_service.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  final SecureStorageService _secureStorageService;

  AuthProvider(this._apiService, this._secureStorageService);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _secureStorageService.storeToken(data['token']);
        _setLoading(false);
        return true;
      }
      _setError('Login failed. Please check your credentials.');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An error occurred during login.');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.post('/auth/register', userData);
      if (response.statusCode == 201) {
        _setLoading(false);
        return true;
      }
      _setError('Registration failed.');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An error occurred during registration.');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _secureStorageService.clearToken();
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.post('/auth/forgot-password', {'email': email});
      if (response.statusCode == 200) {
        _setLoading(false);
        return true;
      }
      _setError('Failed to send password reset email.');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An error occurred while sending the password reset email.');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.post('/auth/reset-password', {
        'token': token,
        'password': newPassword,
      });
      if (response.statusCode == 200) {
        _setLoading(false);
        return true;
      }
      _setError('Failed to reset password.');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An error occurred during password reset.');
      _setLoading(false);
      return false;
    }
  }
}
