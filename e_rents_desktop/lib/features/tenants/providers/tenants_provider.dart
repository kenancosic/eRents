import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/paged_result.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';

/// Refactored Tenants Provider using the new base architecture.
///
/// This provider consolidates all tenant-related functionality and leverages
/// [BaseProvider] for state management, caching, and simplified API calls.
class TenantsProvider extends BaseProvider {
  TenantsProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  List<User> _tenants = [];
  List<User> get tenants => _tenants;

  List<User> _currentTenants = [];
  List<User> get currentTenants => _currentTenants;

  List<User> _prospectiveTenants = [];
  List<User> get prospectiveTenants => _prospectiveTenants;

  PagedResult<User>? _pagedResult;
  PagedResult<User>? get pagedResult => _pagedResult;

  User? _selectedTenant;
  User? get selectedTenant => _selectedTenant;

  List<Review> _tenantFeedbacks = [];
  List<Review> get tenantFeedbacks => _tenantFeedbacks;

  List<Property> _availableProperties = [];
  List<Property> get availableProperties => _availableProperties;

  Map<String, Map<String, dynamic>> _propertyAssignments = {};
  Map<String, Map<String, dynamic>> get propertyAssignments => _propertyAssignments;

  List<TenantPreference> _tenantPreferences = [];
  List<TenantPreference> get tenantPreferences => _tenantPreferences;

  bool _isLoadingProspective = false;
  bool get isLoadingProspective => _isLoadingProspective;

  // ─── Public API ─────────────────────────────────────────────────────────

  /// Load all tenant data (current tenants, prospective tenants, property assignments, tenant preferences)
  Future<void> loadAllData() async {
    await executeWithState(() async {
      // Load current tenants
      await _loadCurrentTenants();
      // Load prospective tenants  
      await _loadProspectiveTenants();
      // Load property assignments
      await _loadPropertyAssignments();
      // Load tenant preferences (advertisements)
      await _loadTenantPreferences();
    });
  }

  /// Refresh all tenant data by invalidating caches and reloading
  Future<void> refreshAllData() async {
    // Clear all caches
    clearAllTenantCaches();
    // Reload all data
    await loadAllData();
  }

  /// Load paginated tenants with filtering.
  Future<void> loadPagedTenants(Map<String, dynamic> params) async {
    final result = await executeWithState<PagedResult<User>>(() async {
      return await api.getPagedAndDecode(
        '/users/tenants${api.buildQueryString(params)}',
        User.fromJson,
        authenticated: true,
      );
    });
    
    if (result != null) {
      _pagedResult = result;
      _tenants = result.items;
      notifyListeners();
    }
  }

  /// Load tenant details by ID, using cache first.
  Future<void> loadTenantDetails(String tenantId, {bool forceRefresh = false}) async {
    final cacheKey = 'tenant_$tenantId';
    
    if (forceRefresh) {
      invalidateCache(cacheKey);
    }
    
    final result = await executeWithCache<User>(
      cacheKey,
      () => api.getAndDecode('/users/$tenantId', User.fromJson, authenticated: true),
    );
    
    if (result != null) {
      _selectedTenant = result;
      notifyListeners();
    }
  }

  /// Load tenant feedbacks, using cache first.
  Future<void> loadTenantFeedbacks(String tenantId, {bool forceRefresh = false}) async {
    final cacheKey = 'feedbacks_$tenantId';
    
    if (forceRefresh) {
      invalidateCache(cacheKey);
    }
    
    final result = await executeWithCache<List<Review>>(
      cacheKey,
      () => api.getListAndDecode('/users/$tenantId/reviews', Review.fromJson, authenticated: true),
    );
    
    if (result != null) {
      _tenantFeedbacks = result;
      notifyListeners();
    }
  }

  /// Submit a review for a tenant.
  Future<bool> submitTenantReview({
    required String tenantId,
    required double rating,
    required String description,
  }) async {
    final reviewData = {
      'rating': rating,
      'comment': description,
    };
    
    final result = await executeWithState<Map<String, dynamic>>(() async {
      return await api.postJson('/users/$tenantId/reviews', reviewData, authenticated: true);
    });
    
    if (result != null) {
      invalidateCache('feedbacks_$tenantId');
      return true;
    }
    return false;
  }

  /// Load available properties for property offers, using cache first.
  Future<void> loadAvailableProperties({bool forceRefresh = false}) async {
    const cacheKey = 'available_properties';
    
    if (forceRefresh) {
      invalidateCache(cacheKey);
    }
    
    final result = await executeWithCache<List<Property>>(
      cacheKey,
      () => api.getListAndDecode('/properties?IsAvailable=true', Property.fromJson, authenticated: true),
    );
    
    if (result != null) {
      _availableProperties = result;
      notifyListeners();
    }
  }

  /// Send a property offer to a tenant.
  Future<bool> sendPropertyOffer(String tenantId, String propertyId, {String? customMessage}) async {
    final offerData = {
      'tenantId': tenantId,
      'propertyId': propertyId,
      'message': customMessage ?? 'You have received a property offer.',
    };
    
    final result = await executeWithState<Map<String, dynamic>>(() async {
      return await api.postJson('/chat/send-property-offer', offerData, authenticated: true);
    });
    
    return result != null;
  }

  /// Invalidate all tenant-related caches.
  void clearAllTenantCaches() {
    invalidateCache('tenant_');
    invalidateCache('feedbacks_');
    invalidateCache('paged_tenants');
    invalidateCache('current_tenants');
    invalidateCache('prospective_tenants');
    invalidateCache('property_assignments');
    invalidateCache('tenant_preferences');
    _tenants.clear();
    _currentTenants.clear();
    _prospectiveTenants.clear();
    _propertyAssignments.clear();
    _tenantPreferences.clear();
    _pagedResult = null;
    _selectedTenant = null;
    _tenantFeedbacks.clear();
    _availableProperties.clear();
    _isLoadingProspective = false;
    notifyListeners();
  }

  // ─── Private Helper Methods ─────────────────────────────────────────────

  /// Load current tenants (active tenants)
  Future<void> _loadCurrentTenants() async {
    const cacheKey = 'current_tenants';
    
    final result = await getCachedOrExecute<List<User>>(
      cacheKey,
      () => api.getListAndDecode(
        '/users/tenants?status=current',
        User.fromJson,
        authenticated: true,
      ),
    );
    
    _currentTenants = result;
  }

  /// Load prospective tenants (users who applied but not yet tenants)
  Future<void> _loadProspectiveTenants() async {
    _isLoadingProspective = true;
    notifyListeners();
    
    try {
      const cacheKey = 'prospective_tenants';
      
      final result = await getCachedOrExecute<List<User>>(
        cacheKey,
        () => api.getListAndDecode(
          '/users/tenants?status=prospective',
          User.fromJson,
          authenticated: true,
        ),
      );
      
      _prospectiveTenants = result;
    } finally {
      _isLoadingProspective = false;
      notifyListeners();
    }
  }

  /// Load property assignments (which tenants are assigned to which properties)
  Future<void> _loadPropertyAssignments() async {
    const cacheKey = 'property_assignments';
    
    final result = await getCachedOrExecute<Map<String, Map<String, dynamic>>>(
      cacheKey,
      () async {
        final response = await api.getJson('/tenants/property-assignments', authenticated: true);
        final assignments = (response['assignments'] as List).cast<Map<String, dynamic>>();
        
        // Convert list to map keyed by tenant ID for efficient lookup
        final assignmentMap = <String, Map<String, dynamic>>{};
        for (final assignment in assignments) {
          final tenantId = assignment['tenantId']?.toString();
          if (tenantId != null) {
            assignmentMap[tenantId] = assignment;
          }
        }
        
        return assignmentMap;
      },
    );
    
    _propertyAssignments = result;
  }

  /// Load tenant preferences (tenant advertisements/search criteria)
  Future<void> _loadTenantPreferences() async {
    const cacheKey = 'tenant_preferences';
    
    final result = await getCachedOrExecute<List<TenantPreference>>(
      cacheKey,
      () => api.getListAndDecode(
        '/tenant-preferences',
        TenantPreference.fromJson,
        authenticated: true,
      ),
    );
    
    _tenantPreferences = result;
  }

  // ─── Computed Properties and Getters ───────────────────────────────────

  bool get isDetailsLoading => isLoading;
  String? get detailsError => error;

  bool get areFeedbacksLoading => isLoading;
  String? get feedbacksError => error;

  bool get arePropertiesLoading => isLoading;
  String? get propertiesError => error;

  bool get isSendingOffer => isLoading;
  String? get offerError => error;
}
