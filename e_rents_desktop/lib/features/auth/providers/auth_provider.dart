import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/auth/register_request_model.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'dart:convert';

/// AuthProvider built on BaseProvider + BaseProviderMixin
/// - Unifies state: isLoading, isUpdating, hasError, error
/// - Uses ApiServiceExtensions for concise networking
/// - Preserves existing screen method signatures for incremental migration
class AuthProvider extends BaseProvider {
  User? _currentUser;
  String? _accessToken;
  String? _refreshToken;

  // Optional dependency for token persistence; kept generic so existing tests can pass it
  final dynamic storage;

  // Back-compat: allow named parameters as used in tests and providers_config.dart
  AuthProvider({required ApiService apiService, this.storage}) : super(apiService);

  // Public getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => (_accessToken != null && _accessToken!.isNotEmpty);

  // Optional: expose tokens if needed by interceptors (or keep private and use ApiService)
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  // region: Core auth workflows

  /// Login and set auth state. Returns true on success.
  Future<bool> login(String email, String password) async {
    final result = await executeWithRetry<bool>(() async {
      final httpResp = await api.postJson(
        '/Auth/Login',
        {
          'username': email,
          'password': password,
        },
        authenticated: false,
      );

      // Expected response: { accessToken, refreshToken, user: {...} }
      final decoded = jsonDecode(httpResp.body);
      if (decoded is Map<String, dynamic>) {
        _accessToken = (decoded['accessToken'] as String?) ?? _accessToken;
        _refreshToken = (decoded['refreshToken'] as String?) ?? _refreshToken;
      }

      // Persist access token for ApiService header usage
      if (_accessToken != null && _accessToken!.isNotEmpty) {
        await api.secureStorageService.storeToken(_accessToken!);
      }

      final userMap = (decoded is Map<String, dynamic>) ? decoded['user'] : null;
      if (userMap is Map<String, dynamic>) {
        _currentUser = User.fromJson(userMap);
      } else {
        // If backend returns user separately, you can call me() after login
        _currentUser = _currentUser;
      }

      // Optionally persist tokens here via a TokenService/UserPreferences
      notifyListeners();
      return true;
    }, isUpdate: true);

    return result ?? false;
  }

  /// Register a new user. Returns true on success.
  Future<bool> register(RegisterRequestModel request) async {
    final ok = await executeWithRetry<bool>(() async {
      await api.postJson(
        '/Auth/Register',
        request.toJson(),
        authenticated: false,
      );
      // Usually backend sends verification code via email
      return true;
    }, isUpdate: true);
    return ok ?? false;
  }

  /// Start forgot password flow. Returns true on success.
  Future<bool> forgotPassword(String email) async {
    final ok = await executeWithStateForSuccess(() async {
      await api.postJson(
        'Auth/ForgotPassword',
        {'email': email},
        authenticated: false,
      );
    });
    return ok;
  }

  /// Verify the received code. Returns true on success.
  Future<bool> verifyCode(String email, String code) async {
    final ok = await executeWithStateForSuccess(() async {
      await api.postJson(
        'Auth/verify',
        {
          'email': email,
          'code': code,
        },
        authenticated: false,
      );
    });
    return ok;
  }

  /// Reset or create new password. Returns true on success.
  Future<bool> resetPassword(String email, String code, String newPassword) async {
    final ok = await executeWithRetry<bool>(() async {
      await api.postJson(
        'Auth/ResetPassword',
        {
          'email': email,
          'resetCode': code,
          'newPassword': newPassword,
          'confirmPassword': newPassword,
        },
        authenticated: false,
      );
      return true;
    }, isUpdate: true);
    return ok ?? false;
  }

  /// Logout current session. Returns true on success.
  Future<bool> logout() async {
    // No backend logout endpoint currently; just clear local auth state and tokens
    // If a server-side logout is added later (e.g., refresh token revocation), call it here.
    // Clear persisted token so ApiService stops authenticating requests
    await api.secureStorageService.clearToken();
    // Clear local state
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;
    notifyListeners();
    return true;
  }

  // endregion

  // region: Backward-compatible shims (if older screens expect these names)
  // The current auth screens already call login/register/forgotPassword/verifyCode/resetPassword
  // and read isLoading/error from provider, which BaseProviderMixin supplies.
  // If you have older method names, add aliases here to avoid breaking changes.
  // endregion
}
