import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/models/auth/login_request_model.dart';
import 'package:e_rents_desktop/models/auth/register_request_model.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/services/auth_service.dart';
import 'package:e_rents_desktop/base/app_error.dart';
import 'package:e_rents_desktop/base/lifecycle_mixin.dart';
import 'package:e_rents_desktop/utils/provider_registry.dart';

class AuthProvider extends ChangeNotifier with LifecycleMixin {
  final AuthService _authService;
  User? _currentUser;
  bool _isAuthenticated = false;
  AppError? _error;
  bool _isLoading = false;

  AuthProvider(this._authService) {
    _initializeAuth();
  }

  void _initializeAuth() async {
    if (disposed) return;

    _isLoading = true;
    _error = null;
    safeNotifyListeners();

    try {
      _isAuthenticated = await _authService.isAuthenticated();
      if (_isAuthenticated && !disposed) {
        await _fetchCurrentUserDetails();
        if (_currentUser == null) {
          _isAuthenticated = false;
        }
      }
    } catch (e) {
      if (!disposed) {
        _error = AppError.fromException(e);
        _isAuthenticated = false;
      }
    } finally {
      if (!disposed) {
        _isLoading = false;
        safeNotifyListeners();
      }
    }
  }

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticatedState => _isAuthenticated;
  AppError? get error => _error;
  bool get isLoading => _isLoading;
  String? get errorMessage => _error?.message;

  // Helper methods
  void _setError(String message) {
    if (disposed) return;

    _error = AppError(type: ErrorType.authentication, message: message);
    safeNotifyListeners();
  }

  void _clearError() {
    if (disposed) return;

    _error = null;
    safeNotifyListeners();
  }

  Future<void> _fetchCurrentUserDetails() async {
    if (disposed || !_isAuthenticated) return;

    try {
      final userResponse = await _authService.getMe();

      if (!disposed) {
        if (userResponse.containsKey('user')) {
          _currentUser = User.fromJson(userResponse['user']);
        } else {
          _currentUser = null;
          _isAuthenticated = false;
          _setError(
            'Failed to load user profile. Please try logging in again.',
          );
        }
      }
    } catch (e) {
      if (!disposed) {
        debugPrint('Error fetching user details: $e');
        _currentUser = null;
        _isAuthenticated = false;
        _setError('Failed to load user profile. Please try logging in again.');
      }
    }
  }

  Future<bool> login(LoginRequestModel request) async {
    if (disposed) return false;

    return await executeAsync(() async {
      _isLoading = true;
      _clearError();
      safeNotifyListeners();

      try {
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

        if (!disposed) {
          _isLoading = false;
          safeNotifyListeners();
        }
        return true;
      } catch (e) {
        if (!disposed) {
          _isAuthenticated = false;
          _currentUser = null;
          _error = AppError.fromException(e);
          _isLoading = false;
          safeNotifyListeners();
        }
        return false;
      }
    });
  }

  Future<User?> register(RegisterRequestModel request) async {
    // Registration is not supported in desktop app as it's landlord-only
    // Landlord accounts should be created through proper business processes
    _setError(
      'Account registration is not available in the desktop application. Please contact support for landlord account setup.',
    );
    return null;
  }

  Future<void> logout() async {
    if (disposed) return;

    await executeAsync(() async {
      _isLoading = true;
      _clearError();
      safeNotifyListeners();

      try {
        await _authService.logout();
        if (!disposed) {
          _currentUser = null;
          _isAuthenticated = false;

          // Clear all cached providers on logout to free memory and ensure fresh data on next login
          final registry = ProviderRegistry();
          registry.clear();
        }
      } catch (e) {
        if (!disposed) {
          _error = AppError.fromException(e);
        }
      } finally {
        if (!disposed) {
          _isLoading = false;
          safeNotifyListeners();
        }
      }
    });
  }

  Future<bool> checkAndUpdateAuthStatus() async {
    if (disposed) return false;

    return await executeAsync(() async {
      _isLoading = true;
      _clearError();
      safeNotifyListeners();

      try {
        _isAuthenticated = await _authService.isAuthenticated();
        if (_isAuthenticated && !disposed) {
          await _fetchCurrentUserDetails();
          if (_currentUser == null) {
            _isAuthenticated = false;
          }
        } else if (!disposed) {
          _currentUser = null;
        }

        if (!disposed) {
          _isLoading = false;
          safeNotifyListeners();
        }
        return _isAuthenticated;
      } catch (e) {
        if (!disposed) {
          _error = AppError.fromException(e);
          _isAuthenticated = false;
          _isLoading = false;
          safeNotifyListeners();
        }
        return false;
      }
    });
  }
}
