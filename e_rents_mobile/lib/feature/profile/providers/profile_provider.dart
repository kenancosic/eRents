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
/// Following the provider-only architecture pattern
class ProfileProvider extends BaseProvider {
  
  ProfileProvider(ApiService api) : super(api);

  // ─── State ──────────────────────────────────────────────────────────────
  // Use inherited loading/error state from BaseProvider
  // isLoading, error, hasError are available

  // User Profile State
  User? _currentUser;
  User? get currentUser => _currentUser;
  User? get user => _currentUser; // Compatibility alias
  
  TenantPreferenceModel? _tenantPreferences;
  TenantPreferenceModel? get tenantPreferences => _tenantPreferences;
  TenantPreferenceModel? get tenantPreference => _tenantPreferences; // Compatibility alias
  

  // Cache TTL for manual cache management
  static const Duration _cacheTTL = Duration(minutes: 5);
  
  // Cache timestamps for manual TTL management
  DateTime? _lastUserLoad;
  DateTime? _lastTenantPreferencesLoad;
  
  /// Check if cache is still valid based on timestamp and TTL
  bool _isCacheValid(DateTime? lastLoad) {
    if (lastLoad == null) return false;
    return DateTime.now().difference(lastLoad) < _cacheTTL;
  }

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
    // Check cache first
    if (!forceRefresh && _currentUser != null && _isCacheValid(_lastUserLoad)) {
      debugPrint('ProfileProvider: Using cached user data');
      return;
    }
    
    await executeWithState(() async {
      debugPrint('ProfileProvider: Loading current user');
      
      final response = await api.get('/users/current', authenticated: true);
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _currentUser = User.fromJson(userData);
        _lastUserLoad = DateTime.now();
        debugPrint('ProfileProvider: Current user loaded successfully');
      }
    });
  }

  /// Initialize user (compatibility method)
  Future<void> initUser() async {
    await loadCurrentUser();
  }

  /// Update current user profile
  Future<bool> updateUserProfile(User updatedUser) async {
    return await executeWithStateForSuccess(() async {
      debugPrint('ProfileProvider: Updating user profile');
      
      final response = await api.put(
        '/users/current', 
        updatedUser.toJson(),
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _currentUser = User.fromJson(userData);
        _lastUserLoad = DateTime.now();
        
        debugPrint('ProfileProvider: User profile updated successfully');
      } else {
        debugPrint('ProfileProvider: Failed to update user profile');
        throw Exception('Failed to update user profile');
      }
    });
  }

  /// Update specific user fields (optimistic updates)
  Future<void> updateUserField({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
  }) async {
    final user = _currentUser;
    if (user == null) return;
    
    // Update locally first (optimistic update)
    _currentUser = user.copyWith(
      firstName: firstName ?? user.firstName,
      lastName: lastName ?? user.lastName,
      email: email ?? user.email,
      phoneNumber: phoneNumber ?? user.phoneNumber,
    );
    notifyListeners();
  }

  /// Update user's public status
  Future<bool> updateUserPublicStatus(bool isPublic) async {
    return await executeWithStateForSuccess(() async {
      debugPrint('ProfileProvider: Updating user public status to $isPublic');
      
      final response = await api.put(
        '/users/current/public-status',
        {'isPublic': isPublic},
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        // Update local user data
        final user = _currentUser;
        if (user != null) {
          _currentUser = user.copyWith(isPublic: isPublic);
        }
        debugPrint('ProfileProvider: User public status updated successfully');
      } else {
        debugPrint('ProfileProvider: Failed to update user public status');
        throw Exception('Failed to update user public status');
      }
    });
  }

  /// Upload profile image
  Future<bool> uploadProfileImage(File imageFile) async {
    return await executeWithStateForSuccess(() async {
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
      } else {
        debugPrint('ProfileProvider: Failed to upload profile image');
        throw Exception('Failed to upload profile image');
      }
    });
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
      _lastUserLoad = null;
      _lastTenantPreferencesLoad = null;
      
      debugPrint('ProfileProvider: User logged out successfully');
    });
  }

  // ─── Tenant Preferences Methods ────────────────────────────────────────
  
  /// Load tenant preferences for current user
  Future<void> loadTenantPreferences({bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh && _tenantPreferences != null && _isCacheValid(_lastTenantPreferencesLoad)) {
      debugPrint('ProfileProvider: Using cached tenant preferences');
      return;
    }
    await executeWithState(() async {
      debugPrint('ProfileProvider: Loading tenant preferences');
      
      final response = await api.get('/users/current/tenant-preferences', authenticated: true);
      
      if (response.statusCode == 200) {
        final preferencesData = jsonDecode(response.body);
        _tenantPreferences = TenantPreferenceModel.fromJson(preferencesData);
        _lastTenantPreferencesLoad = DateTime.now();
        debugPrint('ProfileProvider: Tenant preferences loaded successfully');
      }
    });
  }

  /// Update tenant preferences
  Future<bool> updateTenantPreferences(TenantPreferenceModel preferences) async {
    return await executeWithStateForSuccess(() async {
      debugPrint('ProfileProvider: Updating tenant preferences');
      
      final response = await api.put(
        '/users/current/tenant-preferences',
        preferences.toJson(),
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        _tenantPreferences = preferences;
        _lastTenantPreferencesLoad = DateTime.now();
        debugPrint('ProfileProvider: Tenant preferences updated successfully');
      } else {
        debugPrint('ProfileProvider: Failed to update tenant preferences');
        throw Exception('Failed to update tenant preferences');
      }
    });
  }
}
