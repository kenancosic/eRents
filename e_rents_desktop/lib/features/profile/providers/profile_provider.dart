import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/auth/change_password_request_model.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:http/http.dart' as http;

/// Profile provider following the new provider-only architecture
/// Handles user profile management, password changes, PayPal linking, and image uploads
class ProfileProvider extends ChangeNotifier {
  final ApiService _api;

  ProfileProvider(this._api);

  // ─── State ──────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _isChangingPassword = false;
  bool get isChangingPassword => _isChangingPassword;

  String? _passwordChangeError;
  String? get passwordChangeError => _passwordChangeError;

  bool _isUpdatingProfile = false;
  bool get isUpdatingProfile => _isUpdatingProfile;

  String? _profileUpdateError;
  String? get profileUpdateError => _profileUpdateError;

  bool _isEditing = false;
  bool get isEditing => _isEditing;

  void toggleEditing() {
    _isEditing = !_isEditing;
    if (!_isEditing) {
      // Reset any pending changes if user cancels
      // This might need more sophisticated logic depending on requirements
    }
    notifyListeners();
  }

  /// Updates the local user model without saving to the backend.
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

  /// Saves the updated user profile to the backend.
  Future<bool> saveChanges() async {
    if (_currentUser == null) {
      _profileUpdateError = 'No user data to save.';
      notifyListeners();
      return false;
    }

    final success = await updateProfile(_currentUser!);
    if (success) {
      toggleEditing(); // Exit editing mode on successful save
    }
    return success;
  }

  User? _currentUser;
  User? get currentUser => _currentUser;

  // Cache management
  DateTime? _lastProfileFetch;
  static const Duration _profileCacheTtl = Duration(minutes: 15);

  // ─── Public API ─────────────────────────────────────────────────────────

  /// Load user profile with caching
  Future<void> loadUserProfile({bool forceRefresh = false}) async {
    // Check if we should use cached data
    if (!forceRefresh && 
        _currentUser != null && 
        _lastProfileFetch != null &&
        DateTime.now().difference(_lastProfileFetch!) < _profileCacheTtl) {
      debugPrint('ProfileProvider: Using cached user profile');
      return;
    }

    if (_isLoading) return;

    try {
      _setLoading(true);
      _setError(null);

      debugPrint('ProfileProvider: Fetching fresh user profile...');
      final response = await _api.get('/profile/me', authenticated: true);
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final user = User.fromJson(jsonResponse);

      _currentUser = user;
      _lastProfileFetch = DateTime.now();
      debugPrint('ProfileProvider: User profile loaded and cached successfully');
    } catch (e) {
      debugPrint('ProfileProvider: Error loading user profile: $e');
      _setError('Failed to load user profile: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<bool> updateProfile(User user) async {
    if (_isUpdatingProfile) return false;

    try {
      _isUpdatingProfile = true;
      _profileUpdateError = null;
      notifyListeners();

      debugPrint('ProfileProvider: Updating user profile...');
      
      // Create UserUpdateRequest format expected by backend
      final updateData = {
        'firstName': user.firstName,
        'lastName': user.lastName,
        'phoneNumber': user.phone,
        'address': user.address?.toJson(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final response = await _api.put('/profile/me', updateData, authenticated: true);
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final updatedUser = User.fromJson(jsonResponse);

      _currentUser = updatedUser;
      _lastProfileFetch = DateTime.now();
      debugPrint('ProfileProvider: User profile updated successfully');
      return true;
    } catch (e) {
      debugPrint('ProfileProvider: Error updating user profile: $e');
      _profileUpdateError = 'Failed to update user profile: ${e.toString()}';
      return false;
    } finally {
      _isUpdatingProfile = false;
      notifyListeners();
    }
  }

  /// Change user password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (_isChangingPassword) return false;

    try {
      _isChangingPassword = true;
      _passwordChangeError = null;
      notifyListeners();

      debugPrint('ProfileProvider: Changing user password...');
      final request = ChangePasswordRequestModel(
        oldPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      await _api.post('/profile/change-password', request.toJson(), authenticated: true);
      debugPrint('ProfileProvider: Password changed successfully');
      return true;
    } catch (e) {
      debugPrint('ProfileProvider: Error changing password: $e');
      _passwordChangeError = 'Failed to change password: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isChangingPassword = false;
      notifyListeners();
    }
  }

  /// Upload profile image
  Future<bool> uploadProfileImage(String imagePath) async {
    if (_isLoading) return false;

    try {
      _setLoading(true);
      _setError(null);

      debugPrint('ProfileProvider: Uploading profile image...');
      
      final uri = Uri.parse('${_api.baseUrl}/profile/upload-profile-image');
      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      final token = await _api.secureStorageService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add platform header
      request.headers['Client-Type'] = 'Desktop';

      // Add the image file
      final file = await http.MultipartFile.fromPath('image', imagePath);
      request.files.add(file);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final updatedUser = User.fromJson(jsonResponse);

        _currentUser = updatedUser;
        _lastProfileFetch = DateTime.now();
        debugPrint('ProfileProvider: Profile image uploaded successfully');
        return true;
      } else {
        throw Exception('Upload failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('ProfileProvider: Error uploading profile image: $e');
      _setError('Failed to upload profile image: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Link PayPal account
  Future<bool> linkPayPalAccount(String paypalEmail) async {
    if (_isLoading) return false;

    try {
      _setLoading(true);
      _setError(null);

      debugPrint('ProfileProvider: Linking PayPal account...');
      final response = await _api.post('/profile/link-paypal', {
        'email': paypalEmail,
      }, authenticated: true);

      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final updatedUser = User.fromJson(jsonResponse);

      _currentUser = updatedUser;
      _lastProfileFetch = DateTime.now();
      debugPrint('ProfileProvider: PayPal account linked successfully');
      return true;
    } catch (e) {
      debugPrint('ProfileProvider: Error linking PayPal account: $e');
      _setError('Failed to link PayPal account: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Unlink PayPal account
  Future<bool> unlinkPayPalAccount() async {
    if (_isLoading) return false;

    try {
      _setLoading(true);
      _setError(null);

      debugPrint('ProfileProvider: Unlinking PayPal account...');
      final response = await _api.post('/profile/unlink-paypal', {}, authenticated: true);

      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final updatedUser = User.fromJson(jsonResponse);

      _currentUser = updatedUser;
      _lastProfileFetch = DateTime.now();
      debugPrint('ProfileProvider: PayPal account unlinked successfully');
      return true;
    } catch (e) {
      debugPrint('ProfileProvider: Error unlinking PayPal account: $e');
      _setError('Failed to unlink PayPal account: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Clear cached profile data
  void clearCache() {
    _currentUser = null;
    _lastProfileFetch = null;
    debugPrint('ProfileProvider: Cache cleared');
    notifyListeners();
  }

  /// Get export data for profile information
  Map<String, dynamic> getProfileExportData() {
    if (_currentUser == null) {
      return {'title': 'No Profile Data', 'headers': [], 'rows': []};
    }

    final user = _currentUser!;
    final title = 'User Profile - ${user.firstName} ${user.lastName}';
    final headers = ['Field', 'Value'];

    final rows = [
      ['First Name', user.firstName],
      ['Last Name', user.lastName],
      ['Email', user.email],
      ['Phone', user.phone ?? 'Not provided'],
      ['Username', user.username],
      ['PayPal Status', user.isPaypalLinked ? 'Linked' : 'Not Linked'],
      if (user.isPaypalLinked && user.paypalUserIdentifier != null)
        ['PayPal Email', user.paypalUserIdentifier!],
      ['Member Since', user.createdAt.toString().split(' ')[0]],
      ['Last Updated', user.updatedAt.toString().split(' ')[0]],
      if (user.address != null) ...[
        ['Address', user.address!.streetLine1 ?? 'Not provided'],
        ['City', user.address!.city ?? 'Not provided'],
        ['State', user.address!.state ?? 'Not provided'],
        ['Country', user.address!.country ?? 'Not provided'],
        ['Postal Code', user.address!.postalCode ?? 'Not provided'],
      ],
    ];

    return {'title': title, 'headers': headers, 'rows': rows};
  }

  /// Update user state (called by form widgets when they successfully update profile)
  void updateUserState(User updatedUser) {
    _currentUser = updatedUser;
    _lastProfileFetch = DateTime.now();
    notifyListeners();
  }

  // ─── Private Helpers ────────────────────────────────────────────────────

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}
