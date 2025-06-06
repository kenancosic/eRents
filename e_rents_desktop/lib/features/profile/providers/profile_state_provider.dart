import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/base/base.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/repositories/profile_repository.dart';
import 'package:e_rents_desktop/services/export_service.dart';

/// State provider for profile management using the new architecture
/// Handles user profile, password changes, PayPal linking, and image uploads
class ProfileStateProvider extends StateProvider<User?> {
  final ProfileRepository _repository;

  // Additional loading states for specific operations
  bool _isUpdatingProfile = false;
  bool _isChangingPassword = false;
  bool _isUploadingImage = false;
  bool _isLinkingPayPal = false;
  bool _isUnlinkingPayPal = false;
  bool _isLoading = false;
  AppError? _error;

  ProfileStateProvider(this._repository) : super(null);

  // Getters for loading states
  bool get isUpdatingProfile => _isUpdatingProfile;
  bool get isChangingPassword => _isChangingPassword;
  bool get isUploadingImage => _isUploadingImage;
  bool get isLinkingPayPal => _isLinkingPayPal;
  bool get isUnlinkingPayPal => _isUnlinkingPayPal;
  bool get isLoading => _isLoading;
  AppError? get error => _error;

  /// Get current user profile
  User? get currentUser => state;

  /// Load user profile data
  Future<void> loadUserProfile({bool forceRefresh = false}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('ProfileStateProvider: Loading user profile...');
      final user = await _repository.getUserProfile(forceRefresh: forceRefresh);
      updateState(user);
      debugPrint('ProfileStateProvider: User profile loaded successfully');
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace);
      debugPrint('ProfileStateProvider: Error loading user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile(User user) async {
    bool success = false;
    _isUpdatingProfile = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('ProfileStateProvider: Updating user profile...');
      final updatedUser = await _repository.updateProfile(user);
      updateState(updatedUser);
      success = true;
      debugPrint('ProfileStateProvider: User profile updated successfully');
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace);
      debugPrint('ProfileStateProvider: Error updating user profile: $e');
    } finally {
      _isUpdatingProfile = false;
      notifyListeners();
    }

    return success;
  }

  /// Change user password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    bool success = false;
    _isChangingPassword = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('ProfileStateProvider: Changing user password...');
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      success = true;
      debugPrint('ProfileStateProvider: Password changed successfully');
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace);
      debugPrint('ProfileStateProvider: Error changing password: $e');
    } finally {
      _isChangingPassword = false;
      notifyListeners();
    }

    return success;
  }

  /// Upload profile image
  Future<bool> uploadProfileImage(String imagePath) async {
    bool success = false;
    _isUploadingImage = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('ProfileStateProvider: Uploading profile image...');
      final updatedUser = await _repository.uploadProfileImage(imagePath);
      updateState(updatedUser);
      success = true;
      debugPrint('ProfileStateProvider: Profile image uploaded successfully');
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace);
      debugPrint('ProfileStateProvider: Error uploading profile image: $e');
    } finally {
      _isUploadingImage = false;
      notifyListeners();
    }

    return success;
  }

  /// Link PayPal account
  Future<bool> linkPayPalAccount(String paypalEmail) async {
    bool success = false;
    _isLinkingPayPal = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('ProfileStateProvider: Linking PayPal account...');
      final updatedUser = await _repository.linkPayPalAccount(paypalEmail);
      updateState(updatedUser);
      success = true;
      debugPrint('ProfileStateProvider: PayPal account linked successfully');
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace);
      debugPrint('ProfileStateProvider: Error linking PayPal account: $e');
    } finally {
      _isLinkingPayPal = false;
      notifyListeners();
    }

    return success;
  }

  /// Unlink PayPal account
  Future<bool> unlinkPayPalAccount() async {
    bool success = false;
    _isUnlinkingPayPal = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('ProfileStateProvider: Unlinking PayPal account...');
      final updatedUser = await _repository.unlinkPayPalAccount();
      updateState(updatedUser);
      success = true;
      debugPrint('ProfileStateProvider: PayPal account unlinked successfully');
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace);
      debugPrint('ProfileStateProvider: Error unlinking PayPal account: $e');
    } finally {
      _isUnlinkingPayPal = false;
      notifyListeners();
    }

    return success;
  }

  /// Export profile data to PDF
  Future<String> exportProfileToPDF() async {
    if (currentUser == null) {
      throw Exception('No user data available for export');
    }

    final exportData = _repository.getProfileExportData(currentUser!);
    return ExportService.exportToPDF(
      title: exportData['title'],
      headers: exportData['headers'],
      rows: exportData['rows'],
    );
  }

  /// Export profile data to Excel
  Future<String> exportProfileToExcel() async {
    if (currentUser == null) {
      throw Exception('No user data available for export');
    }

    final exportData = _repository.getProfileExportData(currentUser!);
    return ExportService.exportToExcel(
      title: exportData['title'],
      headers: exportData['headers'],
      rows: exportData['rows'],
    );
  }

  /// Export profile data to CSV
  Future<String> exportProfileToCSV() async {
    if (currentUser == null) {
      throw Exception('No user data available for export');
    }

    final exportData = _repository.getProfileExportData(currentUser!);
    return ExportService.exportToCSV(
      title: exportData['title'],
      headers: exportData['headers'],
      rows: exportData['rows'],
    );
  }

  /// Refresh profile data (force refresh from server)
  Future<void> refreshProfile() async {
    await loadUserProfile(forceRefresh: true);
    debugPrint('ProfileStateProvider: Profile data refreshed');
  }

  /// Clear cache and reload profile
  Future<void> clearCacheAndRefresh() async {
    await _repository.clearCache();
    await loadUserProfile();
    debugPrint('ProfileStateProvider: Cache cleared and profile refreshed');
  }

  /// Check if user has a complete profile
  bool get hasCompleteProfile {
    if (currentUser == null) return false;

    final user = currentUser!;
    return user.firstName.isNotEmpty &&
        user.lastName.isNotEmpty &&
        user.email.isNotEmpty &&
        user.phone != null &&
        user.phone!.isNotEmpty;
  }

  /// Check if user has profile image
  bool get hasProfileImage {
    return currentUser?.profileImageId != null;
  }

  /// Check if PayPal is linked
  bool get isPayPalLinked {
    return currentUser?.isPaypalLinked ?? false;
  }

  /// Get profile completion percentage
  int get profileCompletionPercentage {
    if (currentUser == null) return 0;

    final user = currentUser!;
    int completedFields = 0;
    int totalFields = 6;

    if (user.firstName.isNotEmpty) completedFields++;
    if (user.lastName.isNotEmpty) completedFields++;
    if (user.email.isNotEmpty) completedFields++;
    if (user.phone != null && user.phone!.isNotEmpty) completedFields++;
    if (user.profileImageId != null) completedFields++;
    if (user.address != null) completedFields++;

    return ((completedFields / totalFields) * 100).round();
  }

  /// Get user's full name
  String get fullName {
    if (currentUser == null) return '';
    return '${currentUser!.firstName} ${currentUser!.lastName}'.trim();
  }

  /// Get user display name (first name or username)
  String get displayName {
    if (currentUser == null) return '';
    return currentUser!.firstName.isNotEmpty
        ? currentUser!.firstName
        : currentUser!.username;
  }

  /// Get formatted member since date
  String get memberSinceFormatted {
    if (currentUser == null) return '';
    final date = currentUser!.createdAt;
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get formatted last updated date
  String get lastUpdatedFormatted {
    if (currentUser == null) return '';
    final date = currentUser!.updatedAt;
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Reset all loading states
  void _resetLoadingStates() {
    _isUpdatingProfile = false;
    _isChangingPassword = false;
    _isUploadingImage = false;
    _isLinkingPayPal = false;
    _isUnlinkingPayPal = false;
    _isLoading = false;
    _error = null;
  }

  @override
  void dispose() {
    _resetLoadingStates();
    super.dispose();
  }
}
