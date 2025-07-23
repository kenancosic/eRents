import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/models/auth/login_request_model.dart';
import 'package:e_rents_desktop/models/auth/register_request_model.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'package:logging/logging.dart';
import 'package:e_rents_desktop/base/app_error.dart';

final log = Logger('AuthProvider');

/// A consolidated provider for authentication and form state management.
class AuthProvider extends ChangeNotifier {
  // Dependencies
  final ApiService _api;
  final SecureStorageService _storage;

  // --- State --------------------------------------------------------------
  User? _currentUser;
  // Forgot Password State
  bool _isAuthenticated = false;
  bool _isLoading = false;
  AppError? _error;

  // --- Form State ---------------------------------------------------------
  bool _rememberMe = false;
  bool _emailSent = false;

  // Constructor
  AuthProvider({required ApiService apiService, required SecureStorageService storage})
      : _api = apiService,
        _storage = storage {
    _init();
  }

  // ---------------- Public Getters ---------------------------------------
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  AppError? get error => _error;
  String? get errorMessage => _error?.message;
  bool get rememberMe => _rememberMe;
  bool get emailSent => _emailSent;

  // ---------------- Internal helpers -------------------------------------
  Future<void> _init() async {
    _setLoading(true);
    try {
      _isAuthenticated = await _checkToken();
      if (_isAuthenticated) {
        await _loadMe();
      }
    } catch (e, s) {
      _setError(AppError.fromException(e, s));
      _isAuthenticated = false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _checkToken() async => (await _storage.getToken()) != null;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }





  void _setError(AppError? err) {
    _error = err;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  // ---------------- API Calls --------------------------------------------
  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> body,
      {bool authenticated = false}) async {
    final response = await _api.post(
      endpoint,
      body,
      authenticated: authenticated,
      customHeaders: const {'Client-Type': 'Desktop'},
    );
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _get(String endpoint,
      {bool authenticated = false}) async {
    final response = await _api.get(
      endpoint,
      authenticated: authenticated,
      customHeaders: const {'Client-Type': 'Desktop'},
    );
    return json.decode(response.body) as Map<String, dynamic>;
  }

  // ---------------- Public API & Form Methods --------------------------------

  void setRememberMe(bool? value) {
    _rememberMe = value ?? false;
    notifyListeners();
  }

  Future<String?> loadRememberedCredentials() async {
    final rememberedEmail = await _storage.getData('remembered_email');
    if (rememberedEmail != null) {
      _rememberMe = true;
      notifyListeners();
    }
    return rememberedEmail;
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();
    _emailSent = false;

    try {
      await _post('Auth/ForgotPassword', {'email': email});
      _emailSent = true;
      log.info('Password reset email sent successfully to $email.');
      return true;
    } catch (e, s) {
      _setError(AppError.fromException(e, s, 'Failed to send password reset email.'));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      final request = LoginRequestModel(usernameOrEmail: email, password: password);
      final result = await _post('/Auth/Login', request.toJson());
      final token = result['token'] as String?;

      if (token == null) throw Exception('Token not returned from API');

      await _storage.storeToken(token);
      await _loadMe();

      if (_currentUser?.role != UserType.landlord) {
        await logout();
        throw AppError(
          type: ErrorType.authentication,
          message: 'Desktop application is for landlords only.',
        );
      }

      if (_rememberMe) {
        await _storage.storeData('remembered_email', email);
      } else {
        await _storage.clearData('remembered_email');
      }

      _isAuthenticated = true;
      return true;
    } catch (e, s) {
      _setError(AppError.fromException(e, s));
      _isAuthenticated = false;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _storage.clearToken();
      _currentUser = null;
      _isAuthenticated = false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(RegisterRequestModel request) async {
    _setError(
      AppError(
        type: ErrorType.validation,
        message: 'Account registration is not available in the desktop application.',
      ),
    );
  }

  // ---------------- Private helpers --------------------------------------
  Future<void> _loadMe() async {
    try {
      final me = await _get('/Auth/Me', authenticated: true);
      if (me.containsKey('user')) {
        _currentUser = User.fromJson(me['user']);
      } else {
        throw Exception('Malformed user data');
      }
    } catch (e, s) {
      await _storage.clearToken();
      _setError(AppError.fromException(e, s));
      rethrow;
    }
  }
}
