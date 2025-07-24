import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/paged_result.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/models/property.dart';

/// Refactored Tenants Provider using the new base architecture.
///
/// This provider consolidates all tenant-related functionality and leverages
/// [BaseProvider] for state management, caching, and simplified API calls.
class TenantsProviderRefactored extends BaseProvider {
  TenantsProviderRefactored(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  List<User> _tenants = [];
  List<User> get tenants => _tenants;

  PagedResult<User>? _pagedResult;
  PagedResult<User>? get pagedResult => _pagedResult;

  User? _selectedTenant;
  User? get selectedTenant => _selectedTenant;

  List<Review> _tenantFeedbacks = [];
  List<Review> get tenantFeedbacks => _tenantFeedbacks;

  List<Property> _availableProperties = [];
  List<Property> get availableProperties => _availableProperties;

  // ─── Public API ─────────────────────────────────────────────────────────

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
    _tenants.clear();
    _pagedResult = null;
    _selectedTenant = null;
    _tenantFeedbacks.clear();
    _availableProperties.clear();
    notifyListeners();
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
