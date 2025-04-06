import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';
import 'package:e_rents_desktop/services/auth_service.dart';
import 'package:e_rents_desktop/utils/error_handler.dart';

class AuthProvider extends BaseProvider<User> {
  AuthService _authService;
  static User? _devCurrentUser; // Static user for development
  String? _error;

  AuthProvider(ApiService apiService)
    : _authService = AuthService(
        apiService.baseUrl,
        apiService.secureStorageService,
      ),
      super(apiService) {
    // Initialize authentication state
    _initializeAuth();
  }

  void _initializeAuth() async {
    try {
      final isAuth = await isAuthenticated();
      if (isAuth && AuthService.isDevelopmentMode) {
        _devCurrentUser ??= MockDataService.getMockUsers().first;
      }
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
    }
  }

  set authService(AuthService service) => _authService = service;

  @override
  String get endpoint => '/auth';

  @override
  User fromJson(Map<String, dynamic> json) => User.fromJson(json);

  @override
  Map<String, dynamic> toJson(User item) => item.toJson();

  @override
  List<User> getMockItems() => MockDataService.getMockUsers();

  User? get currentUser =>
      AuthService.isDevelopmentMode ? _devCurrentUser : null;
  String? get error => _error;

  Future<bool> login(String email, String password) async {
    try {
      _error = null;
      final result = await _authService.login(email, password);
      if (result['token'] != null) {
        if (AuthService.isDevelopmentMode) {
          _devCurrentUser = User.fromJson(result['user']);
        }
        notifyListeners();
        return true;
      }
      _error = 'Invalid email or password';
      return false;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      return false;
    }
  }

  Future<bool> register(User user) async {
    try {
      _error = null;
      final success = await _authService.register(user.toJson());
      if (success) {
        if (AuthService.isDevelopmentMode) {
          _devCurrentUser = user;
        }
        notifyListeners();
      } else {
        _error = 'Registration failed';
      }
      return success;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      _error = null;
      await _authService.logout();
      if (AuthService.isDevelopmentMode) {
        _devCurrentUser = null;
      }
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      _error = null;
      return await _authService.isAuthenticated();
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      return false;
    }
  }

  // Alias for items to maintain backward compatibility
  List<User> get users => items;
}
