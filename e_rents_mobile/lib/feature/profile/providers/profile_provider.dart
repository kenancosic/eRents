import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/models/user.dart';
import 'package:e_rents_mobile/core/models/tenant_preference_model.dart';

/// Consolidated provider for all Profile feature functionality
/// Manages user profile, bookings, tenant preferences, and payment methods
/// Following the provider-only architecture pattern with proper caching
class ProfileProvider extends BaseProvider {
  
  ProfileProvider(ApiService api) : super(api);

  // ─── State ──────────────────────────────────────────────────────────────
  User? _currentUser;
  User? get currentUser => _currentUser;
  User? get user => _currentUser; // Compatibility alias
  
  TenantPreferenceModel? _tenantPreferences;
  TenantPreferenceModel? get tenantPreferences => _tenantPreferences;
  TenantPreferenceModel? get tenantPreference => _tenantPreferences; // Compatibility alias

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
  
  /// Load current user profile with caching
  Future<void> loadCurrentUser({bool forceRefresh = false}) async {
    if (!forceRefresh && _currentUser != null) {
      debugPrint('ProfileProvider: Using cached user data');
      return;
    }
    
    await executeWithCacheAndMessage(
      'current_user',
      () async {
        debugPrint('ProfileProvider: Loading current user');
        final response = await api.get('/users/current', authenticated: true);
        
        if (response.statusCode == 200) {
          final userData = jsonDecode(response.body);
          _currentUser = User.fromJson(userData);
          debugPrint('ProfileProvider: Current user loaded successfully');
          return _currentUser;
        } else {
          throw Exception('Failed to load user data: ${response.statusCode}');
        }
      },
      'Failed to load user profile',
      cacheTtl: const Duration(minutes: 5),
    );
  }

  /// Initialize user (compatibility method)
  Future<void> initUser() async {
    await loadCurrentUser();
  }

  /// Update current user profile
  Future<bool> updateUserProfile(User updatedUser) async {
    bool success = false;
    await executeWithState(() async {
      debugPrint('ProfileProvider: Updating user profile');
      
      final response = await api.put(
        '/users/current', 
        updatedUser.toJson(),
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        _currentUser = updatedUser;
        // Invalidate cache to force refresh on next load
        invalidateCache('current_user');
        debugPrint('ProfileProvider: User profile updated successfully');
        success = true;
      } else {
        debugPrint('ProfileProvider: Failed to update user profile');
        throw Exception('Failed to update user profile');
      }
    });
    return success;
  }

  /// Update specific user fields (optimistic updates)
  Future<bool> updateUserField({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
  }) async {
    bool success = false;
    await executeWithState(() async {
      debugPrint('ProfileProvider: Updating user fields');
      
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
        // Invalidate cache to force refresh on next load
        invalidateCache('current_user');
        debugPrint('ProfileProvider: User fields updated successfully');
        success = true;
      } else {
        debugPrint('ProfileProvider: Failed to update user fields');
        throw Exception('Failed to update user fields');
      }
    });
    return success;
  }

  /// Update user's public status
  Future<bool> updateUserPublicStatus(bool isPublic) async {
    bool success = false;
    await executeWithState(() async {
      debugPrint('ProfileProvider: Updating user public status to $isPublic');
      
      if (_currentUser == null) {
        throw Exception('No current user to update');
      }
      
      final updatedUser = _currentUser!.copyWith(isPublic: isPublic);
      
      final response = await api.put(
        '/users/current',
        updatedUser.toJson(),
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        _currentUser = updatedUser;
        // Invalidate cache to force refresh on next load
        invalidateCache('current_user');
        debugPrint('ProfileProvider: User public status updated successfully');
        success = true;
      } else {
        debugPrint('ProfileProvider: Failed to update user public status');
        throw Exception('Failed to update user public status');
      }
    });
    return success;
  }

  /// Upload profile image
  Future<bool> uploadProfileImage(File imageFile) async {
    bool success = false;
    await executeWithState(() async {
      debugPrint('ProfileProvider: Uploading profile image');
      
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
        debugPrint('ProfileProvider: Profile image uploaded successfully');
        success = true;
      } else {
        debugPrint('ProfileProvider: Failed to upload profile image');
        throw Exception('Failed to upload profile image');
      }
    });
    return success;
  }

  /// Logout - clear all user data
  Future<void> logout() async {
    await executeWithState(() async {
      debugPrint('ProfileProvider: Logging out user');
      
      try {
        // Call logout endpoint
        await api.post('/auth/logout', {}, authenticated: true);
      } catch (e) {
        debugPrint('ProfileProvider: Logout API call failed: $e');
        // Continue with local logout even if API fails
      }
      
      // Clear all local data
      _currentUser = null;
      _tenantPreferences = null;
      
      // Clear all cache
      invalidateCache();
      
      debugPrint('ProfileProvider: User logged out successfully');
    });
  }

  // ─── Tenant Preferences Methods ────────────────────────────────────────
  
  /// Load tenant preferences for current user with caching
  Future<void> loadTenantPreferences({bool forceRefresh = false}) async {
    if (!forceRefresh && _tenantPreferences != null) {
      debugPrint('ProfileProvider: Using cached tenant preferences');
      return;
    }
    
    await executeWithCacheAndMessage(
      'tenant_preferences',
      () async {
        debugPrint('ProfileProvider: Loading tenant preferences');
        final response = await api.get('/users/current/tenant-preferences', authenticated: true);
        
        if (response.statusCode == 200) {
          final preferencesData = jsonDecode(response.body);
          _tenantPreferences = TenantPreferenceModel.fromJson(preferencesData);
          debugPrint('ProfileProvider: Tenant preferences loaded successfully');
          return _tenantPreferences;
        } else {
          throw Exception('Failed to load tenant preferences: ${response.statusCode}');
        }
      },
      'Failed to load tenant preferences',
      cacheTtl: const Duration(minutes: 5),
    );
  }

  /// Update tenant preferences
  Future<bool> updateTenantPreferences(TenantPreferenceModel preferences) async {
    bool success = false;
    await executeWithState(() async {
      debugPrint('ProfileProvider: Updating tenant preferences');
      
      final response = await api.put(
        '/users/current/tenant-preferences',
        preferences.toJson(),
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        _tenantPreferences = preferences;
        // Invalidate cache to force refresh on next load
        invalidateCache('tenant_preferences');
        debugPrint('ProfileProvider: Tenant preferences updated successfully');
        success = true;
      } else {
        debugPrint('ProfileProvider: Failed to update tenant preferences');
        throw Exception('Failed to update tenant preferences');
      }
    });
    return success;
  }

  // ─── Payment Methods ───────────────────────────────────────────────────
  
  /// Add a new payment method
  Future<bool> addPaymentMethod(Map<String, dynamic> paymentData) async {
    bool success = false;
    await executeWithState(() async {
      debugPrint('ProfileProvider: Adding payment method');
      
      final response = await api.post(
        '/users/current/payment-methods',
        paymentData,
        authenticated: true,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh user data to get updated payment methods
        await loadCurrentUser(forceRefresh: true);
        debugPrint('ProfileProvider: Payment method added successfully');
        success = true;
      } else {
        debugPrint('ProfileProvider: Failed to add payment method');
        throw Exception('Failed to add payment method');
      }
    });
    return success;
  }

  /// Update an existing payment method
  Future<bool> updatePaymentMethod(String methodId, Map<String, dynamic> paymentData) async {
    bool success = false;
    await executeWithState(() async {
      debugPrint('ProfileProvider: Updating payment method $methodId');
      
      final response = await api.put(
        '/users/current/payment-methods/$methodId',
        paymentData,
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        // Refresh user data to get updated payment methods
        await loadCurrentUser(forceRefresh: true);
        debugPrint('ProfileProvider: Payment method updated successfully');
        success = true;
      } else {
        debugPrint('ProfileProvider: Failed to update payment method');
        throw Exception('Failed to update payment method');
      }
    });
    return success;
  }

  /// Delete a payment method
  Future<bool> deletePaymentMethod(String methodId) async {
    bool success = false;
    await executeWithState(() async {
      debugPrint('ProfileProvider: Deleting payment method $methodId');
      
      final response = await api.delete(
        '/users/current/payment-methods/$methodId',
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        // Refresh user data to get updated payment methods
        await loadCurrentUser(forceRefresh: true);
        debugPrint('ProfileProvider: Payment method deleted successfully');
        success = true;
      } else {
        debugPrint('ProfileProvider: Failed to delete payment method');
        throw Exception('Failed to delete payment method');
      }
    });
    return success;
  }

  // ─── Booking Methods ───────────────────────────────────────────────────
  
  /// Load user's booking history with caching
  Future<List<dynamic>?> loadBookingHistory({bool forceRefresh = false}) async {
    // Check if we have cached data
    final cachedData = getCache<List<dynamic>>('booking_history');
    if (!forceRefresh && cachedData != null && isCacheValid('booking_history')) {
      debugPrint('ProfileProvider: Using cached booking history data');
      return cachedData;
    }
    
    List<dynamic>? bookings;
    await executeWithState(() async {
      debugPrint('ProfileProvider: Loading booking history');
      
      final response = await api.get('/users/current/bookings', authenticated: true);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        bookings = data['bookings'] as List<dynamic>;
        // Cache the booking history
        setCache('booking_history', bookings, const Duration(minutes: 5));
        debugPrint('ProfileProvider: Booking history loaded successfully');
      } else {
        debugPrint('ProfileProvider: Failed to load booking history');
        throw Exception('Failed to load booking history: ${response.statusCode}');
      }
    });
    
    return bookings;
  }

  /// Get upcoming bookings
  Future<List<dynamic>?> getUpcomingBookings({bool forceRefresh = false}) async {
    final allBookings = await loadBookingHistory(forceRefresh: forceRefresh);
    if (allBookings == null) return null;
    
    // Filter for upcoming bookings (status: confirmed, pending)
    return allBookings.where((booking) {
      final status = booking['status'] as String;
      return status == 'Confirmed' || status == 'Pending';
    }).toList();
  }

  /// Get completed bookings
  Future<List<dynamic>?> getCompletedBookings({bool forceRefresh = false}) async {
    final allBookings = await loadBookingHistory(forceRefresh: forceRefresh);
    if (allBookings == null) return null;
    
    // Filter for completed bookings (status: completed)
    return allBookings.where((booking) {
      return booking['status'] == 'Completed';
    }).toList();
  }

  /// Get cancelled bookings
  Future<List<dynamic>?> getCancelledBookings({bool forceRefresh = false}) async {
    final allBookings = await loadBookingHistory(forceRefresh: forceRefresh);
    if (allBookings == null) return null;
    
    // Filter for cancelled bookings (status: cancelled)
    return allBookings.where((booking) {
      return booking['status'] == 'Cancelled';
    }).toList();
  }

  /// Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    bool success = false;
    await executeWithState(() async {
      debugPrint('ProfileProvider: Cancelling booking $bookingId');
      
      final response = await api.post(
        '/bookings/$bookingId/cancel',
        {},
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        // Invalidate booking history cache to force refresh
        invalidateCache('booking_history');
        debugPrint('ProfileProvider: Booking cancelled successfully');
        success = true;
      } else {
        debugPrint('ProfileProvider: Failed to cancel booking');
        throw Exception('Failed to cancel booking');
      }
    });
    return success;
  }
}
