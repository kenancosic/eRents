import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/models/tenant_preference_model.dart';

/// Provider for managing tenant preferences
/// Handles loading and updating tenant accommodation preferences
class TenantPreferencesProvider extends BaseProvider {
  TenantPreferencesProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  TenantPreferenceModel? _tenantPreferences;

  // ─── Getters ────────────────────────────────────────────────────────────
  TenantPreferenceModel? get tenantPreferences => _tenantPreferences;
  TenantPreferenceModel? get tenantPreference => _tenantPreferences; // Compatibility alias

  // ─── Public API ─────────────────────────────────────────────────────────

  /// Load tenant preferences for current user
  Future<void> loadTenantPreferences({bool forceRefresh = false}) async {
    // If not forcing refresh and we already have data, skip
    if (!forceRefresh && _tenantPreferences != null) {
      debugPrint('TenantPreferencesProvider: Using existing tenant preferences');
      return;
    }

    final preferences = await executeWithState(() async {
      debugPrint('TenantPreferencesProvider: Loading tenant preferences');
      final response = await api.get('/users/current/tenant-preferences', authenticated: true);

      if (response.statusCode == 200) {
        final preferencesData = jsonDecode(response.body);
        debugPrint('TenantPreferencesProvider: Tenant preferences loaded successfully');
        return TenantPreferenceModel.fromJson(preferencesData);
      } else {
        throw Exception('Failed to load tenant preferences: ${response.statusCode}');
      }
    });

    if (preferences != null) {
      _tenantPreferences = preferences;
    }
  }

  /// Update tenant preferences
  Future<bool> updateTenantPreferences(TenantPreferenceModel preferences) async {
    final success = await executeWithStateForSuccess(() async {
      debugPrint('TenantPreferencesProvider: Updating tenant preferences');

      final response = await api.put(
        '/users/current/tenant-preferences',
        preferences.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 200) {
        _tenantPreferences = preferences;
        debugPrint('TenantPreferencesProvider: Tenant preferences updated successfully');
      } else {
        debugPrint('TenantPreferencesProvider: Failed to update tenant preferences');
        throw Exception('Failed to update tenant preferences');
      }
    }, errorMessage: 'Failed to update tenant preferences');

    return success;
  }
}
