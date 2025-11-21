import 'dart:convert';
import 'dart:io';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/models/user.dart';
import 'package:flutter/foundation.dart';

/// Provider for managing user profile data
///
/// This provider handles all user profile related functionality including
/// loading user data, updating personal details, profile image management,
/// and user authentication state.
class UserProfileProvider extends BaseProvider {
  /// Creates a new UserProfileProvider instance
  ///
  /// Requires an ApiService instance for making API calls
  UserProfileProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  
  /// The current user object
  User? _currentUser;
  
  /// Getter for the current user object
  User? get currentUser => _currentUser;
  
  /// Compatibility alias for the current user object
  User? get user => _currentUser; // Compatibility alias

  // ─── Convenience Getters ───────────────────────────────────────────────

  /// Get user's full name
  ///
  /// Returns 'Unknown User' if no user is loaded
  String get fullName {
    if (_currentUser == null) return 'Unknown User';
    return _currentUser!.fullName;
  }

  /// Get user's display name (first name or username)
  ///
  /// Returns 'Guest' if no user is loaded
  String get displayName {
    if (_currentUser == null) return 'Guest';
    return _currentUser!.firstName ?? _currentUser!.username;
  }

  /// Check if user has profile image
  ///
  /// Returns true if the user has a profile image ID set
  bool get hasProfileImage {
    return _currentUser?.profileImageId != null;
  }

  /// Get user's role/type
  ///
  /// Returns 'guest' if no user is loaded
  String get userRole {
    return _currentUser?.role ?? 'guest';
  }

  /// Get the user's profile image URL or a default placeholder
  ///
  /// Builds an absolute URL for the profile image content endpoint when
  /// `profileImageId` is available; otherwise returns the local asset path.
  String get profileImageUrlOrPlaceholder {
    final id = _currentUser?.profileImageId;
    if (id != null && id > 0) {
      return api.makeAbsoluteUrl('/api/Images/$id/content');
    }
    return 'assets/images/user-image.png';
  }

  // ─── User Profile Methods ──────────────────────────────────────────────

  /// Load current user profile
  ///
  /// Loads the current user profile from the API. If [forceRefresh] is false
  /// and user data already exists, it will skip loading.
  ///
  /// Example:
  /// ```dart
  /// await profileProvider.loadCurrentUser();
  /// ```
  Future<void> loadCurrentUser({bool forceRefresh = false}) async {
    // If not forcing refresh and we already have data, skip
    if (!forceRefresh && _currentUser != null) {
      debugPrint('UserProfileProvider: Using existing user data');
      return;
    }

    final user = await executeWithState(() async {
      debugPrint('UserProfileProvider: Loading current user');
      final response = await api.get('/profile', authenticated: true);

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
  ///
  /// This is a compatibility method that calls [loadCurrentUser]
  Future<void> loadUserProfile() async {
    await loadCurrentUser();
  }

  /// Initialize user
  ///
  /// This is a compatibility method that calls [loadCurrentUser]
  Future<void> initUser() async {
    await loadCurrentUser();
  }

  /// Update current user profile
  ///
  /// Updates the current user profile with the provided [updatedUser] object.
  /// Returns true if the update was successful, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// final updatedUser = user.copyWith(firstName: 'John', lastName: 'Doe');
  /// final success = await profileProvider.updateUserProfile(updatedUser);
  /// ```
  Future<bool> updateUserProfile(User updatedUser) async {
    final success = await executeWithStateForSuccess(() async {
      debugPrint('UserProfileProvider: Updating user profile');

      // Build flattened payload matching backend UserRequest
      final Map<String, dynamic> payload = {
        'username': updatedUser.username,
        'email': updatedUser.email,
        'firstName': updatedUser.firstName,
        'lastName': updatedUser.lastName,
        'phoneNumber': updatedUser.phoneNumber,
        'profileImageId': updatedUser.profileImageId,
        'isPublic': updatedUser.isPublic,
        'streetLine1': updatedUser.address?.streetLine1,
        'streetLine2': updatedUser.address?.streetLine2,
        'city': updatedUser.address?.city,
        'state': updatedUser.address?.state,
        'country': updatedUser.address?.country,
        'postalCode': updatedUser.address?.postalCode,
        'latitude': updatedUser.address?.latitude,
        'longitude': updatedUser.address?.longitude,
      };

      final response = await api.put(
        '/profile',
        payload,
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

  /// Update specific user fields
  ///
  /// Updates specific fields of the current user profile. Only the provided
  /// fields will be updated, others will retain their current values.
  /// Returns true if the update was successful, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// final success = await profileProvider.updateUserField(
  ///   firstName: 'John',
  ///   lastName: 'Doe',
  /// );
  /// ```
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

      // Build flattened payload matching backend UserRequest
      final Map<String, dynamic> payload = {
        'username': updatedUser.username,
        'email': updatedUser.email,
        'firstName': updatedUser.firstName,
        'lastName': updatedUser.lastName,
        'phoneNumber': updatedUser.phoneNumber,
        'profileImageId': updatedUser.profileImageId,
        'isPublic': updatedUser.isPublic,
        'streetLine1': updatedUser.address?.streetLine1,
        'streetLine2': updatedUser.address?.streetLine2,
        'city': updatedUser.address?.city,
        'state': updatedUser.address?.state,
        'country': updatedUser.address?.country,
        'postalCode': updatedUser.address?.postalCode,
        'latitude': updatedUser.address?.latitude,
        'longitude': updatedUser.address?.longitude,
      };

      final response = await api.put(
        '/profile',
        payload,
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
  ///
  /// Updates the user's public profile status. If making the profile public
  /// and a [city] is provided, it will also update the user's city.
  /// Returns true if the update was successful, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// final success = await profileProvider.updateUserPublicStatus(true, city: 'New York');
  /// ```
  Future<bool> updateUserPublicStatus(bool isPublic, {String? city}) async {
    final success = await executeWithStateForSuccess(() async {
      debugPrint('UserProfileProvider: Updating user public status to $isPublic');

      if (_currentUser == null) {
        throw Exception('No current user to update');
      }

      // Send payload aligned with backend UserRequest required fields.
      // Backend expects at least username and email to be present.
      final Map<String, dynamic> payload = {
        'username': _currentUser!.username,
        'email': _currentUser!.email,
        'firstName': _currentUser!.firstName,
        'lastName': _currentUser!.lastName,
        'phoneNumber': _currentUser!.phoneNumber,
        'profileImageId': _currentUser!.profileImageId,
        'isPublic': isPublic,
      };
      if (isPublic && city != null && city.trim().isNotEmpty) {
        payload['city'] = city.trim();
      }

      final response = await api.put('/profile', payload, authenticated: true);

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

  /// Ensure City is set on the profile
  ///
  /// Ensures that a city is set on the user's profile when making it public.
  /// Returns true if the update was successful, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// final success = await profileProvider.ensureCityOnProfile('New York');
  /// ```
  Future<bool> ensureCityOnProfile(String city) async {
    final trimmed = city.trim();
    if (trimmed.isEmpty) return false;
    return await executeWithStateForSuccess(() async {
      debugPrint('UserProfileProvider: Ensuring city "$trimmed" on profile');
      if (_currentUser == null) {
        throw Exception('No current user to update');
      }
      final response = await api.put(
        '/profile',
        {
          'username': _currentUser!.username,
          'email': _currentUser!.email,
          'firstName': _currentUser!.firstName,
          'lastName': _currentUser!.lastName,
          'phoneNumber': _currentUser!.phoneNumber,
          'profileImageId': _currentUser!.profileImageId,
          'city': trimmed,
          // keep current public status if any
          'isPublic': _currentUser!.isPublic,
        },
        authenticated: true,
      );
      if (response.statusCode == 200) {
        await loadCurrentUser(forceRefresh: true);
      } else {
        throw Exception('Failed to set city on profile');
      }
    }, errorMessage: 'Failed to set city on profile');
  }

  /// Change password for current user
  ///
  /// Calls PUT /api/users/change-password with { oldPassword, newPassword, confirmPassword }
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return await executeWithStateForSuccess(() async {
      debugPrint('UserProfileProvider: Changing password');
      final response = await api.put(
        '/users/change-password',
        {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
        authenticated: true,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to change password');
      }
    }, errorMessage: 'Failed to change password');
  }

  /// Upload profile image
  ///
  /// Uploads a new profile image for the current user.
  /// Returns true if the upload was successful, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// final imageFile = File('path/to/image.jpg');
  /// final success = await profileProvider.uploadProfileImage(imageFile);
  /// ```
  Future<bool> uploadProfileImage(File imageFile) async {
    final success = await executeWithStateForSuccess(() async {
      debugPrint('UserProfileProvider: Uploading profile image');

      // Ensure current user is loaded (needed for profile update payload)
      if (_currentUser == null) {
        await loadCurrentUser();
      }
      if (_currentUser == null) {
        throw Exception('Unable to load current user for profile update');
      }

      // Prepare image payload for /api/images (JSON with base64-encoded bytes)
      final bytes = await imageFile.readAsBytes();
      final b64 = base64Encode(bytes);
      final filePath = imageFile.path;
      final fileName = filePath.split('/').last.split('\\').last; // handle both separators
      String contentType = 'image/jpeg';
      final lower = fileName.toLowerCase();
      if (lower.endsWith('.png')) contentType = 'image/png';
      if (lower.endsWith('.webp')) contentType = 'image/webp';

      final imgResponse = await api.post(
        '/images',
        {
          'fileName': fileName,
          'contentType': contentType,
          'imageData': b64,
          'isCover': false,
        },
        authenticated: true,
      );

      if (imgResponse.statusCode != 200 && imgResponse.statusCode != 201) {
        debugPrint('UserProfileProvider: Failed to upload image to /images');
        throw Exception('Failed to upload image');
      }

      final imgJson = jsonDecode(imgResponse.body) as Map<String, dynamic>;
      final imageId = imgJson['imageId'] is int
          ? imgJson['imageId']
          : int.tryParse(imgJson['imageId']?.toString() ?? '');
      if (imageId == null) {
        throw Exception('Invalid image response');
      }

      // Now update user profile with new profileImageId via /api/profile
      final updatePayload = {
        'username': _currentUser!.username,
        'email': _currentUser!.email,
        'firstName': _currentUser!.firstName,
        'lastName': _currentUser!.lastName,
        'phoneNumber': _currentUser!.phoneNumber,
        'profileImageId': imageId,
        'isPublic': _currentUser!.isPublic,
        // Preserve address fields (flattened) to avoid data loss
        'streetLine1': _currentUser!.address?.streetLine1,
        'streetLine2': _currentUser!.address?.streetLine2,
        'city': _currentUser!.address?.city,
        'state': _currentUser!.address?.state,
        'country': _currentUser!.address?.country,
        'postalCode': _currentUser!.address?.postalCode,
        'latitude': _currentUser!.address?.latitude,
        'longitude': _currentUser!.address?.longitude,
      };

      final profResp = await api.put('/profile', updatePayload, authenticated: true);
      if (profResp.statusCode == 200) {
        await loadCurrentUser(forceRefresh: true);
        debugPrint('UserProfileProvider: Profile image updated successfully');
      } else {
        debugPrint('UserProfileProvider: Failed to update profile with image');
        throw Exception('Failed to update profile image');
      }
    }, errorMessage: 'Failed to upload profile image');

    return success;
  }

  /// Logout
  ///
  /// Clears all user data and logs the user out of the application.
  /// This method clears the authentication token and resets the user state.
  ///
  /// Example:
  /// ```dart
  /// await profileProvider.logout();
  /// ```
  Future<void> logout() async {
    await executeWithState(() async {
      debugPrint('UserProfileProvider: Logging out user');

      // Clear persisted token so ApiService stops authenticating requests
      await api.secureStorageService.clearToken();
      
      // Clear all local data
      _currentUser = null;

      debugPrint('UserProfileProvider: User logged out successfully');
    });
  }

}
