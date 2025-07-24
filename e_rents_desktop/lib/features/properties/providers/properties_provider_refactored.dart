import 'dart:typed_data';

import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/paged_result.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/models/booking_summary.dart';
import 'package:e_rents_desktop/models/property_stats_data.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';

/// Refactored Properties Provider using the new base architecture.
///
/// This provider consolidates all property-related functionality and leverages
/// [BaseProvider] for state management, caching, and simplified API calls.
class PropertiesProviderRefactored extends BaseProvider {
  PropertiesProviderRefactored(super.api);

  // ─── Properties State ──────────────────────────────────────────────────
  List<Property> _properties = [];
  List<Property> get properties => _properties;

  PagedResult<Property>? _pagedResult;
  PagedResult<Property>? get pagedResult => _pagedResult;

  Property? _selectedProperty;
  Property? get selectedProperty => _selectedProperty;

  // ─── Reviews State ─────────────────────────────────────────────────────
  List<Review> _reviews = [];
  List<Review> get reviews => _reviews;

  bool _areReviewsLoading = false;
  bool get areReviewsLoading => _areReviewsLoading;

  String? _reviewsError;
  String? get reviewsError => _reviewsError;

  int _reviewsPage = 0;
  final int _reviewsPageSize = 5;
  bool _hasMoreReviews = true;
  bool get hasMoreReviews => _hasMoreReviews;

  int _totalReviewCount = 0;
  int get totalReviewCount => _totalReviewCount;

  // ─── Statistics State ──────────────────────────────────────────────────
  PropertyStatsData? _statsData;
  PropertyStatsData? get statsData => _statsData;

  String? _currentStatsPropertyId;

  // ─── Public API ────────────────────────────────────────────────────────

  /// Get paginated properties with filtering.
  Future<void> getPagedProperties({Map<String, dynamic>? params}) async {
    final result = await executeWithState<PagedResult<Property>>(() async {
      return await api.getPagedAndDecode(
        '/properties/paged${api.buildQueryString(params)}',
        Property.fromJson,
        authenticated: true,
      );
    });
    
    if (result != null) {
      _pagedResult = result;
      _properties = result.items;
      notifyListeners();
    }
  }

  /// Get property by ID, using cache first.
  Future<void> getPropertyById(String propertyId, {bool forceRefresh = false}) async {
    final cacheKey = 'property_$propertyId';
    
    if (forceRefresh) {
      invalidateCache(cacheKey);
    }
    
    final result = await executeWithCache<Property>(
      cacheKey,
      () => api.getAndDecode('/properties/$propertyId', Property.fromJson, authenticated: true),
    );
    
    if (result != null) {
      _selectedProperty = result;
      notifyListeners();
    }
  }

  /// Save property (create or update).
  Future<bool> saveProperty(
    Property property, {
    List<Uint8List>? newImageData,
    List<String>? newImageFileNames,
    List<int>? existingImageIds,
  }) async {
    setError('Multipart file upload functionality not yet implemented in base provider');
    return false;
  }

  /// Delete property.
  Future<bool> deleteProperty(String propertyId) async {
    final result = await executeWithState<bool>(() async {
      return await api.deleteAndConfirm('/properties/$propertyId', authenticated: true);
    });
    
    if (result == true) {
      _properties.removeWhere((p) => p.id == propertyId);
      if (_selectedProperty?.id == propertyId) {
        _selectedProperty = null;
      }
      invalidateCache('property_$propertyId');
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Fetch reviews for a property.
  Future<void> fetchReviews(String propertyId, {bool initialLoad = false}) async {
    if (initialLoad) {
      _reviews = [];
      _reviewsPage = 0;
      _hasMoreReviews = true;
    }

    if (_areReviewsLoading || !_hasMoreReviews) return;

    _areReviewsLoading = true;
    _reviewsError = null;
    notifyListeners();

    try {
      final params = {'page': _reviewsPage, 'pageSize': _reviewsPageSize};
      final result = await apiService.getPaged<Review>(
        'properties/$propertyId/reviews',
        params: params,
        fromJson: Review.fromJson,
      );

      _reviews.addAll(result.items);
      _totalReviewCount = result.totalCount;
      _hasMoreReviews = result.items.length == _reviewsPageSize;
      _reviewsPage++;
    } catch (e) {
      _reviewsError = e.toString();
    } finally {
      _areReviewsLoading = false;
      notifyListeners();
    }
  }

  /// Load comprehensive property statistics, using cache first.
  Future<void> loadPropertyStats(String propertyId, {bool forceRefresh = false}) async {
    _currentStatsPropertyId = propertyId;
    final cacheKey = 'stats_$propertyId';
    
    if (forceRefresh) {
      invalidateCache(cacheKey);
    }
    
    final result = await executeWithCache<PropertyStatsData>(
      cacheKey,
      () => api.getAndDecode('/properties/$propertyId/stats', PropertyStatsData.fromJson, authenticated: true),
    );
    
    if (result != null) {
      _statsData = result;
      notifyListeners();
    }
  }

  // ─── Helper and Private Methods ────────────────────────────────────────
  // Note: _buildPropertyFields method removed as it's not used after refactoring
  // to use the base provider architecture. Multipart form handling would need
  // to be implemented in the ApiService if needed.

  // ─── Computed Properties and Getters ───────────────────────────────────

  bool get isStatsLoading => isLoading;
  String? get statsError => error;

  int get totalBookings => _statsData?.bookingStats?.totalBookings ?? 0;
  double get totalRevenue => _statsData?.bookingStats?.totalRevenue ?? 0.0;
  double get averageRating => _statsData?.reviewStats?.averageRating ?? 0.0;
  int get totalReviews => _statsData?.reviewStats?.totalReviews ?? 0;
  double get occupancyRate => _statsData?.bookingStats?.occupancyRate ?? 0.0;
  List<BookingSummary> get currentBookings => _statsData?.currentBookings ?? [];
  List<BookingSummary> get upcomingBookings => _statsData?.upcomingBookings ?? [];
}
