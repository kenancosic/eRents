import 'package:e_rents_desktop/base/repository.dart';
import 'package:e_rents_desktop/base/cache_manager.dart';
import 'package:e_rents_desktop/models/paged_result.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/services/tenant_service.dart';

/// Repository for tenant data management with intelligent caching
/// Handles both current tenants and prospective tenants (searching)
class TenantRepository extends BaseRepository<User, TenantService> {
  TenantRepository({required super.service, required super.cacheManager});

  @override
  String get resourceName => 'tenants';

  @override
  Duration get defaultCacheTtl => const Duration(minutes: 10);

  // Additional cache for prospective tenants and assignments
  final Map<String, DateTime> _cacheTimestamps = {};

  // ✅ UNIVERSAL SYSTEM INTEGRATION
  /// Get paged tenants using Universal System with backend pagination
  Future<PagedResult<User>> getPagedTenants(Map<String, dynamic> params) async {
    final specialCacheKey = _buildSpecialCacheKey('paged', params);

    if (enableCaching) {
      final cached = await cacheManager.get<PagedResult<User>>(specialCacheKey);
      if (cached != null) {
        return cached;
      }
    }

    // Call service pagination method
    final result = await service.getPagedTenants(params);

    // Convert service response to PagedResult
    final pagedData = PagedResult<User>(
      items: result['data'] as List<User>,
      totalCount: result['totalCount'] as int,
      page: (result['pageNumber'] as int) - 1, // Convert to 0-based
      pageSize: result['pageSize'] as int,
    );

    if (enableCaching) {
      await cacheManager.set(
        specialCacheKey,
        pagedData,
        duration: defaultCacheTtl,
      );
    }

    return pagedData;
  }

  /// Build cache key for paginated/special requests
  String _buildSpecialCacheKey(String operation, Map<String, dynamic> params) {
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final paramStr = sortedParams.entries
        .map((e) => '${e.key}:${e.value}')
        .join('_');
    return '${resourceName}_${operation}_$paramStr';
  }

  /// Get current tenants with caching and filtering
  Future<List<User>> getCurrentTenants({
    Map<String, String>? queryParams,
  }) async {
    final cacheKey = '${resourceName}_current_${_hashParams(queryParams)}';

    if (enableCaching) {
      final cached = await cacheManager.get<List<User>>(cacheKey);
      if (cached != null) {
        return cached;
      }
    }

    final tenants = await service.getCurrentTenants(queryParams: queryParams);

    if (enableCaching) {
      await cacheManager.set(cacheKey, tenants, duration: defaultCacheTtl);
    }

    return tenants;
  }

  /// Get prospective tenants (searching tenants) with caching
  Future<List<TenantPreference>> getProspectiveTenants({
    Map<String, String>? queryParams,
  }) async {
    final cacheKey = '${resourceName}_prospective_${_hashParams(queryParams)}';

    if (enableCaching) {
      final cached = await cacheManager.get<List<TenantPreference>>(cacheKey);
      if (cached != null) {
        return cached;
      }
    }

    final preferences = await service.getProspectiveTenants(
      queryParams: queryParams,
    );

    if (enableCaching) {
      await cacheManager.set(cacheKey, preferences, duration: defaultCacheTtl);
    }

    return preferences;
  }

  /// Get tenant feedbacks with caching
  Future<List<Review>> getTenantFeedbacks(int tenantId) async {
    final cacheKey = '${resourceName}_feedbacks_$tenantId';

    if (enableCaching) {
      final cached = await cacheManager.get<List<Review>>(cacheKey);
      if (cached != null) {
        return cached;
      }
    }

    final feedbacks = await service.getTenantFeedbacks(tenantId);

    if (enableCaching) {
      await cacheManager.set(
        cacheKey,
        feedbacks,
        duration: const Duration(minutes: 15),
      );
    }

    return feedbacks;
  }

  /// Add tenant feedback and invalidate cache
  Future<Review> addTenantFeedback(int tenantId, Review feedback) async {
    final newFeedback = await service.addTenantFeedback(tenantId, feedback);

    // Invalidate feedback cache for this tenant
    final cacheKey = '${resourceName}_feedbacks_$tenantId';
    await cacheManager.remove(cacheKey);

    return newFeedback;
  }

  /// Get tenant property assignments with caching
  Future<Map<int, Map<String, dynamic>>> getTenantPropertyAssignments(
    List<int> tenantIds,
  ) async {
    final cacheKey = '${resourceName}_assignments_${tenantIds.join('_')}';

    if (enableCaching) {
      final cached = await cacheManager.get<Map<int, Map<String, dynamic>>>(
        cacheKey,
      );
      if (cached != null) {
        return cached;
      }
    }

    final rawAssignments = await service.getTenantPropertyAssignments(
      tenantIds,
    );

    // Convert String keys to int keys
    final assignments = <int, Map<String, dynamic>>{};
    for (final entry in rawAssignments.entries) {
      final tenantId = int.tryParse(entry.key);
      if (tenantId != null && entry.value != null) {
        assignments[tenantId] = entry.value as Map<String, dynamic>;
      }
    }

    if (enableCaching) {
      await cacheManager.set(
        cacheKey,
        assignments,
        duration: const Duration(minutes: 20),
      );
    }

    return assignments;
  }

  /// Record property offer to tenant
  Future<void> recordPropertyOffer(int tenantId, int propertyId) async {
    await service.recordPropertyOfferedToTenant(tenantId, propertyId);

    // Invalidate relevant caches
    await _invalidateCurrentTenantsCache();
    await _invalidateAssignmentsCache();
  }

  /// Submit review for tenant (not implemented in service yet)
  Future<void> submitReview({
    required int tenantId,
    required double rating,
    required String description,
  }) async {
    // TODO: Implement when service supports review submission
    throw UnsupportedError(
      'Review submission not yet implemented in TenantService',
    );
  }

  // Business logic methods

  /// Filter current tenants by search criteria
  List<User> filterCurrentTenants(
    List<User> tenants, {
    String? searchQuery,
    String? city,
    String? status,
  }) {
    return tenants.where((tenant) {
      bool matchesSearch =
          searchQuery == null ||
          searchQuery.isEmpty ||
          tenant.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (tenant.email.toLowerCase().contains(searchQuery.toLowerCase()) ??
              false);

      bool matchesCity =
          city == null ||
          city.isEmpty ||
          (tenant.address?.city?.toLowerCase().contains(city.toLowerCase()) ??
              false);

      bool matchesStatus = status == null || status.isEmpty || status == 'all';
      // Status filtering can be enhanced based on booking/lease status

      return matchesSearch && matchesCity && matchesStatus;
    }).toList();
  }

  /// Filter prospective tenants by search criteria
  List<TenantPreference> filterProspectiveTenants(
    List<TenantPreference> preferences, {
    String? searchQuery,
    String? city,
    double? minBudget,
    double? maxBudget,
    List<String>? amenities,
  }) {
    return preferences.where((pref) {
      bool matchesSearch =
          searchQuery == null ||
          searchQuery.isEmpty ||
          (pref.city.toLowerCase().contains(searchQuery.toLowerCase())) ||
          (pref.description.toLowerCase().contains(searchQuery.toLowerCase()));

      bool matchesCity =
          city == null ||
          city.isEmpty ||
          (pref.city.toLowerCase().contains(city.toLowerCase()));

      bool matchesBudget =
          (minBudget == null || (pref.maxPrice ?? 0) >= minBudget) &&
          (maxBudget == null ||
              (pref.maxPrice ?? double.infinity) <= maxBudget);

      bool matchesAmenities =
          amenities == null ||
          amenities.isEmpty ||
          (pref.amenities.any((amenity) => amenities.contains(amenity)));

      return matchesSearch && matchesCity && matchesBudget && matchesAmenities;
    }).toList();
  }

  /// Get tenant statistics
  Map<String, int> getTenantStatistics(
    List<User> currentTenants,
    List<TenantPreference> prospectiveTenants,
  ) {
    return {
      'totalCurrentTenants': currentTenants.length,
      'totalProspectiveTenants': prospectiveTenants.length,
      'tenantsWithFeedback':
          currentTenants.length, // Could be enhanced with actual feedback check
      'recentProspectives':
          prospectiveTenants
              .where(
                (p) => p.searchStartDate.isAfter(
                  DateTime.now().subtract(const Duration(days: 7)),
                ),
              )
              .length,
    };
  }

  // Helper methods

  String _hashParams(Map<String, String>? params) {
    if (params == null || params.isEmpty) return 'default';
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return sortedParams.entries.map((e) => '${e.key}:${e.value}').join('_');
  }

  Future<void> _invalidateCurrentTenantsCache() async {
    await cacheManager.clear('${resourceName}_current');
  }

  Future<void> _invalidateAssignmentsCache() async {
    await cacheManager.clear('${resourceName}_assignments');
  }

  @override
  Future<void> clearCache() async {
    await cacheManager.clear(resourceName);
    _cacheTimestamps.clear();
  }

  // Required BaseRepository overrides

  @override
  Future<List<User>> fetchAllFromService([Map<String, dynamic>? params]) async {
    final queryParams = params?.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    return getCurrentTenants(queryParams: queryParams);
  }

  @override
  Future<User> fetchByIdFromService(String id) async {
    return service.getTenantById(int.parse(id));
  }

  @override
  Future<User> createInService(User item) async {
    throw UnsupportedError(
      'Creating tenants directly not supported. Use booking/lease creation.',
    );
  }

  @override
  Future<User> updateInService(String id, User item) async {
    throw UnsupportedError(
      'Updating tenants directly not supported. Use user management.',
    );
  }

  @override
  Future<void> deleteInService(String id) async {
    throw UnsupportedError(
      'Deleting tenants directly not supported. Use lease termination.',
    );
  }

  @override
  Future<bool> existsInService(String id) async {
    try {
      await service.getTenantById(int.parse(id));
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  String? extractIdFromItem(User item) {
    return item.id.toString();
  }

  @override
  Future<int> countInService([Map<String, dynamic>? params]) async {
    // For tenants, count would typically be the number of current tenants
    final tenants = await fetchAllFromService(params);
    return tenants.length;
  }

  @override
  User fromJson(Map<String, dynamic> json) => User.fromJson(json);

  @override
  Future<PagedResult<User>> fetchPagedFromService([
    Map<String, dynamic>? params,
  ]) async {
    // Call service pagination method
    final result = await service.getPagedTenants(params ?? {});

    // Convert service response to PagedResult
    final pagedData = PagedResult<User>(
      items: (result['data'] as List).map((i) => User.fromJson(i)).toList(),
      totalCount: result['totalCount'] as int,
      page: (result['pageNumber'] as int) - 1, // Convert to 0-based
      pageSize: result['pageSize'] as int,
    );
    return pagedData;
  }
}
