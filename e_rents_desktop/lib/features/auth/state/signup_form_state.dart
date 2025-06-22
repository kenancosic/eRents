import 'package:e_rents_desktop/base/app_error.dart';
import 'package:flutter/material.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:e_rents_desktop/models/auth/register_request_model.dart';

class SignupFormState extends ChangeNotifier {
  final AuthProvider authProvider;

  SignupFormState(this.authProvider);

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _errorMessage = 'Please fill in all fields.';
      notifyListeners();
      return false;
    }

    if (password != confirmPassword) {
      _errorMessage = 'Passwords do not match.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // The current AuthProvider.register displays an error as registration is not supported.
      // This will demonstrate that the error is properly handled by the form state.
      final user = await authProvider.register(
        RegisterRequestModel(
          name: name.split(' ').first, // Simple split for first name
          lastName:
              name.split(' ').length > 1
                  ? name.split(' ').sublist(1).join(' ')
                  : '', // and last name
          email: email,
          username: email, // Use email as username for simplicity
          password: password,
          confirmPassword: confirmPassword,
          dateOfBirth: DateTime.now(), // Placeholder
          role: 'tenant', // Placeholder
        ),
      );

      // If registration is ever successful, this will handle it.
      if (user != null) {
        return true;
      } else {
        _errorMessage =
            authProvider.errorMessage ?? 'An unknown error occurred.';
        return false;
      }
    } on AppError catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
