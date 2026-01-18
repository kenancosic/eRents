import 'dart:convert';

import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ProfileProvider extends BaseProvider {
  ProfileProvider(super.api);

  // ─── State (standardized per playbook) ─────────────────────────────────
  User? _currentUser;
  User? get currentUser => _currentUser;

  bool _isEditing = false;
  bool get isEditing => _isEditing;

  // Password change state (mapped to provider flags where possible)
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
      phoneNumber: phone ?? _currentUser!.phoneNumber,
      address: address ?? _currentUser!.address,
    );
    notifyListeners();
  }

  Future<void> loadUserProfile() async {
    final result = await executeWithState<User>(() async {
      return await api.getAndDecode('/Profile', User.fromJson, authenticated: true);
    });
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
    // Check if email changed
    final emailChanged = _currentUser?.email != user.email;

    final updated = await executeWithRetry<User>(() async {
      return await api.putAndDecode('/Profile', user.toJson(), User.fromJson, authenticated: true);
    }, isUpdate: true);
    if (updated != null) {
      _currentUser = updated;
      toggleEditing();
      notifyListeners();

      if (emailChanged) {
        await logout();
      }
      
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

    // Validate that passwords match before sending request
    if (newPassword != confirmPassword) {
      setError('New passwords do not match');
      _isChangingPassword = false;
      _passwordChangeError = error?.toString();
      notifyListeners();
      return false;
    }

    // Ensure we have current user data
    if (_currentUser == null) {
      setError('User not loaded');
      _isChangingPassword = false;
      _passwordChangeError = error?.toString();
      notifyListeners();
      return false;
    }

    final ok = await executeWithStateForSuccess(() async {
      await api.putJson(
        '/Users/change-password',
        {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
        authenticated: true,
      );
    });

    _isChangingPassword = false;
    if (!ok) {
      // keep provider.error populated by mixin; mirror into local field for legacy readers
      _passwordChangeError = error?.toString();
    }
    notifyListeners();
    return ok;
  }

  /// Uploads a new profile image for the current user
  /// Returns true if successful, false otherwise
  Future<bool> uploadProfileImage(String filePath) async {
    if (_currentUser == null) {
      setError('User not loaded');
      return false;
    }

    try {
      setLoading(true);
      clearError();
      
      // Determine content type from file extension
      final extension = filePath.split('.').last.toLowerCase();
      final contentType = _getImageContentType(extension);
      if (contentType == null) {
        setError('Invalid file type. Allowed: JPEG, PNG, GIF, WebP');
        return false;
      }
      
      // Create multipart file from path with proper content type
      final file = await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: MediaType.parse(contentType),
      );
      
      final response = await api.multipartRequest(
        '/Profile/upload-image',
        'POST',
        files: [file],
        authenticated: true,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        // Backend returns PascalCase 'Success' but ASP.NET Core serializes to camelCase
        if (data['success'] == true || data['Success'] == true || data['imageId'] != null || data['ImageId'] != null) {
          // Reload user profile to get updated profileImageId
          await loadUserProfile();
          return true;
        }
      }
      
      setError('Failed to upload image');
      return false;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Get MIME content type from file extension
  String? _getImageContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  void clearUserProfile() {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await api.secureStorageService.clearToken();
    clearUserProfile();
  }
}
