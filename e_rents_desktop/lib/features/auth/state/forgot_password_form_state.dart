import 'package:flutter/material.dart';

// NOTE: In a real app, this would take an AuthService dependency
// to call the backend API for password reset.
// final AuthService _authService;
// ForgotPasswordFormState(this._authService);

class ForgotPasswordFormState extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isEmailSent = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmailSent => _isEmailSent;

  Future<void> resetPassword(String email) async {
    if (email.isEmpty) {
      _errorMessage = 'Please enter your email address.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network call to password reset service
      print('Reset password for email: $email');
      await Future.delayed(const Duration(seconds: 2));

      _isEmailSent = true;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
