import 'package:e_rents_mobile/models/user.dart';
import 'package:e_rents_mobile/providers/base_provider.dart';
import 'package:e_rents_mobile/services/auth_service.dart';

class AuthProvider extends BaseProvider<User> {
  User? _user;
  
  User? get user => _user;

  AuthProvider() : super('auth');

  Future<void> login(String email, String password) async {
    setLoadingState(true);
    try {
      _user = await AuthService.login(email, password);
      notifyListeners();
    } catch (e) {
      handleException(e, 'login');
    } finally {
      setLoadingState(false);
    }
  }

  Future<void> register(User user) async {
    setLoadingState(true);
    try {
      _user = await AuthService.register(user);
      notifyListeners();
    } catch (e) {
      handleException(e, 'register');
    } finally {
      setLoadingState(false);
    }
  }

  Future<void> logout() async {
    setLoadingState(true);
    try {
      await AuthService.logout();
      _user = null;
      notifyListeners();
    } catch (e) {
      handleException(e, 'logout');
    } finally {
      setLoadingState(false);
    }
  }

  Future<void> getCurrentUser() async {
    setLoadingState(true);
    try {
      _user = await AuthService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      handleException(e, 'getCurrentUser');
    } finally {
      setLoadingState(false);
    }
  }

  @override
  User fromJson(data) {
    return User.fromJson(data);
  }
}
