import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/models/auth/change_password_request_model.dart';
import 'package:e_rents_desktop/models/user.dart';

class ProfileProviderRefactored extends BaseProvider {
  ProfileProviderRefactored(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  User? _currentUser;
  User? get currentUser => _currentUser;

  bool _isEditing = false;
  bool get isEditing => _isEditing;

  // ─── Getters for Operation States ───────────────────────────────────────
  bool get isChangingPassword => isLoading;
  String? get passwordChangeError => error;

  bool get isUpdatingProfile => isLoading;
  String? get profileUpdateError => error;

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

  Future<void> loadUserProfile({bool forceRefresh = false}) async {
    const cacheKey = 'user_profile';
    
    if (forceRefresh) {
      invalidateCache(cacheKey);
    }
    
    final result = await executeWithCache<User>(
      cacheKey,
      () => api.getAndDecode('/profile/me', User.fromJson, authenticated: true),
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
      return await api.putAndDecode('/profile/me', user.toJson(), User.fromJson, authenticated: true);
    });
    
    if (result != null) {
      _currentUser = result;
      setCache('user_profile', result);
      toggleEditing();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final request = ChangePasswordRequestModel(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    
    final result = await executeWithState<Map<String, dynamic>>(() async {
      return await api.postJson('/profile/change-password', request.toJson(), authenticated: true);
    });
    
    return result != null;
  }

  Future<bool> uploadProfileImage(String imagePath) async {
    // Note: File upload functionality would need to be implemented in ApiService
    // For now, this is a placeholder that shows the intended structure
    setError('File upload functionality not yet implemented in base provider');
    return false;
  }

  Future<bool> linkPayPalAccount(String paypalEmail) async {
    final result = await executeWithState<User>(() async {
      return await api.postAndDecode('/profile/link-paypal', {'email': paypalEmail}, User.fromJson, authenticated: true);
    });
    
    if (result != null) {
      _currentUser = result;
      setCache('user_profile', result);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> unlinkPayPalAccount() async {
    final result = await executeWithState<User>(() async {
      return await api.postAndDecode('/profile/unlink-paypal', {}, User.fromJson, authenticated: true);
    });
    
    if (result != null) {
      _currentUser = result;
      setCache('user_profile', result);
      notifyListeners();
      return true;
    }
    return false;
  }

  void clearUserProfileCache() {
    invalidateCache('user_profile');
    _currentUser = null;
    notifyListeners();
  }
}
