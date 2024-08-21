import 'base_provider.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';
import '../models/user.dart';

class AuthProvider extends BaseProvider {
  final AuthService _authService;
  final SecureStorageService _secureStorageService;

  User? _user;

  User? get user => _user;

  AuthProvider(
      {required AuthService authService,
      required SecureStorageService secureStorageService})
      : _authService = authService,
        _secureStorageService = secureStorageService;

  Future<bool> login(String email, String password) async {
    setState(ViewState.Busy);
    try {
      _user = await _authService.login(email, password);
      await _secureStorageService.writeToken('auth_token', _user!.token ?? '');
      setState(ViewState.Idle);
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _secureStorageService.clearAll();
    _user = null;
    notifyListeners();
  }

 Future<bool> signUp(String username, String email, String password) async {
    setState(ViewState.Busy);
    try {
      _user = await _authService.register(User(
        username: username,
        email: email,
        password: password,
        // other required fields
      ));
      setState(ViewState.Idle);
      return true;
    } catch (e) {
      setError(e.toString());
      setState(ViewState.Idle);
      return false;
    }
  }


  Future<bool> forgotPassword(String email) async {
    setState(ViewState.Busy);
    try {
      await _authService.forgotPassword(email);
      setState(ViewState.Idle);
      return true;
    } catch (e) {
      setError(e.toString());
      setState(ViewState.Idle);
      return false;
    }
  }


  Future<void> loadUserFromStorage() async {
    String? token = await _secureStorageService.readToken('auth_token');
    if (token != null) {
      _user = await _authService.getUserFromToken(token);
      notifyListeners();
    }
  }
}
