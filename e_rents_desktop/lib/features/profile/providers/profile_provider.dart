import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/models/user.dart';

class ProfileProvider extends BaseProvider {
  ProfileProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  User? _currentUser;
  User? get currentUser => _currentUser;

  bool _isEditing = false;
  bool get isEditing => _isEditing;

  // Password change state
  bool _isChangingPassword = false;
  bool get isChangingPassword => _isChangingPassword;

  String? _passwordChangeError;
  String? get passwordChangeError => _passwordChangeError;

  // ─── Public API ─────────────────────────────────────────────────────────

  void toggleEditing() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  void updateLocalUser({
    String? firstName,
    String? lastName,
    String? phone,
    Address? address,
  }) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      firstName: firstName ?? _currentUser!.firstName,
      lastName: lastName ?? _currentUser!.lastName,
      phone: phone ?? _currentUser!.phone,
      address: address ?? _currentUser!.address,
    );
    notifyListeners();
  }

  Future<void> loadUserProfile() async {
    final result = await executeWithState(
      () => api.getAndDecode('/api/Profile/me', User.fromJson, authenticated: true),
    );
    
    if (result != null) {
      _currentUser = result;
      notifyListeners();
    }
  }

  Future<bool> saveChanges() async {
    if (_currentUser == null) {
      setError('No user data to save.');
      return false;
    }
    return await updateProfile(_currentUser!);
  }

  Future<bool> updateProfile(User user) async {
    final result = await executeWithState<User>(() async {
      return await api.putAndDecode('/api/Profile/me', user.toJson(), User.fromJson, authenticated: true);
    });
    
    if (result != null) {
      _currentUser = result;
      // setCache('user_profile', result); // BaseProvider handles caching
      toggleEditing();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isChangingPassword = true;
    _passwordChangeError = null;
    notifyListeners();

    try {
      final result = await executeWithState<bool>(() async {
        final response = await api.post(
          '/api/Profile/change-password',
          {
            'oldPassword': oldPassword,
            'newPassword': newPassword,
            'confirmPassword': confirmPassword,
          },
          authenticated: true,
        );

        return response.statusCode == 200;
      });

      _isChangingPassword = false;
      notifyListeners();
      return result ?? false;
    } catch (e) {
      _isChangingPassword = false;
      _passwordChangeError = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearUserProfile() {
    _currentUser = null;
    notifyListeners();
  }
}
