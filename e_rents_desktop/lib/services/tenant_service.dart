import 'dart:convert';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';

/// ✅ Backend Integration Complete: All tenant management endpoints implemented
/// Backend API Endpoints: /Tenant/*
/// Security: User-scoped access control with ownership validation
/// Pattern: Business Logic Controller (Non-CRUD) following established patterns
class TenantService extends ApiService {
  TenantService(String baseUrl, SecureStorageService secureStorageService)
    : super(baseUrl, secureStorageService);

  /// Get current tenants for the authenticated landlord
  /// Backend: GET /Tenant/current
  /// Returns: List<UserResponseDto> from backend ITenantService.GetCurrentTenantsAsync()
  Future<List<User>> getCurrentTenants({
    Map<String, String>? queryParams,
  }) async {
    print('TenantService: Fetching current tenants...');
    String endpoint = '/Tenant/current';
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = Uri(queryParameters: queryParams).query;
      endpoint += '?$queryString';
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
      print('TenantService: Error fetching current tenants: $e');
      rethrow;
    }
  }

  /// Get prospective tenants (tenants actively searching)
  /// Backend: GET /Tenant/prospective
  /// Returns: List<TenantPreferenceResponseDto> from backend ITenantService.GetProspectiveTenantsAsync()
  Future<List<TenantPreference>> getProspectiveTenants({
    Map<String, String>? queryParams,
  }) async {
    print('TenantService: Fetching prospective tenants...');
    String endpoint = '/Tenant/prospective';
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
        'TenantService: Successfully fetched ${preferences.length} prospective tenants.',
      );
      return preferences;
    } catch (e) {
      print('TenantService: Error fetching prospective tenants: $e');
      rethrow;
    }
  }

  /// Get specific tenant details
  /// Backend: GET /Tenant/current/{tenantId}
  /// Returns: UserResponseDto from backend ITenantService.GetTenantByIdAsync()
  Future<User> getTenantById(int tenantId) async {
    print('TenantService: Fetching tenant $tenantId...');
    try {
      final response = await get(
        '/Tenant/current/$tenantId',
        authenticated: true,
      );
      final user = User.fromJson(jsonDecode(response.body));
      print('TenantService: Successfully fetched tenant $tenantId.');
      return user;
    } catch (e) {
      print('TenantService: Error fetching tenant $tenantId: $e');
      rethrow;
    }
  }

  /// Get tenant preferences
  /// Backend: GET /Tenant/preferences/{tenantId}
  /// Returns: TenantPreferenceResponseDto from backend ITenantService.GetTenantPreferencesAsync()
  Future<TenantPreference> getTenantPreferences(int tenantId) async {
    print('TenantService: Fetching preferences for tenant $tenantId...');
    try {
      final response = await get(
        '/Tenant/preferences/$tenantId',
        authenticated: true,
      );
      return TenantPreference.fromJson(jsonDecode(response.body));
    } catch (e) {
      print('TenantService: Error fetching tenant preferences: $e');
      rethrow;
    }
  }

  /// Update tenant preferences
  /// Backend: PUT /Tenant/preferences/{tenantId}
  /// Returns: TenantPreferenceResponseDto from backend ITenantService.UpdateTenantPreferencesAsync()
  Future<TenantPreference> updateTenantPreferences(
    int tenantId,
    TenantPreference preferences,
  ) async {
    print('TenantService: Updating preferences for tenant $tenantId...');
    try {
      final response = await put(
        '/Tenant/preferences/$tenantId',
        preferences.toJson(),
        authenticated: true,
      );
      return TenantPreference.fromJson(jsonDecode(response.body));
    } catch (e) {
      print('TenantService: Error updating tenant preferences: $e');
      rethrow;
    }
  }

  /// Get tenant feedbacks/reviews
  /// Backend: GET /Tenant/feedback/{tenantId}
  /// Returns: List<ReviewResponseDto> from backend ITenantService.GetTenantFeedbacksAsync()
  Future<List<Review>> getTenantFeedbacks(int tenantId) async {
    print('TenantService: Fetching feedbacks for tenant $tenantId...');
    try {
      final response = await get(
        '/Tenant/feedback/$tenantId',
        authenticated: true,
      );
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      print('TenantService: Error fetching tenant feedbacks: $e');
      rethrow;
    }
  }

  /// Add tenant feedback/review
  /// Backend: POST /Tenant/feedback/{tenantId}
  /// Returns: ReviewResponseDto from backend ITenantService.AddTenantFeedbackAsync()
  Future<Review> addTenantFeedback(int tenantId, Review feedback) async {
    print('TenantService: Adding feedback for tenant $tenantId...');
    try {
      final response = await post(
        '/Tenant/feedback/$tenantId',
        feedback.toJson(),
        authenticated: true,
      );
      return Review.fromJson(jsonDecode(response.body));
    } catch (e) {
      print('TenantService: Error adding tenant feedback: $e');
      rethrow;
    }
  }

  /// Record property offered to tenant
  /// Backend: POST /Tenant/{tenantId}/offer/{propertyId}
  /// Returns: void from backend ITenantService.RecordPropertyOfferedToTenantAsync()
  Future<void> recordPropertyOfferedToTenant(
    int tenantId,
    int propertyId,
  ) async {
    print(
      'TenantService: Recording property offer: tenant $tenantId, property $propertyId...',
    );
    try {
      await post(
        '/Tenant/$tenantId/offer/$propertyId',
        {},
        authenticated: true,
      );
      print('TenantService: Property offer recorded successfully.');
    } catch (e) {
      print('TenantService: Error recording property offer: $e');
      rethrow;
    }
  }

  /// Get tenant relationships for landlord portfolio
  /// Backend: GET /Tenant/relationships
  /// Returns: List<TenantRelationshipDto> from backend ITenantService.GetTenantRelationshipsForLandlordAsync()
  Future<List<Map<String, dynamic>>> getTenantRelationships() async {
    print('TenantService: Fetching tenant relationships...');
    try {
      final response = await get('/Tenant/relationships', authenticated: true);
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      print('TenantService: Error fetching tenant relationships: $e');
      rethrow;
    }
  }

  /// Get property assignments for tenants
  /// Backend: GET /Tenant/assignments
  /// Returns: Dictionary<int, PropertyResponseDto> from backend ITenantService.GetTenantPropertyAssignmentsAsync()
  Future<Map<String, dynamic>> getTenantPropertyAssignments(
    List<int> tenantIds,
  ) async {
    print(
      'TenantService: Fetching property assignments for ${tenantIds.length} tenants...',
    );
    try {
      // Build query string with multiple tenantIds parameters
      // Backend expects List<int> tenantIds which requires multiple parameters like: tenantIds=1&tenantIds=2&tenantIds=3
      final queryParts = tenantIds.map((id) => 'tenantIds=$id').toList();
      final queryString = queryParts.join('&');

      final response = await get(
        '/Tenant/assignments?$queryString',
        authenticated: true,
      );

      // Check if response body is empty
      if (response.body.isEmpty) {
        print('TenantService: Empty response body from /Tenant/assignments');
        return <String, dynamic>{};
      }

      final result = jsonDecode(response.body);
      print(
        'TenantService: Successfully fetched property assignments for ${tenantIds.length} tenants',
      );
      return result;
    } catch (e) {
      print('TenantService: Error fetching tenant property assignments: $e');
      rethrow;
    }
  }
}
