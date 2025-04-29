import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/feature/auth/data/auth_service.dart';

class AuthProvider extends BaseProvider {
  final AuthService _authService;

  AuthProvider(this._authService);

  Future<bool> login(String email, String password) async {
    setState(ViewState.Busy);
    try {
      final success = await _authService.login(email, password);
      if (success) {
        setState(ViewState.Idle);
        return true;
      } else {
        setError('Login failed. Please check your credentials.');
        setState(ViewState.Idle);
        return false;
      }
    } catch (e) {
      setError('An error occurred during login.');
      setState(ViewState.Idle);
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    setState(ViewState.Busy);
    try {
      final success = await _authService.register(userData);
      if (success) {
        setState(ViewState.Idle);
        return true;
      } else {
        setError('Registration failed.');
        setState(ViewState.Idle);
        return false;
      }
    } catch (e) {
      setError('An error occurred during registration.');
      setState(ViewState.Idle);
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    setState(ViewState.Idle);
  }

  Future<bool> forgotPassword(String email) async {
    setState(ViewState.Busy);
    try {
      final success = await _authService.forgotPassword(email);
      if (success) {
        setState(ViewState.Idle);
        return true;
      } else {
        setError('Failed to send password reset email.');
        setState(ViewState.Idle);
        return false;
      }
    } catch (e) {
      setError('An error occurred while sending the password reset email.');
      setState(ViewState.Idle);
      return false;
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    setState(ViewState.Busy);
    try {
      final success = await _authService.resetPassword(token, newPassword);
      if (success) {
        setState(ViewState.Idle);
        return true;
      } else {
        setError('Failed to reset password.');
        setState(ViewState.Idle);
        return false;
      }
    } catch (e) {
      setError('An error occurred during password reset.');
      setState(ViewState.Idle);
      return false;
    }
  }
}
