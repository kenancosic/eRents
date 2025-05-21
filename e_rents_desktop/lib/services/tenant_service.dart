import 'dart:convert';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/models/tenant_feedback.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';

class TenantService extends ApiService {
  TenantService(String baseUrl, SecureStorageService secureStorageService)
    : super(baseUrl, secureStorageService);

  Future<List<User>> getCurrentTenants({
    Map<String, String>? queryParams,
  }) async {
    String endpoint = '/users?role=TENANT&status=ACTIVE';
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = Uri(queryParameters: queryParams).query;
      endpoint += '&$queryString'; // Append additional query params
    }
    final response = await get(endpoint);
    // Assuming a generic /users endpoint that can be filtered by role and status
    // Adjust endpoint to `/tenants/current` if a specific one exists.
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => User.fromJson(json)).toList();
  }

  Future<List<TenantPreference>> getProspectiveTenants({
    Map<String, String>? queryParams,
  }) async {
    String endpoint = '/tenant-preferences/search';
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = Uri(queryParameters: queryParams).query;
      endpoint += '?$queryString'; // Append query params
    }
    final response = await get(endpoint);
    // Adjust endpoint to `/tenants/prospective` or `/users?role=TENANT&isSearching=true`
    // if that's more appropriate
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => TenantPreference.fromJson(json)).toList();
  }

  Future<User> getTenantById(String tenantId) async {
    final response = await get('/users/$tenantId');
    // Assuming /users/{id} can fetch any user, including tenants
    // Adjust to `/tenants/$tenantId` if specific
    return User.fromJson(jsonDecode(response.body));
  }

  Future<TenantPreference> getTenantPreferences(String tenantId) async {
    final response = await get('/tenant-preferences/$tenantId');
    // Adjust if preferences are nested under user/tenant: `/tenants/$tenantId/preferences`
    return TenantPreference.fromJson(jsonDecode(response.body));
  }

  Future<TenantPreference> updateTenantPreferences(
    String tenantId,
    TenantPreference preferences,
  ) async {
    final response = await put(
      '/tenant-preferences/$tenantId',
      preferences.toJson(),
    );
    return TenantPreference.fromJson(jsonDecode(response.body));
  }

  Future<List<TenantFeedback>> getTenantFeedbacks(String tenantId) async {
    final response = await get('/tenants/$tenantId/feedbacks');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => TenantFeedback.fromJson(json)).toList();
  }

  Future<TenantFeedback> addTenantFeedback(
    String tenantId,
    TenantFeedback feedback,
  ) async {
    final response = await post(
      '/tenants/$tenantId/feedbacks',
      feedback.toJson(),
    );
    return TenantFeedback.fromJson(jsonDecode(response.body));
  }

  Future<void> recordPropertyOfferedToTenant(
    String tenantId,
    String propertyId,
  ) async {
    // Assuming this endpoint just needs a 200/201 for success and doesn't return a body
    // or returns a simple confirmation that we don't need to parse.
    await post('/tenants/$tenantId/offered-properties', {
      'propertyId': propertyId,
    });
  }
}
