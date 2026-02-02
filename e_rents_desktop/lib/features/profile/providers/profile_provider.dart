import 'dart:convert';

import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/features/profile/models/connect_account_status.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';

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

  // Stripe Connect state
  ConnectAccountStatus? _stripeAccountStatus;
  ConnectAccountStatus? get stripeAccountStatus => _stripeAccountStatus;
  bool get isStripeConnected => _stripeAccountStatus?.isActive ?? false;
  bool get hasStripeAccount => _stripeAccountStatus?.accountId != null;
  ConnectAccountState? get stripeAccountState => _stripeAccountStatus?.state;
  bool get isLoadingStripe => _isLoadingStripe;
  bool _isLoadingStripe = false;

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
          'confirmPassword': confirmPassword,
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

  // ─── Stripe Connect Methods ────────────────────────────────────────────────

  /// Load the current Stripe Connect account status
  Future<void> loadStripeAccountStatus() async {
    _isLoadingStripe = true;
    notifyListeners();
    
    await executeWithState(() async {
      final response = await api.get(
        '/payments/stripe/connect/status',
        authenticated: true,
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      _stripeAccountStatus = ConnectAccountStatus.fromJson(data);
      debugPrint('ProfileProvider: Loaded Stripe account status - ${_stripeAccountStatus?.state}');
    }, errorMessage: 'Failed to load Stripe account status');
    
    _isLoadingStripe = false;
    notifyListeners();
  }

  /// Create a Stripe Connect onboarding link
  /// Returns the onboarding URL or null if failed
  Future<String?> createStripeOnboardingLink({
    required String refreshUrl,
    required String returnUrl,
  }) async {
    return await executeWithState<String?>(() async {
      debugPrint('ProfileProvider: Creating Stripe onboarding link');
      final response = await api.post(
        '/payments/stripe/connect/onboard',
        {
          'refreshUrl': refreshUrl,
          'returnUrl': returnUrl,
        },
        authenticated: true,
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      final linkResponse = OnboardingLinkResponse.fromJson(data);

      if (linkResponse.isExpired) {
        throw Exception('Onboarding link has expired. Please try again.');
      }

      debugPrint('ProfileProvider: Stripe onboarding link created successfully');
      return linkResponse.onboardingUrl;
    }, errorMessage: 'Failed to create onboarding link');
  }

  /// Disconnect the Stripe Connect account
  /// Returns true if successful
  Future<bool> disconnectStripeAccount() async {
    final success = await executeWithStateForSuccess(() async {
      debugPrint('ProfileProvider: Disconnecting Stripe account');
      await api.delete(
        '/payments/stripe/connect/disconnect',
        authenticated: true,
      );
      _stripeAccountStatus = null;
      debugPrint('ProfileProvider: Stripe account disconnected successfully');
    });
    return success;
  }

  /// Get Stripe dashboard link
  /// Returns the dashboard URL or null if failed
  Future<String?> getStripeDashboardLink() async {
    return await executeWithState<String?>(() async {
      debugPrint('ProfileProvider: Getting Stripe dashboard link');
      final response = await api.get(
        '/payments/stripe/connect/dashboard',
        authenticated: true,
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      final url = data['url'] as String?;
      debugPrint('ProfileProvider: Stripe dashboard link retrieved');
      return url;
    }, errorMessage: 'Failed to get dashboard link');
  }

  /// Refresh Stripe account status after onboarding completion
  Future<void> refreshStripeAccountAfterOnboarding() async {
    await Future.delayed(const Duration(seconds: 2)); // Small delay for backend sync
    await loadStripeAccountStatus();
  }
}
