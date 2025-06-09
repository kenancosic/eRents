import 'package:e_rents_mobile/core/base/base_repository.dart';
import 'package:e_rents_mobile/core/models/user.dart';
import 'package:e_rents_mobile/core/models/tenant_preference_model.dart';
import 'package:e_rents_mobile/core/services/user_service.dart';
import 'package:e_rents_mobile/core/services/cache_manager.dart';
import 'dart:io';

/// Concrete repository for User entities
/// Implements BaseRepository pattern with User-specific logic and local storage integration
class UserRepository extends BaseRepository<User, UserService> {
  UserRepository({
    required UserService service,
    required CacheManager cacheManager,
  }) : super(service: service, cacheManager: cacheManager);

  @override
  String get resourceName => 'users';

  @override
  Duration get cacheTtl =>
      const Duration(hours: 1); // Users cache longer for better UX

  @override
  Future<User?> fetchFromService(String id) async {
    // Handle current user profile
    if (id == 'current' || id == 'profile') {
      return await service.getUserProfile();
    }

    // Handle specific user IDs
    final userId = int.tryParse(id);
    if (userId != null) {
      return await service.getUserById(userId);
    }

    throw ArgumentError('Invalid user ID: $id');
  }

  @override
  Future<List<User>> fetchAllFromService([Map<String, dynamic>? params]) async {
    return await service.searchUsers(params);
  }

  @override
  Future<User> createInService(User item) async {
    // User creation is typically handled by AuthService during registration
    // This repository is more focused on profile management
    throw UnimplementedError('User creation should be handled by AuthService');
  }

  @override
  Future<User> updateInService(String id, User item) async {
    final updatedUser = await service.updateUserProfile(item);
    if (updatedUser == null) {
      throw Exception('Failed to update user profile');
    }
    return updatedUser;
  }

  @override
  Future<bool> deleteInService(String id) async {
    // User deletion is typically a complex operation involving data cleanup
    // For now, we just clear local data
    await service.clearUserData();
    return true;
  }

  @override
  Map<String, dynamic> toJson(User item) {
    return item.toJson();
  }

  @override
  User fromJson(Map<String, dynamic> json) {
    return User.fromJson(json);
  }

  @override
  String getItemId(User item) {
    return item.userId?.toString() ?? 'unknown';
  }

  // User-specific methods that don't fit the standard CRUD pattern

  /// Get current user profile (most common operation)
  Future<User?> getCurrentUserProfile({bool forceRefresh = false}) async {
    return await getById('current', forceRefresh: forceRefresh);
  }

  /// Update current user profile
  Future<User> updateCurrentUserProfile(User updatedUser) async {
    return await update('current', updatedUser);
  }

  /// Upload profile image
  Future<bool> uploadProfileImage(File imageFile) async {
    try {
      final success = await service.uploadProfileImage(imageFile);

      if (success) {
        // Invalidate user cache to force reload of updated profile
        await invalidateCache('current');
      }

      return success;
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Get payment methods for current user
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      // This could be cached separately if needed
      return await service.getPaymentMethods();
    } catch (e) {
      throw Exception('Failed to get payment methods: $e');
    }
  }

  /// Add payment method for current user
  Future<bool> addPaymentMethod(Map<String, dynamic> paymentData) async {
    try {
      return await service.addPaymentMethod(paymentData);
    } catch (e) {
      throw Exception('Failed to add payment method: $e');
    }
  }

  /// Clear all user data (logout)
  Future<void> clearUserData() async {
    await service.clearUserData();
    await clearCache(); // Clear repository cache as well
  }

  /// Get tenant preferences for user
  Future<TenantPreferenceModel?> getTenantPreferences(String userId) async {
    try {
      return await service.getTenantPreferences(userId);
    } catch (e) {
      throw Exception('Failed to get tenant preferences: $e');
    }
  }

  /// Update tenant preferences for user
  Future<bool> updateTenantPreferences(
      TenantPreferenceModel preferences) async {
    try {
      return await service.updateTenantPreferences(preferences);
    } catch (e) {
      throw Exception('Failed to update tenant preferences: $e');
    }
  }

  /// Search users by criteria (for future implementation)
  Future<List<User>> searchUsers({
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    int? userTypeId,
  }) async {
    final searchParams = <String, dynamic>{};

    // Add non-null parameters for backend universal filtering
    if (username != null) searchParams['username'] = username;
    if (email != null) searchParams['email'] = email;
    if (firstName != null) searchParams['firstName'] = firstName;
    if (lastName != null) searchParams['lastName'] = lastName;
    if (userTypeId != null) searchParams['userTypeId'] = userTypeId;

    return await getAll(searchParams);
  }
}
