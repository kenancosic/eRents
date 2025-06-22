import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/base/base.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/repositories/profile_repository.dart';

/// State provider for fetching the user's profile.
/// This provider is now read-only and is responsible only for loading the initial user data.
class ProfileStateProvider extends StateProvider<User?> {
  final ProfileRepository _repository;

  bool _isLoading = false;
  AppError? _error;

  ProfileStateProvider(this._repository) : super(null);

  bool get isLoading => _isLoading;
  AppError? get error => _error;
  User? get currentUser => state;

  Future<void> loadUserProfile({bool forceRefresh = false}) async {
    // If we are already loading or have data (and not forcing a refresh), do nothing.
    if (_isLoading || (state != null && !forceRefresh)) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = await _repository.getUserProfile(forceRefresh: forceRefresh);
      updateState(user);
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace);
      // We keep the old state on error, so the UI can still display it if it exists
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Called when a sub-form successfully updates the user profile.
  void updateUserState(User updatedUser) {
    updateState(updatedUser);
  }
}
