import 'dart:convert';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';

// TODO: Full backend integration for all tenant features is pending.
// Ensure all endpoints are functional and error handling is robust.
class TenantService extends ApiService {
  TenantService(String baseUrl, SecureStorageService secureStorageService)
    : super(baseUrl, secureStorageService);

  Future<List<User>> getCurrentTenants({
    Map<String, String>? queryParams,
  }) async {
    print('TenantService: Attempting to fetch current tenants...');
    String endpoint = '/users?role=TENANT&status=ACTIVE';
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = Uri(queryParameters: queryParams).query;
      endpoint += '&$queryString';
    }
    try {
      final response = await get(endpoint, authenticated: true);
      final List<dynamic> data = jsonDecode(response.body);
      final tenants = data.map((json) => User.fromJson(json)).toList();
      print(
        'TenantService: Successfully fetched ${tenants.length} current tenants.',
      );
      return tenants;
    } catch (e) {
      print(
        'TenantService: Error fetching current tenants: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to fetch current tenants. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<List<TenantPreference>> getProspectiveTenants({
    Map<String, String>? queryParams,
  }) async {
    print('TenantService: Attempting to fetch prospective tenants...');
    String endpoint = '/tenant-preferences/search';
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = Uri(queryParameters: queryParams).query;
      endpoint += '?$queryString';
    }
    try {
      final response = await get(endpoint, authenticated: true);
      final List<dynamic> data = jsonDecode(response.body);
      final preferences =
          data.map((json) => TenantPreference.fromJson(json)).toList();
      print(
        'TenantService: Successfully fetched ${preferences.length} prospective tenant preferences.',
      );
      return preferences;
    } catch (e) {
      print(
        'TenantService: Error fetching prospective tenants: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to fetch prospective tenants. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<User> getTenantById(String tenantId) async {
    print('TenantService: Attempting to fetch tenant $tenantId...');
    try {
      final response = await get('/users/$tenantId', authenticated: true);
      final user = User.fromJson(jsonDecode(response.body));
      print('TenantService: Successfully fetched tenant $tenantId.');
      return user;
    } catch (e) {
      print(
        'TenantService: Error fetching tenant $tenantId: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to fetch tenant $tenantId. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
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

  Future<List<Review>> getTenantFeedbacks(String tenantId) async {
    final response = await get('/tenants/$tenantId/feedbacks');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Review.fromJson(json)).toList();
  }

  Future<Review> addTenantFeedback(String tenantId, Review feedback) async {
    final response = await post(
      '/tenants/$tenantId/feedbacks',
      feedback.toJson(),
    );
    return Review.fromJson(jsonDecode(response.body));
  }

  Future<void> recordPropertyOfferedToTenant(
    int tenantId,
    int propertyId,
  ) async {
    // Assuming this endpoint just needs a 200/201 for success and doesn't return a body
    // or returns a simple confirmation that we don't need to parse.
    await post('/tenants/$tenantId/offered-properties', {
      'propertyId': propertyId,
    });
  }
}
