import 'package:flutter/material.dart';
import 'package:e_rents_mobile/models/user.dart';
import 'package:e_rents_mobile/services/auth_service.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;

  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final user = await AuthService.login(email, password);
      _setUser(user);
    } catch (e) {
      _setErrorMessage(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(User user) async {
    _setLoading(true);
    try {
      final registeredUser = await AuthService.register(user);
      _setUser(registeredUser);
    } catch (e) {
      _setErrorMessage(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUser(User updatedUser) async {
    _setLoading(true);
    try {
      final user = await AuthService.updateUser(updatedUser);
      _setUser(user);
    } catch (e) {
      _setErrorMessage(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setUser(null);
    // Clear any additional session data
  }
}
