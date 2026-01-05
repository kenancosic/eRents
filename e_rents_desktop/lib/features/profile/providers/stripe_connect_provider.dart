// lib/features/profile/providers/stripe_connect_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/features/profile/models/connect_account_status.dart';

/// Provider for managing Stripe Connect account integration for landlords
/// Handles onboarding, status checking, and account management
class StripeConnectProvider extends BaseProvider {
  ConnectAccountStatus? _accountStatus;

  StripeConnectProvider(super.api);

  // ─── Getters ────────────────────────────────────────────────────────────

  ConnectAccountStatus? get accountStatus => _accountStatus;
  bool get isConnected => _accountStatus?.isActive ?? false;
  bool get hasAccount => _accountStatus?.accountId != null;
  ConnectAccountState? get accountState => _accountStatus?.state;

  // ─── Public API ─────────────────────────────────────────────────────────

  /// Load the current Stripe Connect account status
  Future<void> loadAccountStatus() async {
    await executeWithState(() async {
      final response = await api.get(
        '/payments/stripe/connect/status',
        authenticated: true,
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      _accountStatus = ConnectAccountStatus.fromJson(data);
      debugPrint('StripeConnectProvider: Loaded account status - ${_accountStatus?.state}');
    }, errorMessage: 'Failed to load Stripe account status');
  }

  /// Create a Stripe Connect onboarding link
  /// Returns the onboarding URL or null if failed
  Future<String?> createOnboardingLink({
    required String refreshUrl,
    required String returnUrl,
  }) async {
    return await executeWithState<String?>(() async {
      debugPrint('StripeConnectProvider: Creating onboarding link');
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

      debugPrint('StripeConnectProvider: Onboarding link created successfully');
      return linkResponse.onboardingUrl;
    }, errorMessage: 'Failed to create onboarding link');
  }

  /// Disconnect the Stripe Connect account
  /// Returns true if successful
  Future<bool> disconnectAccount() async {
    final success = await executeWithStateForSuccess(() async {
      debugPrint('StripeConnectProvider: Disconnecting Stripe account');
      await api.delete(
        '/payments/stripe/connect/disconnect',
        authenticated: true,
      );
      _accountStatus = null;
      debugPrint('StripeConnectProvider: Account disconnected successfully');
    });
    return success;
  }

  /// Get Stripe dashboard link
  /// Returns the dashboard URL or null if failed
  Future<String?> getDashboardLink() async {
    return await executeWithState<String?>(() async {
      debugPrint('StripeConnectProvider: Getting dashboard link');
      final response = await api.get(
        '/payments/stripe/connect/dashboard',
        authenticated: true,
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      final url = data['url'] as String?;
      debugPrint('StripeConnectProvider: Dashboard link retrieved');
      return url;
    }, errorMessage: 'Failed to get dashboard link');
  }

  /// Refresh account status after onboarding completion
  Future<void> refreshAfterOnboarding() async {
    await Future.delayed(const Duration(seconds: 2)); // Small delay for backend sync
    await loadAccountStatus();
  }
}
