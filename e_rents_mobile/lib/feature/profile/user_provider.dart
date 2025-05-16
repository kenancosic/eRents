import 'dart:io';

import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/models/tenant_preference_model.dart';
import 'package:e_rents_mobile/core/models/user.dart';
import 'package:e_rents_mobile/feature/profile/data/user_service.dart';

class UserProvider extends BaseProvider {
  final UserService _userService;
  User? _user;
  TenantPreferenceModel? _tenantPreference;
  List<Map<String, dynamic>>? _paymentMethods;

  UserProvider(this._userService);

  User? get user => _user;
  TenantPreferenceModel? get tenantPreference => _tenantPreference;
  List<Map<String, dynamic>>? get paymentMethods => _paymentMethods;

  // Initialize user data and preferences
  Future<void> initUser() async {
    setState(ViewState.busy);
    try {
      _user = await _userService.getUserProfile();
      if (_user != null) {
        // Assuming userId is String, adjust if it's int
        _tenantPreference =
            await _userService.getTenantPreferences(_user!.userId!.toString());
      }
      await fetchPaymentMethods();
      setState(ViewState.idle);
    } catch (e) {
      setError('Failed to initialize user or preferences: ${e.toString()}');
    }
  }

  // Update user profile
  Future<bool> updateProfile(User updatedUser) async {
    setState(ViewState.busy);
    try {
      final result = await _userService.updateUserProfile(updatedUser);
      if (result != null) {
        _user = result;
        setState(ViewState.idle);
        return true;
      } else {
        setError('Failed to update profile');
        return false;
      }
    } catch (e) {
      setError('Error updating profile: ${e.toString()}');
      return false;
    }
  }

  // Upload profile image
  Future<bool> uploadProfileImage(File imageFile) async {
    setState(ViewState.busy);
    try {
      final success = await _userService.uploadProfileImage(imageFile);
      if (success) {
        // Refresh user data to get updated image URL
        _user = await _userService.getUserProfile();
        setState(ViewState.idle);
        return true;
      } else {
        setError('Failed to upload profile image');
        return false;
      }
    } catch (e) {
      setError('Error uploading profile image: ${e.toString()}');
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    setState(ViewState.busy);
    try {
      await _userService.clearUserData();
      _user = null;
      _paymentMethods = null;
      setState(ViewState.idle);
    } catch (e) {
      setError('Error during logout: ${e.toString()}');
    }
  }

  // Fetch payment methods
  Future<void> fetchPaymentMethods() async {
    setState(ViewState.busy);
    try {
      _paymentMethods = await _userService.getPaymentMethods();
      setState(ViewState.idle);
    } catch (e) {
      setError('Error fetching payment methods: ${e.toString()}');
    }
  }

  // Add payment method
  Future<bool> addPaymentMethod(Map<String, dynamic> paymentData) async {
    setState(ViewState.busy);
    try {
      final success = await _userService.addPaymentMethod(paymentData);
      if (success) {
        await fetchPaymentMethods(); // Refresh payment methods
        setState(ViewState.idle);
        return true;
      } else {
        setError('Failed to add payment method');
        return false;
      }
    } catch (e) {
      setError('Error adding payment method: ${e.toString()}');
      return false;
    }
  }

  // Update Tenant Preferences
  Future<bool> updateTenantPreferences(
      TenantPreferenceModel preferences) async {
    if (_user == null) {
      setError('User not loaded. Cannot update preferences.');
      return false;
    }
    setState(ViewState.busy);
    try {
      final success = await _userService.updateTenantPreferences(preferences);
      if (success) {
        _tenantPreference = preferences; // Update local state
        setState(ViewState.idle);
        return true;
      } else {
        setError('Failed to update tenant preferences.');
        return false;
      }
    } catch (e) {
      setError('Error updating tenant preferences: ${e.toString()}');
      return false;
    }
  }

  // Update user public status
  Future<bool> updateUserPublicStatus(bool isPublic) async {
    if (_user == null) {
      setError('User not loaded.');
      return false;
    }
    setState(ViewState.busy);
    try {
      // Assuming _userService has a method to update this specific field
      // or that updateUserProfile can handle the update appropriately.
      // For now, let's assume a specific method or a map update.
      final success = await _userService.updateUserProfile(
        _user!.copyWith(isPublic: isPublic), // Assumes User model has copyWith
      );
      // If updateUserProfile returns the updated User object:
      if (success != null) {
        // Assuming success means the updated user is returned
        _user = success; // Update local user
        setState(ViewState.idle);
        return true;
      } else {
        // If updateUserProfile returns a boolean:
        // final bool updateSuccess = await _userService.updateUserProfile(
        //   _user!.copyWith(isPublic: isPublic)
        // );
        // if (updateSuccess) {
        //    _user = _user!.copyWith(isPublic: isPublic);
        //    setState(ViewState.idle);
        //    return true;
        // }
        setError('Failed to update public status');
        return false;
      }
    } catch (e) {
      setError('Error updating public status: ${e.toString()}');
      return false;
    }
  }
}
