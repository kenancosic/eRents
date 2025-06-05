import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/base/base.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/auth/change_password_request_model.dart';
import 'package:e_rents_desktop/services/profile_service.dart';

/// Repository for profile data management with intelligent caching
/// Handles user profile, password changes, PayPal linking, and image uploads
class ProfileRepository {
  final ProfileService service;
  final CacheManager cacheManager;

  // Cache TTL configurations
  static const Duration _profileCacheTtl = Duration(minutes: 15);

  ProfileRepository({required this.service, required this.cacheManager});

  /// Load user profile with caching
  /// Returns current user's profile information
  Future<User> getUserProfile({bool forceRefresh = false}) async {
    const cacheKey = 'user_profile';

    if (!forceRefresh) {
      final cached = await cacheManager.get<User>(cacheKey);
      if (cached != null) {
        debugPrint('ProfileRepository: Returning cached user profile');
        return cached;
      }
    }

    try {
      debugPrint('ProfileRepository: Fetching fresh user profile...');
      final user = await service.getMyProfile();

      // Cache the user profile
      await cacheManager.set(cacheKey, user, duration: _profileCacheTtl);
      debugPrint('ProfileRepository: User profile cached successfully');

      return user;
    } catch (e, stackTrace) {
      debugPrint('ProfileRepository: Error loading user profile: $e');
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Update user profile
  /// Updates profile information and invalidates cache
  Future<User> updateProfile(User user) async {
    try {
      debugPrint('ProfileRepository: Updating user profile...');
      final updatedUser = await service.updateMyProfile(user);

      // Update cache with new data
      const cacheKey = 'user_profile';
      await cacheManager.set(cacheKey, updatedUser, duration: _profileCacheTtl);
      debugPrint(
        'ProfileRepository: User profile updated and cached successfully',
      );

      return updatedUser;
    } catch (e, stackTrace) {
      debugPrint('ProfileRepository: Error updating user profile: $e');
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Change user password
  /// Updates password without affecting cached profile data
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      debugPrint('ProfileRepository: Changing user password...');
      final request = ChangePasswordRequestModel(
        oldPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      await service.changePassword(request);
      debugPrint('ProfileRepository: Password changed successfully');
    } catch (e, stackTrace) {
      debugPrint('ProfileRepository: Error changing password: $e');
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Upload profile image
  /// Updates profile image and refreshes cached profile
  Future<User> uploadProfileImage(String imagePath) async {
    try {
      debugPrint('ProfileRepository: Uploading profile image...');
      final updatedUser = await service.uploadProfileImage(imagePath);

      // Update cache with new data
      const cacheKey = 'user_profile';
      await cacheManager.set(cacheKey, updatedUser, duration: _profileCacheTtl);
      debugPrint(
        'ProfileRepository: Profile image uploaded and cached successfully',
      );

      return updatedUser;
    } catch (e, stackTrace) {
      debugPrint('ProfileRepository: Error uploading profile image: $e');
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Link PayPal account
  /// Links PayPal account and updates cached profile
  Future<User> linkPayPalAccount(String paypalEmail) async {
    try {
      debugPrint('ProfileRepository: Linking PayPal account...');
      final updatedUser = await service.linkPaypal(paypalEmail);

      // Update cache with new data
      const cacheKey = 'user_profile';
      await cacheManager.set(cacheKey, updatedUser, duration: _profileCacheTtl);
      debugPrint(
        'ProfileRepository: PayPal account linked and cached successfully',
      );

      return updatedUser;
    } catch (e, stackTrace) {
      debugPrint('ProfileRepository: Error linking PayPal account: $e');
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Unlink PayPal account
  /// Unlinks PayPal account and updates cached profile
  Future<User> unlinkPayPalAccount() async {
    try {
      debugPrint('ProfileRepository: Unlinking PayPal account...');
      final updatedUser = await service.unlinkPaypal();

      // Update cache with new data
      const cacheKey = 'user_profile';
      await cacheManager.set(cacheKey, updatedUser, duration: _profileCacheTtl);
      debugPrint(
        'ProfileRepository: PayPal account unlinked and cached successfully',
      );

      return updatedUser;
    } catch (e, stackTrace) {
      debugPrint('ProfileRepository: Error unlinking PayPal account: $e');
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Clear cached profile data
  /// Useful for logout or when forced refresh is needed
  Future<void> clearCache() async {
    const cacheKey = 'user_profile';
    await cacheManager.remove(cacheKey);
    debugPrint('ProfileRepository: Cache cleared');
  }

  /// Get export data for profile information
  /// Formats profile data for export purposes
  Map<String, dynamic> getProfileExportData(User user) {
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
}
