import 'dart:convert';
import 'dart:io';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/models/user.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Provider for managing user profile data
/// Handles loading user data, updating personal details, and profile image management
class UserProfileProvider extends BaseProvider {
  UserProfileProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  User? _currentUser;
  User? get currentUser => _currentUser;
  User? get user => _currentUser; // Compatibility alias

  // ─── Convenience Getters ───────────────────────────────────────────────

  /// Get user's full name
  String get fullName {
    if (_currentUser == null) return 'Unknown User';
    return _currentUser!.fullName;
  }

  /// Get user's display name (first name or username)
  String get displayName {
    if (_currentUser == null) return 'Guest';
    return _currentUser!.firstName ?? _currentUser!.username;
  }

  /// Check if user has profile image
  bool get hasProfileImage {
    return _currentUser?.profileImageId != null;
  }

  /// Get user's role/type
  String get userRole {
    return _currentUser?.role ?? 'guest';
  }

  // ─── User Profile Methods ──────────────────────────────────────────────

  /// Load current user profile
  Future<void> loadCurrentUser({bool forceRefresh = false}) async {
    // If not forcing refresh and we already have data, skip
    if (!forceRefresh && _currentUser != null) {
      debugPrint('UserProfileProvider: Using existing user data');
      return;
    }

    final user = await executeWithState(() async {
      debugPrint('UserProfileProvider: Loading current user');
      final response = await api.get('/api/Profile', authenticated: true);

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        debugPrint('UserProfileProvider: Current user loaded successfully');
        return User.fromJson(userData);
      } else {
        throw Exception('Failed to load user data: ${response.statusCode}');
      }
    });

    if (user != null) {
      _currentUser = user;
    }
  }

  /// Load user profile data from API
  Future<void> loadUserProfile() async {
    await loadCurrentUser();
  }

  /// Initialize user (compatibility method)
  Future<void> initUser() async {
    await loadCurrentUser();
  }

  /// Update current user profile
  Future<bool> updateUserProfile(User updatedUser) async {
    final success = await executeWithStateForSuccess(() async {
      debugPrint('UserProfileProvider: Updating user profile');

      final response = await api.put(
        '/users/current',
        updatedUser.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 200) {
        _currentUser = updatedUser;
        debugPrint('UserProfileProvider: User profile updated successfully');
      } else {
        debugPrint('UserProfileProvider: Failed to update user profile');
        throw Exception('Failed to update user profile');
      }
    }, errorMessage: 'Failed to update user profile');

    return success;
  }

  /// Update specific user fields (optimistic updates)
  Future<bool> updateUserField({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
  }) async {
    final success = await executeWithStateForSuccess(() async {
      debugPrint('UserProfileProvider: Updating user fields');

      // Create updated user object with current data + changes
      if (_currentUser == null) {
        throw Exception('No current user to update');
      }

      final updatedUser = _currentUser!.copyWith(
        firstName: firstName ?? _currentUser!.firstName,
        lastName: lastName ?? _currentUser!.lastName,
        email: email ?? _currentUser!.email,
        phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
      );

      final response = await api.put(
        '/users/current',
        updatedUser.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 200) {
        _currentUser = updatedUser;
        debugPrint('UserProfileProvider: User fields updated successfully');
      } else {
        debugPrint('UserProfileProvider: Failed to update user fields');
        throw Exception('Failed to update user fields');
      }
    }, errorMessage: 'Failed to update user fields');

    return success;
  }

  /// Update user's public status
  Future<bool> updateUserPublicStatus(bool isPublic, {String? city}) async {
    final success = await executeWithStateForSuccess(() async {
      debugPrint('UserProfileProvider: Updating user public status to $isPublic');

      if (_currentUser == null) {
        throw Exception('No current user to update');
      }

      // Send minimal payload aligned with backend UserRequest (flattened fields)
      final Map<String, dynamic> payload = {
        'isPublic': isPublic,
      };
      if (isPublic && city != null && city.trim().isNotEmpty) {
        payload['city'] = city.trim();
      }

      final response = await api.put('/users/current', payload, authenticated: true);

      if (response.statusCode == 200) {
        // Refresh to ensure we have latest server-side values
        await loadCurrentUser(forceRefresh: true);
        debugPrint('UserProfileProvider: User public status updated successfully');
      } else {
        debugPrint('UserProfileProvider: Failed to update user public status');
        throw Exception('Failed to update user public status');
      }
    }, errorMessage: 'Failed to update user public status');

    return success;
  }

  /// Ensure City is set on the profile (used when making profile public)
  Future<bool> ensureCityOnProfile(String city) async {
    final trimmed = city.trim();
    if (trimmed.isEmpty) return false;
    return await executeWithStateForSuccess(() async {
      debugPrint('UserProfileProvider: Ensuring city "$trimmed" on profile');
      final response = await api.put('/users/current', {'city': trimmed}, authenticated: true);
      if (response.statusCode == 200) {
        await loadCurrentUser(forceRefresh: true);
      } else {
        throw Exception('Failed to set city on profile');
      }
    }, errorMessage: 'Failed to set city on profile');
  }

  /// Upload profile image
  Future<bool> uploadProfileImage(File imageFile) async {
    final success = await executeWithStateForSuccess(() async {
      debugPrint('UserProfileProvider: Uploading profile image');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${api.baseUrl}/users/current/profile-image'),
      );

      final token = await api.secureStorageService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Content-Type'] = 'multipart/form-data';

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Update user profile with new image data
        await loadCurrentUser(forceRefresh: true);
        debugPrint('UserProfileProvider: Profile image uploaded successfully');
      } else {
        debugPrint('UserProfileProvider: Failed to upload profile image');
        throw Exception('Failed to upload profile image');
      }
    }, errorMessage: 'Failed to upload profile image');

    return success;
  }

  /// Logout - clear all user data
  Future<void> logout() async {
    await executeWithState(() async {
      debugPrint('UserProfileProvider: Logging out user');

      try {
        // Call logout endpoint
        await api.post('/auth/logout', {}, authenticated: true);
      } catch (e) {
        debugPrint('UserProfileProvider: Logout API call failed: $e');
        // Continue with local logout even if API fails
      }

      // Clear all local data
      _currentUser = null;

      debugPrint('UserProfileProvider: User logged out successfully');
    });
  }
}
