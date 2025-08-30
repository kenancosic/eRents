import 'dart:async';
import 'package:e_rents_desktop/models/property.dart';
import 'dart:convert';
import 'package:e_rents_desktop/models/paged_result.dart';
import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/base/app_error.dart';
import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/models/image.dart' as model;
import 'package:e_rents_desktop/models/property_tenant_summary.dart';
import 'package:e_rents_desktop/models/property_status_update_request.dart';
import 'package:http/http.dart' as http;

/// Property provider aligned with BaseProvider pattern and finalized API
class PropertyProvider extends BaseProvider {
  PropertyProvider(super.api);

  // State
  List<Property> _items = [];
  PagedResult<Property>? _paged;
  Property? _selected;
  Map<String, dynamic> _filters = {};
  String? _sortBy;
  bool _ascending = true;
  int _page = 1;
  int _pageSize = 20;

  // Reviews state (cached per property)
  final Map<int, List<Review>> _propertyReviews = {};
  final Map<int, bool> _isLoadingReviews = {};

  // Getters
  List<Property> get items => _items;
  PagedResult<Property>? get paged => _paged;
  Property? get selected => _selected;
  Map<String, dynamic> get filters => Map.unmodifiable(_filters);
  ({int page, int pageSize, String? sortBy, bool ascending}) get lastQuery =>
      (page: _page, pageSize: _pageSize, sortBy: _sortBy, ascending: _ascending);
  List<Review> reviewsForSelected() =>
      _selected == null ? const [] : (_propertyReviews[_selected!.propertyId] ?? const []);
  List<Review> reviewsFor(int propertyId) => _propertyReviews[propertyId] ?? const [];
  bool isLoadingReviews(int propertyId) => _isLoadingReviews[propertyId] == true;

  // Backward-compat shim methods to keep existing screens compiling
  Future<List<Property>?> loadProperties() => fetchList();
  Future<List<Property>?> loadPropertiesSorted({String? sortBy, bool? ascending}) =>
      fetchList(sortBy: sortBy, ascending: ascending);
  Future<Property?> loadProperty(int id) => getById(id);
  Future<Property?> createProperty(Property p) => create(p);
  Future<Property?> updateProperty(Property p) => update(p);
  Future<bool> deleteProperty(int id) => remove(id);

  /// Fetch images for a property with a limit (no caching retained here)
  /// Defaults to fetching up to [maxImages] (10) most recently uploaded images.
  Future<List<model.Image>?> fetchPropertyImages(
    int propertyId, {
    int maxImages = 10,
  }) async {
    return executeWithState(() async {
      final params = {
        'propertyId': propertyId,
        'sortBy': 'dateuploaded',
        'sortDirection': 'desc',
        'page': 1,
        'pageSize': maxImages,
        'includeFull': true,
      };
      final endpoint = '/Images${api.buildQueryString(params)}';
      final images = await api.getListAndDecode(endpoint, model.Image.fromJson);
      return images;
    });
  }

  /// Fetch the current tenant summary for a property.
  /// Returns null if there is no active/current tenant (204 from API).
  Future<PropertyTenantSummary?> fetchCurrentTenantSummary(int propertyId) async {
    return executeWithState<PropertyTenantSummary?>(() async {
      final http.Response res = await api.get('/properties/$propertyId/current-tenant');
      if (res.statusCode == 204 || res.body.isEmpty) {
        return null;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return PropertyTenantSummary.fromJson(data);
    });
  }

  // Search method that accepts search parameters
  Future<List<Property>?> searchProperties({String? nameContains, String? city, double? minPrice, double? maxPrice}) async {
    final searchFilters = <String, dynamic>{};
    
    if (nameContains != null && nameContains.isNotEmpty) {
      searchFilters['nameContains'] = nameContains;
    }
    
    if (city != null && city.isNotEmpty) {
      searchFilters['city'] = city;
    }
    
    if (minPrice != null) {
      searchFilters['minPrice'] = minPrice;
    }
    
    if (maxPrice != null) {
      searchFilters['maxPrice'] = maxPrice;
    }
    
    return fetchList(filters: searchFilters);
  }

  // Mutators
  void select(Property? property) {
    _selected = property;
    notifyListeners();
  }

  void applyFilters(Map<String, dynamic> newFilters) {
    _filters = Map<String, dynamic>.from(newFilters)..removeWhere(
      (k, v) => v == null || (v is String && v.isEmpty),
    );
    notifyListeners();
  }

  void clearFilters() {
    _filters = {};
    notifyListeners();
  }

  // Queries

  /// Non-paged fetch, honoring current filters and optional sorting
  Future<List<Property>?> fetchList({Map<String, dynamic>? filters, String? sortBy, bool? ascending}) async {
    return executeWithState(() async {
      final params = <String, dynamic>{
        ..._filters,
        ...?filters,
        if (sortBy != null) 'sortBy': sortBy,
        if (ascending != null) 'sortDirection': ascending ? 'asc' : 'desc',
      };
      final endpoint = '/properties${api.buildQueryString(params)}';
      final list = await api.getListAndDecode(endpoint, Property.fromJson);
      _items = list;
      _paged = null;
      _sortBy = sortBy ?? _sortBy;
      _ascending = ascending ?? _ascending;
      return _items;
    });
  }

  /// Paged fetch using properties?page=&pageSize= and optional sorting
  Future<PagedResult<Property>?> fetchPaged({
    int? page,
    int? pageSize,
    Map<String, dynamic>? filters,
    String? sortBy,
    bool? ascending,
  }) async {
    final result = await executeWithState<PagedResult<Property>>(() async {
      _page = page ?? _page;
      _pageSize = pageSize ?? _pageSize;
      if (sortBy != null) _sortBy = sortBy;
      if (ascending != null) _ascending = ascending;

      final params = <String, dynamic>{
        ..._filters,
        ...?filters,
        'page': _page,
        'pageSize': _pageSize,
        if (_sortBy != null) 'sortBy': _sortBy,
        'sortDirection': _ascending ? 'asc' : 'desc',
      };

      final endpoint = 'properties${api.buildQueryString(params)}';
      final paged = await api.getPagedAndDecode(endpoint, Property.fromJson);
      // update local state
      _paged = paged;
      _items = paged.items;
      return paged;
    });
    return result;
  }

  Future<Property?> getById(int id) async {
    return executeWithState(() async {
      final p = await api.getAndDecode('/properties/$id', Property.fromJson);
      _selected = p;
      // Lazy-load reviews for detail view
      // Ignore errors here to not block the detail page
      // Will notify listeners separately
      unawaited(_safeLoadReviews(id));
      return p;
    });
  }

  Future<void> _safeLoadReviews(int propertyId) async {
    try {
      await fetchPropertyReviews(propertyId);
    } catch (_) {
      // swallow
    }
  }

  /// Fetch top-level reviews (and optionally their replies) for a property
  Future<List<Review>> fetchPropertyReviews(int propertyId, {bool includeReplies = false}) async {
    _isLoadingReviews[propertyId] = true;
    notifyListeners();
    try {
      final params = <String, dynamic>{
        'propertyId': propertyId,
        // top-level only; replies are loaded per parent if needed
        'parentReviewId': null,
        'sortBy': 'createdat',
        'sortDirection': 'desc',
        'pageSize': 50,
      }..removeWhere((k, v) => v == null);
      final endpoint = '/reviews${api.buildQueryString(params)}';
      final list = await api.getListAndDecode(endpoint, Review.fromJson);
      _propertyReviews[propertyId] = list.where((r) => r.parentReviewId == null).toList();
      notifyListeners();
      if (includeReplies) {
        // load replies per parent (best-effort, parallelized)
        for (final parent in _propertyReviews[propertyId]!) {
          unawaited(fetchReplies(parent.reviewId));
        }
      }
      return _propertyReviews[propertyId]!;
    } finally {
      _isLoadingReviews[propertyId] = false;
      notifyListeners();
    }
  }

  /// Fetch replies for a given review thread
  Future<List<Review>> fetchReplies(int parentReviewId) async {
    final params = <String, dynamic>{
      'parentReviewId': parentReviewId,
      'sortBy': 'createdat',
      'sortDirection': 'asc',
      'pageSize': 100,
    };
    final endpoint = '/reviews${api.buildQueryString(params)}';
    final replies = await api.getListAndDecode(endpoint, Review.fromJson);
    // Merge into cached list if present
    final propertyId = _selected?.propertyId;
    if (propertyId != null && _propertyReviews[propertyId] != null) {
      _propertyReviews[propertyId] = _propertyReviews[propertyId]!
          .map((r) => r.reviewId == parentReviewId
              ? Review(
                  reviewId: r.reviewId,
                  reviewType: r.reviewType,
                  propertyId: r.propertyId,
                  revieweeId: r.revieweeId,
                  reviewerId: r.reviewerId,
                  description: r.description,
                  starRating: r.starRating,
                  bookingId: r.bookingId,
                  parentReviewId: r.parentReviewId,
                  createdAt: r.createdAt,
                  updatedAt: r.updatedAt,
                  createdBy: r.createdBy,
                  modifiedBy: r.modifiedBy,
                  property: r.property,
                  booking: r.booking,
                  reviewer: r.reviewer,
                  reviewee: r.reviewee,
                  parentReview: r.parentReview,
                  replies: replies,
                )
              : r)
          .toList();
      notifyListeners();
    }
    return replies;
  }

  /// Post a reply to a review thread
  Future<Review?> replyToReview({
    required int parentReviewId,
    required String description,
  }) async {
    return executeWithRetry<Review?>(
      () async {
        final body = {
          'reviewType': 'ResponseReview',
          'description': description,
          'parentReviewId': parentReviewId,
          // reviewerId, revieweeId resolved by API from auth where applicable
        };
        final created = await api.postAndDecode('/reviews', body, Review.fromJson);
        // refresh replies for this thread
        await fetchReplies(parentReviewId);
        return created;
      },
      isUpdate: true,
    );
  }

  Future<Property?> create(Property dto) async {
    return executeWithRetry<Property>(() async {
      final created = await api.postAndDecode('/properties', dto.toRequestJson(), Property.fromJson);
      // optimistic local append
      _items = [..._items, created];
      // Safely adjust paged state if present (no copyWith dependency)
      if (_paged != null) {
        _paged = PagedResult<Property>(
          items: [..._items],
          totalCount: (_paged!.totalCount + 1),
          page: _paged!.page,
          pageSize: _paged!.pageSize,
        );
      }
      notifyListeners();
      return created;
    }, isUpdate: true);
  }

  Future<Property?> update(Property dto) async {
    return executeWithRetry<Property>(() async {
      final updated = await api.putAndDecode('/properties/${dto.propertyId}', dto.toRequestJson(), Property.fromJson);
      _items = _items.map((e) => e.propertyId == dto.propertyId ? updated : e).toList();
      if (_paged != null) {
        _paged = PagedResult<Property>(
          items: [..._items],
          totalCount: _paged!.totalCount,
          page: _paged!.page,
          pageSize: _paged!.pageSize,
        );
      }
      if (_selected?.propertyId == dto.propertyId) {
        _selected = updated;
      }
      notifyListeners();
      return updated;
    }, isUpdate: true);
  }

  Future<Property?> updatePropertyStatus(int propertyId, PropertyStatusUpdateRequest request) async {
    return executeWithRetry<Property>(() async {
      final updated = await api.putAndDecode('/properties/$propertyId/status', request.toJson(), Property.fromJson);
      _items = _items.map((e) => e.propertyId == propertyId ? updated : e).toList();
      if (_paged != null) {
        _paged = PagedResult<Property>(
          items: [..._items],
          totalCount: _paged!.totalCount,
          page: _paged!.page,
          pageSize: _paged!.pageSize,
        );
      }
      if (_selected?.propertyId == propertyId) {
        _selected = updated;
      }
      notifyListeners();
      
      // Check if this was a status change that might trigger refunds
      if ((request.status == 'Unavailable' || request.status == 'UnderMaintenance') && 
          _selected?.rentingType == 'Daily') {
        // In a real implementation, we would listen for refund notifications from the backend
        // For now, we'll just show a message that refunds may be processed
        // In a production app, this would be handled by a notification service
      }
      
      return updated;
    }, isUpdate: true);
  }

  Future<bool> remove(int id) async {
    return await executeWithStateForSuccess(() async {
      final ok = await api.deleteAndConfirm('/properties/$id');
      if (!ok) throw AppError.server('Delete failed');
      _items = _items.where((e) => e.propertyId != id).toList();
      if (_paged != null) {
        final newTotal = (_paged!.totalCount - 1);
        _paged = PagedResult<Property>(
          items: [..._items],
          totalCount: newTotal < 0 ? 0 : newTotal,
          page: _paged!.page,
          pageSize: _paged!.pageSize,
        );
      }
      if (_selected?.propertyId == id) {
        _selected = null;
      }
      notifyListeners();
    }, isUpdate: true);
  }

  Future<void> refresh() async {
    if (isLoading || isRefreshing) return;
    if (_paged != null) {
      await fetchPaged(
        page: _page,
        pageSize: _pageSize,
        filters: _filters,
        sortBy: _sortBy,
        ascending: _ascending,
      );
    } else {
      await fetchList(filters: _filters, sortBy: _sortBy, ascending: _ascending);
    }
  }
}

/// Property form provider kept minimal, reusing main provider behavior if desired
class PropertyFormProvider extends BaseProvider {
  PropertyFormProvider(super.api);

  Future<Property?> loadProperty(int id) async {
    return executeWithState(() async {
      return await api.getAndDecode('/properties/$id', Property.fromJson);
    });
  }

  Future<Property?> saveProperty(Property property) async {
    if (property.propertyId == 0) {
      return executeWithRetry<Property>(() async {
        return await api.postAndDecode('/properties', property.toJson(), Property.fromJson);
      }, isUpdate: true);
    } else {
      return executeWithRetry<Property>(() async {
        return await api.putAndDecode('/properties/${property.propertyId}', property.toJson(), Property.fromJson);
      }, isUpdate: true);
    }
  }
}