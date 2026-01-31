import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/auth/register_request_model.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show VoidCallback;

/// AuthProvider built on BaseProvider + BaseProviderMixin
/// - Unifies state: isLoading, isUpdating, hasError, error
/// - Uses ApiServiceExtensions for concise networking
/// - Preserves existing screen method signatures for incremental migration
class AuthProvider extends BaseProvider {
  User? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  Map<String, String> _fieldErrors = <String, String>{};

  // Optional dependency for token persistence; kept generic so existing tests can pass it
  final dynamic storage;

  // Callbacks for chat lifecycle integration
  VoidCallback? onLoginSuccess;
  VoidCallback? onLogoutComplete;

  // Back-compat: allow named parameters as used in tests and providers_config.dart
  AuthProvider({required ApiService apiService, this.storage}) : super(apiService);

  // Public getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => (_accessToken != null && _accessToken!.isNotEmpty);

  // Optional: expose tokens if needed by interceptors (or keep private and use ApiService)
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  Map<String, String> get fieldErrors => _fieldErrors;
  String? getFieldError(String field) => _fieldErrors[field.toLowerCase()];
  void clearFieldError(String field) {
    final removed = _fieldErrors.remove(field.toLowerCase());
    if (removed != null) {
      notifyListeners();
    }
  }

  /// Clear all errors (field errors and general error)
  void clearAllErrors() {
    _fieldErrors.clear();
    clearError();
  }

  // region: Core auth workflows

  /// Login and set auth state. Returns true on success.
  Future<bool> login(String identifier, String password) async {
    debugPrint('[AuthProvider] login() called with identifier: $identifier');
    
    // Clear any previous error
    setUpdating(true);
    
    try {
      // Determine if identifier is email or username to align with backend LoginRequest
      final body = <String, dynamic>{
        'password': password,
      };
      if (identifier.contains('@')) {
        body['email'] = identifier;
        debugPrint('[AuthProvider] Using email login');
      } else {
        body['username'] = identifier;
        debugPrint('[AuthProvider] Using username login');
      }

      debugPrint('[AuthProvider] Sending login request to /Auth/login');
      final httpResp = await api.postJson(
        '/Auth/login',
        body,
        authenticated: false,
      );
      debugPrint('[AuthProvider] Login response status: ${httpResp.statusCode}');

      // Expected response: { accessToken, refreshToken, user: {...} }
      final decoded = jsonDecode(httpResp.body);
      debugPrint('[AuthProvider] Response decoded, has accessToken: ${decoded is Map && decoded.containsKey('accessToken')}');
      
      if (decoded is Map<String, dynamic>) {
        _accessToken = (decoded['accessToken'] as String?) ?? _accessToken;
        _refreshToken = (decoded['refreshToken'] as String?) ?? _refreshToken;
        debugPrint('[AuthProvider] Tokens extracted - accessToken: ${_accessToken != null ? '${_accessToken!.substring(0, 20)}...' : 'null'}');
      }

      // Persist access token for ApiService header usage
      if (_accessToken != null && _accessToken!.isNotEmpty) {
        await api.secureStorageService.storeToken(_accessToken!);
        debugPrint('[AuthProvider] Token stored in secure storage');
      }

      final userMap = (decoded is Map<String, dynamic>) ? decoded['user'] : null;
      if (userMap is Map<String, dynamic>) {
        _currentUser = User.fromJson(userMap);
        debugPrint('[AuthProvider] User parsed: ${_currentUser?.username} (${_currentUser?.email})');
      } else {
        debugPrint('[AuthProvider] No user object in response, will need to fetch separately');
        _currentUser = _currentUser;
      }

      setUpdating(false);
      debugPrint('[AuthProvider] Login successful');
      
      // Trigger chat lifecycle connection
      onLoginSuccess?.call();
      
      return true;
    } catch (e) {
      // Extract actual error message from exception
      String errorMessage = _extractErrorMessage(e);
      debugPrint('[AuthProvider] Login failed: $errorMessage');
      setError(errorMessage);
      return false;
    }
  }
  
  /// Extract a user-friendly error message from an exception
  String _extractErrorMessage(dynamic e) {
    String msg = e.toString();
    
    // Remove 'Exception: ' prefix if present
    if (msg.startsWith('Exception: ')) {
      msg = msg.substring(11);
    }
    
    // Common backend error messages - make them more user-friendly
    if (msg.contains('Invalid username or password') || 
        msg.contains('invalid_credentials') ||
        msg.contains('Invalid credentials')) {
      return 'Invalid username or password. Please try again.';
    }
    if (msg.contains('User not found')) {
      return 'No account found with this email or username.';
    }
    if (msg.contains('401')) {
      return 'Authentication failed. Please check your credentials.';
    }
    if (msg.contains('network') || msg.contains('connection') || msg.contains('SocketException')) {
      return 'Unable to connect to server. Please check your internet connection.';
    }
    if (msg.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    // Return the cleaned message if it's reasonably short
    if (msg.length <= 150) {
      return msg;
    }
    
    // Truncate very long messages
    return '${msg.substring(0, 150)}...';
  }

  /// Register a new user. Returns true on success.
  Future<bool> register(RegisterRequestModel request) async {
    debugPrint('[AuthProvider] register() called for username: ${request.username}, email: ${request.email}');
    // Custom flow to capture server-side field errors for UI mapping
    _fieldErrors = <String, String>{};
    setUpdating(true);
    try {
      debugPrint('[AuthProvider] Sending register request to /Auth/register');
      await api.postJson(
        '/Auth/register',
        request.toJson(),
        authenticated: false,
      );
      // Mark update finished successfully
      setUpdating(false);
      debugPrint('[AuthProvider] Registration successful');
      return true;
    } catch (e) {
      // ApiService aggregates validation errors like "Field: Message; Field2: Message2"
      final msg = e.toString();
      debugPrint('[AuthProvider] Registration failed: $msg');
      _fieldErrors = _parseFieldErrors(msg);
      debugPrint('[AuthProvider] Parsed field errors: $_fieldErrors');
      // Set a concise top-level error for banners
      final summary = _fieldErrors.isNotEmpty
          ? _fieldErrors.values.first
          : (msg.isNotEmpty ? msg : 'Registration failed');
      setError(summary);
      return false;
    }
  }

  Map<String, String> _parseFieldErrors(String message) {
    final Map<String, String> map = <String, String>{};
    // Expected aggregated format: "Field: Message; Field2: Message2"
    for (final part in message.split(';')) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final idx = trimmed.indexOf(':');
      if (idx > 0 && idx < trimmed.length - 1) {
        final field = trimmed.substring(0, idx).trim().toLowerCase();
        final msg = trimmed.substring(idx + 1).trim();
        if (field.isNotEmpty && msg.isNotEmpty) {
          map[field] = msg;
        }
      }
    }
    return map;
  }

  /// Start forgot password flow. Returns true on success.
  Future<bool> forgotPassword(String email) async {
    debugPrint('[AuthProvider] forgotPassword() called for email: $email');
    setUpdating(true);
    try {
      debugPrint('[AuthProvider] Sending forgot-password request');
      await api.postJson(
        '/Auth/forgot-password',
        {'email': email},
        authenticated: false,
      );
      setUpdating(false);
      debugPrint('[AuthProvider] Forgot password request successful');
      return true;
    } catch (e) {
      String errorMessage = _extractErrorMessage(e);
      debugPrint('[AuthProvider] Forgot password failed: $errorMessage');
      setError(errorMessage);
      return false;
    }
  }

  /// Verify reset code for password reset flow. Returns true if code is valid.
  Future<bool> verifyCode(String email, String code) async {
    debugPrint('[AuthProvider] verifyCode() called for email: $email');
    setUpdating(true);
    try {
      debugPrint('[AuthProvider] Sending verify request');
      await api.postJson(
        '/Auth/verify',
        {
          'email': email,
          'code': code,
        },
        authenticated: false,
      );
      setUpdating(false);
      debugPrint('[AuthProvider] Verification successful');
      return true;
    } catch (e) {
      String errorMessage = _extractErrorMessage(e);
      debugPrint('[AuthProvider] Verification failed: $errorMessage');
      setError(errorMessage);
      return false;
    }
  }

  /// Verify email after signup and auto-login. Returns true on success.
  /// This marks the user's email as verified and returns auth tokens.
  Future<bool> verifyEmailAndLogin(String email, String code) async {
    debugPrint('[AuthProvider] verifyEmailAndLogin() called for email: $email');
    setUpdating(true);
    try {
      debugPrint('[AuthProvider] Sending verify-email request');
      final httpResp = await api.postJson(
        '/Auth/verify-email',
        {
          'email': email,
          'code': code,
        },
        authenticated: false,
      );
      
      // Parse auth response and set tokens
      final decoded = jsonDecode(httpResp.body);
      debugPrint('[AuthProvider] verify-email response decoded');
      
      if (decoded is Map<String, dynamic>) {
        _accessToken = (decoded['accessToken'] as String?) ?? _accessToken;
        _refreshToken = (decoded['refreshToken'] as String?) ?? _refreshToken;
        debugPrint('[AuthProvider] Tokens extracted from verify-email response');
      }

      // Persist access token
      if (_accessToken != null && _accessToken!.isNotEmpty) {
        await api.secureStorageService.storeToken(_accessToken!);
        debugPrint('[AuthProvider] Token stored in secure storage');
      }

      // Parse user from response
      final userMap = (decoded is Map<String, dynamic>) ? decoded['user'] : null;
      if (userMap is Map<String, dynamic>) {
        _currentUser = User.fromJson(userMap);
        debugPrint('[AuthProvider] User parsed: ${_currentUser?.username}');
      }

      setUpdating(false);
      debugPrint('[AuthProvider] Email verification and auto-login successful');
      return true;
    } catch (e) {
      String errorMessage = _extractErrorMessage(e);
      debugPrint('[AuthProvider] Email verification failed: $errorMessage');
      setError(errorMessage);
      return false;
    }
  }

  /// Reset or create new password. Returns true on success.
  Future<bool> resetPassword(String email, String code, String newPassword) async {
    debugPrint('[AuthProvider] resetPassword() called for email: $email');
    setUpdating(true);
    try {
      debugPrint('[AuthProvider] Sending reset-password request');
      await api.postJson(
        '/Auth/reset-password',
        {
          'email': email,
          'resetCode': code,
          'newPassword': newPassword,
          'confirmPassword': newPassword,
        },
        authenticated: false,
      );
      setUpdating(false);
      debugPrint('[AuthProvider] Password reset successful');
      return true;
    } catch (e) {
      String errorMessage = _extractErrorMessage(e);
      debugPrint('[AuthProvider] Password reset failed: $errorMessage');
      setError(errorMessage);
      return false;
    }
  }

  /// Logout current session. Returns true on success.
  Future<bool> logout() async {
    debugPrint('[AuthProvider] logout() called');
    
    // Trigger chat lifecycle disconnection before clearing token
    onLogoutComplete?.call();
    
    // No backend logout endpoint currently; just clear local auth state and tokens
    // If a server-side logout is added later (e.g., refresh token revocation), call it here.
    // Clear persisted token so ApiService stops authenticating requests
    await api.secureStorageService.clearToken();
    // Clear local state
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;
    notifyListeners();
    debugPrint('[AuthProvider] Logout complete - tokens cleared');
    return true;
  }

  // endregion

  // region: Backward-compatible shims (if older screens expect these names)
  // The current auth screens already call login/register/forgotPassword/verifyCode/resetPassword
  // and read isLoading/error from provider, which BaseProviderMixin supplies.
  // If you have older method names, add aliases here to avoid breaking changes.
  // endregion
}
