import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/base/detail_provider.dart';
import 'package:e_rents_mobile/core/repositories/user_repository.dart';
import 'package:e_rents_mobile/core/models/user.dart';
import 'package:e_rents_mobile/core/models/tenant_preference_model.dart';
import 'dart:io';

/// Concrete detail provider for User entities
/// Manages current user profile with automatic caching and error handling
class UserDetailProvider extends DetailProvider<User> {
  UserDetailProvider(UserRepository super.repository);

  // Tenant preferences state
  TenantPreferenceModel? _tenantPreference;

  // Payment methods state
  List<Map<String, dynamic>>? _paymentMethods;

  // Get the user repository with proper typing
  UserRepository get userRepository => repository as UserRepository;

  /// Convenience getter for current user
  User? get currentUser => item;

  /// Getter for tenant preferences (compatibility with legacy UserProvider)
  TenantPreferenceModel? get tenantPreference => _tenantPreference;

  /// Payment methods getter (compatibility with legacy UserProvider)
  List<Map<String, dynamic>>? get paymentMethods => _paymentMethods;

  /// Load current user profile (alias for loadCurrentUserProfile)
  Future<void> loadCurrentUser({bool forceRefresh = false}) async {
    await loadCurrentUserProfile(forceRefresh: forceRefresh);
  }

  /// Initialize user (compatibility with legacy UserProvider)
  Future<void> initUser() async {
    await loadCurrentUserProfile();
    await loadPaymentMethods();
  }

  /// Load current user profile
  Future<void> loadCurrentUserProfile({bool forceRefresh = false}) async {
    await loadItem('current', forceRefresh: forceRefresh);

    // Also load tenant preferences if user is loaded
    if (currentUser != null && currentUser!.userId != null) {
      await loadTenantPreferences(forceRefresh: forceRefresh);
    }
  }

  /// Load payment methods for current user
  Future<void> loadPaymentMethods({bool forceRefresh = false}) async {
    if (!forceRefresh && _paymentMethods != null) return;

    await execute(() async {
      debugPrint('UserDetailProvider: Loading payment methods');

      _paymentMethods = await userRepository.getPaymentMethods();

      debugPrint('UserDetailProvider: Payment methods loaded');
    });
  }

  /// Load tenant preferences for current user
  Future<void> loadTenantPreferences({bool forceRefresh = false}) async {
    if (currentUser?.userId == null) return;

    await execute(() async {
      debugPrint('UserDetailProvider: Loading tenant preferences');

      _tenantPreference = await userRepository
          .getTenantPreferences(currentUser!.userId!.toString());

      debugPrint('UserDetailProvider: Tenant preferences loaded');
    });
  }

  /// Update tenant preferences (compatibility with legacy UserProvider)
  Future<bool> updateTenantPreferences(
      TenantPreferenceModel preferences) async {
    bool success = false;

    await execute(() async {
      debugPrint('UserDetailProvider: Updating tenant preferences');

      success = await userRepository.updateTenantPreferences(preferences);

      if (success) {
        _tenantPreference = preferences;
        debugPrint(
            'UserDetailProvider: Tenant preferences updated successfully');
      }
    });

    return success;
  }

  /// Update current user profile
  Future<void> updateCurrentUserProfile(User updatedUser) async {
    await updateItem(updatedUser);
  }

  /// Update user's public status (compatibility with legacy UserProvider)
  Future<bool> updateUserPublicStatus(bool isPublic) async {
    if (currentUser == null) return false;

    bool success = false;

    await execute(() async {
      debugPrint(
          'UserDetailProvider: Updating user public status to $isPublic');

      final updatedUser = currentUser!.copyWith(isPublic: isPublic);
      await updateItem(updatedUser);
      success = true;

      debugPrint('UserDetailProvider: User public status updated successfully');
    });

    return success;
  }

  /// Upload profile image
  Future<bool> uploadProfileImage(File imageFile) async {
    bool success = false;

    await execute(() async {
      debugPrint('UserDetailProvider: Uploading profile image');

      success = await userRepository.uploadProfileImage(imageFile);

      if (success) {
        // Reload user profile to get updated image
        await loadCurrentUserProfile(forceRefresh: true);
        debugPrint(
            'UserDetailProvider: Profile image uploaded and profile reloaded');
      }
    });

    return success;
  }

  /// Get payment methods for current user
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      return await userRepository.getPaymentMethods();
    } catch (e) {
      debugPrint('UserDetailProvider: Error getting payment methods: $e');
      setError('Failed to load payment methods');
      return [];
    }
  }

  /// Add payment method for current user
  Future<bool> addPaymentMethod(Map<String, dynamic> paymentData) async {
    bool success = false;

    await execute(() async {
      debugPrint('UserDetailProvider: Adding payment method');

      success = await userRepository.addPaymentMethod(paymentData);

      if (success) {
        debugPrint('UserDetailProvider: Payment method added successfully');
      }
    });

    return success;
  }

  /// Logout - clear all user data
  Future<void> logout() async {
    await execute(() async {
      debugPrint('UserDetailProvider: Logging out user');

      await userRepository.clearUserData();
      clearItem(); // Clear from provider state
      _tenantPreference = null; // Clear tenant preferences

      debugPrint('UserDetailProvider: User logged out and data cleared');
    });
  }

  /// Update specific user fields (optimistic updates)
  void updateUserField({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
  }) {
    if (currentUser != null) {
      updateItemProperty((user) => user.copyWith(
            firstName: firstName ?? user.firstName,
            lastName: lastName ?? user.lastName,
            email: email ?? user.email,
            phoneNumber: phoneNumber ?? user.phoneNumber,
          ));
    }
  }

  /// Get user's full name
  String get fullName {
    if (currentUser == null) return 'Unknown User';
    return currentUser!.fullName;
  }

  /// Get user's display name (first name or username)
  String get displayName {
    if (currentUser == null) return 'Guest';
    return currentUser!.firstName ?? currentUser!.username;
  }

  /// Check if user has profile image
  bool get hasProfileImage {
    return currentUser?.profileImageId != null;
  }

  /// Get user's role/type
  String get userRole {
    return currentUser?.role ?? 'guest';
  }

  /// Getter for user (compatibility with legacy UserProvider)
  User? get user => currentUser;

  @override
  void onItemLoaded(User item) {
    debugPrint('UserDetailProvider: User profile loaded - ${item.fullName}');
  }

  @override
  void onItemUpdated(User item) {
    debugPrint('UserDetailProvider: User profile updated - ${item.fullName}');
  }

  @override
  void onItemDeleted(User item) {
    debugPrint('UserDetailProvider: User profile deleted - ${item.fullName}');
  }
}
