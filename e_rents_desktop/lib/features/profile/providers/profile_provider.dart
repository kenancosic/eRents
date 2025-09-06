import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_windows/webview_windows.dart';
import 'dart:convert';

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

  // PayPal linking state
  bool _isUpdatingPaypal = false;
  bool get isUpdatingPaypal => _isUpdatingPaypal;

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
      return await api.getAndDecode('Profile', User.fromJson, authenticated: true);
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
    final updated = await executeWithRetry<User>(() async {
      return await api.putAndDecode('Profile', user.toJson(), User.fromJson, authenticated: true);
    }, isUpdate: true);
    if (updated != null) {
      _currentUser = updated;
      toggleEditing();
      notifyListeners();
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
        'Users/change-password',
        {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
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

  Future<void> startPayPalLinking(BuildContext context) async {
    _isUpdatingPaypal = true;
    clearError();
    notifyListeners();

    try {
      final response = await api.get(
        'payments/paypal/account/start',
        authenticated: true,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to start PayPal linking process.');
      }

      final responseBody = jsonDecode(response.body);
      final approvalUrl = responseBody['approvalUrl'];

      if (approvalUrl == null) {
        throw Exception('Approval URL not found in response.');
      }

      _showPayPalWebView(context, approvalUrl);
    } catch (e) {
      setError(e.toString());
      _isUpdatingPaypal = false;
      notifyListeners();
    }
  }

  void _showPayPalWebView(BuildContext context, String url) {
    final webview = WebviewController();

    webview.initialize().then((_) {
      webview.url.listen((currentUrl) {
        // Check for success or cancel URLs from the backend (host-agnostic)
        if (currentUrl.contains('/api/payments/paypal/account/callback?code=')) {
          context.pop();
          webview.dispose();
          // Reload user profile to get updated PayPal status
          loadUserProfile();
          _isUpdatingPaypal = false;
          notifyListeners();
        } else if (currentUrl.contains('/api/payments/paypal/account/callback?error=')) {
          context.pop();
          webview.dispose();
          setError('PayPal linking cancelled or failed.');
          _isUpdatingPaypal = false;
          notifyListeners();
        }
      });

      webview.loadUrl(url);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: SizedBox(
            width: 500,
            height: 600,
            child: Webview(webview),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                context.pop();
                webview.dispose();
                 _isUpdatingPaypal = false;
                 notifyListeners();
              },
            )
          ],
        ),
      );
    });
  }


  Future<bool> unlinkPaypal() async {
    _isUpdatingPaypal = true;
    clearError();
    notifyListeners();

    try {
      final response = await api.delete(
        'payments/paypal/account',
        authenticated: true,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await loadUserProfile();
        return true;
      } else {
        throw Exception('Failed to unlink PayPal account');
      }
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      _isUpdatingPaypal = false;
      notifyListeners();
    }
  }

  void clearUserProfile() {
    _currentUser = null;
    notifyListeners();
  }
}
