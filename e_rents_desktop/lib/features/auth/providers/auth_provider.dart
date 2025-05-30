import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/auth/login_request_model.dart';
import 'package:e_rents_desktop/models/auth/register_request_model.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/auth_service.dart';

class AuthProvider extends BaseProvider<User> {
  AuthService _authService;
  User? _currentUser;
  bool _isAuthenticated = false;

  AuthProvider(ApiService apiService)
    : _authService = AuthService(
        apiService.baseUrl,
        apiService.secureStorageService,
      ),
      super(apiService) {
    _initializeAuth();
  }

  void _initializeAuth() async {
    await execute(() async {
      _isAuthenticated = await _authService.isAuthenticated();
      if (_isAuthenticated) {
        await _fetchCurrentUserDetails();
        if (_currentUser == null) {
          _isAuthenticated = false;
        }
      }
    });
  }

  set authService(AuthService service) {
    _authService = service;
    notifyListeners();
  }

  @override
  String get endpoint => '/users'; // General endpoint for user data if BaseProvider CRUD is used

  @override
  User fromJson(Map<String, dynamic> json) => User.fromJson(json);

  @override
  Map<String, dynamic> toJson(User item) => item.toJson();

  @override
  List<User> getMockItems() => []; // No mock users for auth provider specifically

  User? get currentUser => _currentUser;
  bool get isAuthenticatedState => _isAuthenticated;

  Future<void> _fetchCurrentUserDetails() async {
    if (_isAuthenticated) {
      try {
        final userResponse = await _authService.getMe();
        if (userResponse != null && userResponse['user'] != null) {
          _currentUser = User.fromJson(userResponse['user']);
        } else {
          _currentUser = null;
          _isAuthenticated = false;
          setError('Failed to load user profile. Please try logging in again.');
        }
      } catch (e) {
        print('Error fetching user details: $e');
        _currentUser = null;
        _isAuthenticated = false;
        setError('Failed to load user profile. Please try logging in again.');
      }
    }
  }

  Future<bool> login(LoginRequestModel request) async {
    bool success = false;
    await execute(() async {
      await _authService.login(request);
      _isAuthenticated = true;
      await _fetchCurrentUserDetails();

      // Verify we have a valid landlord user
      if (_currentUser == null || _currentUser!.role != UserType.landlord) {
        _isAuthenticated = false;
        _currentUser = null;
        await _authService.logout(); // Clear any stored data
        throw Exception(
          'Desktop application is for landlords only. Please use the mobile app to access your account.',
        );
      }

      success = true;
    });

    if (!success) {
      _isAuthenticated = false;
      _currentUser = null;
    }
    notifyListeners();
    return success;
  }

  Future<User?> register(RegisterRequestModel request) async {
    // Registration is not supported in desktop app as it's landlord-only
    // Landlord accounts should be created through proper business processes
    setError(
      'Account registration is not available in the desktop application. Please contact support for landlord account setup.',
    );
    return null;
  }

  Future<void> logout() async {
    await execute(() async {
      await _authService.logout();
      _currentUser = null;
      _isAuthenticated = false;
    });
    notifyListeners();
  }

  Future<bool> checkAndUpdateAuthStatus() async {
    await execute(() async {
      _isAuthenticated = await _authService.isAuthenticated();
      if (_isAuthenticated) {
        await _fetchCurrentUserDetails();
        if (_currentUser == null) {
          _isAuthenticated = false;
        }
      } else {
        _currentUser = null;
      }
    });
    notifyListeners();
    return _isAuthenticated;
  }
}
