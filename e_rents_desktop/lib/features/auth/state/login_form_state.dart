import 'package:e_rents_desktop/base/app_error.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:e_rents_desktop/models/auth/login_request_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginFormState extends ChangeNotifier {
  final AuthProvider authProvider;
  final _storage = const FlutterSecureStorage();

  LoginFormState(this.authProvider);

  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get rememberMe => _rememberMe;

  Future<void> loadRememberedCredentials(
    TextEditingController emailController,
  ) async {
    final rememberedEmail = await _storage.read(key: 'remembered_email');
    if (rememberedEmail != null) {
      emailController.text = rememberedEmail;
      _rememberMe = true;
      notifyListeners();
    }
  }

  void setRememberMe(bool? value) {
    _rememberMe = value ?? false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await authProvider.login(
        LoginRequestModel(usernameOrEmail: email, password: password),
      );

      if (success) {
        if (_rememberMe) {
          await _storage.write(key: 'remembered_email', value: email);
        } else {
          await _storage.delete(key: 'remembered_email');
        }
      } else {
        _errorMessage = authProvider.errorMessage;
      }
      return success;
    } catch (e, s) {
      final appError = AppError.fromException(e, s);
      _errorMessage = appError.userMessage;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
