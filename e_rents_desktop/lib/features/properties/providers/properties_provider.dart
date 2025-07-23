import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../models/paged_result.dart';
import '../../../models/property.dart';
import '../../../models/review.dart';
import '../../../models/booking_summary.dart';
import '../../../models/property_stats_data.dart';
import '../../../services/api_service.dart';
import '../../maintenance/providers/maintenance_provider.dart';

/// Unified Properties Provider - Consolidates all property-related functionality
///
/// This provider follows the new architecture pattern by:
/// - Extending ChangeNotifier for state management
/// - Making direct API calls using ApiService
/// - Handling all property CRUD operations
/// - Managing property statistics and analytics
/// - Simple in-memory caching with TTL
/// - Consolidating functionality from PropertyProvider, PropertyStatsProvider, and related services
class PropertiesProvider extends ChangeNotifier {
  final ApiService _api;
  final MaintenanceProvider _maintenanceProvider;

  PropertiesProvider(this._api, this._maintenanceProvider);

  // ─── API Access ────────────────────────────────────────────────────────
  ApiService get apiService => _api;

  // ─── Core State ─────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

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

  bool get canReplyToReviews => true; // Based on user permissions

  // ─── Statistics State ──────────────────────────────────────────────────
  PropertyStatsData? _statsData;
  PropertyStatsData? get statsData => _statsData;

  bool _isStatsLoading = false;
  bool get isStatsLoading => _isStatsLoading;

  String? _statsError;
  String? get statsError => _statsError;

  String? _currentStatsPropertyId;
  String? get currentStatsPropertyId => _currentStatsPropertyId;

  // ─── Simple Caching ────────────────────────────────────────────────────
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  bool _isCacheValid(String key, Duration ttl) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < ttl;
  }

  void _setCache(String key, dynamic value, Duration ttl) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  T? _getCache<T>(String key, Duration ttl) {
    if (_isCacheValid(key, ttl)) {
      return _cache[key] as T?;
    }
    return null;
  }

  void _clearCache([String? key]) {
    if (key != null) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
    }
  }

  // ─── Properties API Methods ────────────────────────────────────────────
  
  /// Get paginated properties with filtering
  Future<void> getPagedProperties({Map<String, dynamic>? params}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Build cache key for this request
      final cacheKey = 'paged_properties_${params?.toString() ?? 'default'}';
      
      // Check cache first (5 minute TTL)
      final cached = _getCache<PagedResult<Property>>(cacheKey, const Duration(minutes: 5));
      if (cached != null) {
        _pagedResult = cached;
        _properties = cached.items;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Ensure default parameters for inclusion are set
      final queryParams = {
        'IncludeImages': 'true',
        'IncludeAmenities': 'true',
        'IncludeOwner': 'true',
        'IncludePropertyType': 'true',
        'IncludeRentingType': 'true',
        ...?params,
      };

      // Convert all query param values to strings for the URI
      final stringQueryParams =
          queryParams.map((key, value) => MapEntry(key, value.toString()));

      final endpoint = '/properties?${Uri(queryParameters: stringQueryParams).query}';

      final response = await _api.get(endpoint);
      final data = json.decode(response.body) as Map<String, dynamic>;

      final itemsJson = data['items'] as List<dynamic>? ?? [];
      final properties =
          itemsJson.map((json) => Property.fromJson(json)).toList();

      _pagedResult = PagedResult<Property>(
        items: properties,
        totalCount: data['totalCount'] ?? 0,
        page: (data['page'] ?? 1) - 1, // API is 1-based, UI is 0-based
        pageSize: data['pageSize'] ?? 10,
      );

      _properties = _pagedResult!.items;
      
      // Cache the result
      _setCache(cacheKey, _pagedResult, const Duration(minutes: 5));
      
    } catch (e) {
      _error = 'Failed to load properties: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get property by ID with caching
  Future<void> getPropertyById(String propertyId, {bool forceRefresh = false}) async {
    final cacheKey = 'property_$propertyId';
    
    if (!forceRefresh) {
      // Check if already loaded in selected property
      if (_selectedProperty != null &&
          _selectedProperty!.propertyId.toString() == propertyId) {
        return;
      }
      
      // Check cache
      final cached = _getCache<Property>(cacheKey, const Duration(minutes: 10));
      if (cached != null) {
        _selectedProperty = cached;
        notifyListeners();
        return;
      }
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = {
        'IncludeImages': 'true',
        'IncludeAmenities': 'true',
        'IncludeOwner': 'true',
        'IncludePropertyType': 'true',
        'IncludeRentingType': 'true',
        'IncludeReviews': 'true',
      };

      final endpoint =
          '/properties/$propertyId?${Uri(queryParameters: params).query}';

      final response = await _api.get(endpoint);
      final data = json.decode(response.body) as Map<String, dynamic>;

      _selectedProperty = Property.fromJson(data);
      
      // Cache the property
      _setCache(cacheKey, _selectedProperty, const Duration(minutes: 10));
      
      // Also load reviews for this property
      await _fetchReviews(propertyId, initialLoad: true);
      
    } catch (e) {
      _error = 'Failed to load property: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save property (create or update)
  Future<bool> saveProperty(
    Property property, {
    List<Uint8List>? newImageData,
    List<String>? newImageFileNames,
    List<int>? existingImageIds,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final isUpdate = property.propertyId > 0;
      final endpoint = isUpdate 
          ? '/properties/${property.propertyId}'
          : '/properties';

      // Build multipart request
      final request = http.MultipartRequest(
        isUpdate ? 'PUT' : 'POST',
        Uri.parse('${_api.baseUrl}$endpoint'),
      );

      // Add auth headers
      final token = await _api.secureStorageService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add property fields
      final fields = await _buildPropertyFields(property);
      request.fields.addAll(fields);

      // Add existing image IDs
      if (existingImageIds != null && existingImageIds.isNotEmpty) {
        for (int i = 0; i < existingImageIds.length; i++) {
          request.fields['ExistingImageIds[$i]'] = existingImageIds[i].toString();
        }
      }

      // Add new image files
      if (newImageData != null && newImageData.isNotEmpty) {
        final imageFiles = _buildImageFiles(newImageData, newImageFileNames);
        request.files.addAll(imageFiles);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(response.body);
        final savedProperty = Property.fromJson(responseData);

        // Update local state
        if (isUpdate) {
          final index = _properties.indexWhere(
              (p) => p.propertyId == savedProperty.propertyId);
          if (index != -1) {
            _properties[index] = savedProperty;
          }
        } else {
          _properties.insert(0, savedProperty);
        }

        _selectedProperty = savedProperty;
        
        // Clear related caches
        _clearCache('property_${savedProperty.propertyId}');
        _clearCache(); // Clear all paged results cache
        
        return true;
      } else {
        _error = 'Failed to save property: ${response.body}';
        return false;
      }
    } catch (e) {
      _error = 'Failed to save property: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete property
  Future<bool> deleteProperty(String propertyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.delete('/properties/$propertyId');

      // Update local state
      _properties.removeWhere((p) => p.propertyId.toString() == propertyId);
      if (_pagedResult != null) {
        final updatedItems = _pagedResult!.items
            .where((p) => p.propertyId.toString() != propertyId)
            .toList();

        _pagedResult = PagedResult(
          items: updatedItems,
          totalCount: _pagedResult!.totalCount - 1,
          page: _pagedResult!.page,
          pageSize: _pagedResult!.pageSize,
        );
      }

      // Clear caches
      _clearCache('property_$propertyId');
      _clearCache(); // Clear all paged results cache

      return true;
    } catch (e) {
      _error = 'Failed to delete property: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Reviews API Methods ───────────────────────────────────────────────

  /// Fetch reviews for a property
  Future<void> _fetchReviews(String propertyId, {bool initialLoad = false}) async {
    if (initialLoad) {
      _reviews.clear();
      _reviewsPage = 0;
      _hasMoreReviews = true;
      _totalReviewCount = 0;
    }

    _areReviewsLoading = true;
    _reviewsError = null;
    notifyListeners();

    try {
      final response = await _api.get(
        '/reviews/$propertyId/paged?page=${_reviewsPage + 1}&pageSize=$_reviewsPageSize',
      );
      
      final data = json.decode(response.body) as Map<String, dynamic>;
      final itemsJson = data['items'] as List<dynamic>? ?? [];
      final newReviews = itemsJson.map((json) => Review.fromJson(json)).toList();

      if (initialLoad) {
        _reviews = newReviews;
      } else {
        _reviews.addAll(newReviews);
      }

      _totalReviewCount = data['totalCount'] ?? 0;
      _hasMoreReviews = newReviews.length == _reviewsPageSize;
      _reviewsPage++;

    } catch (e) {
      _reviewsError = 'Failed to load reviews: $e';
    } finally {
      _areReviewsLoading = false;
      notifyListeners();
    }
  }

  /// Load more reviews
  Future<void> loadMoreReviews() async {
    if (_selectedProperty != null && _hasMoreReviews && !_areReviewsLoading) {
      await _fetchReviews(_selectedProperty!.propertyId.toString());
    }
  }

  /// Submit reply to review
  Future<void> submitReply(String reviewId, String replyText) async {
    try {
      final request = {
        'parentReviewId': int.parse(reviewId),
        'description': replyText,
        'reviewType': 'PropertyReview',
      };

      final response = await _api.post('/reviews', request);
      final responseData = json.decode(response.body);
      final newReply = Review.fromJson(responseData);

      // Add reply to local state
      _reviews.add(newReply);
      notifyListeners();

    } catch (e) {
      _error = 'Failed to submit reply: $e';
      notifyListeners();
    }
  }

  // ─── Statistics API Methods ────────────────────────────────────────────

  /// Load comprehensive property statistics
  Future<void> loadPropertyStats(String propertyId, {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        !_isStatsLoading &&
        _statsData != null &&
        _currentStatsPropertyId == propertyId) {
      return;
    }

    _isStatsLoading = true;
    _statsError = null;
    _currentStatsPropertyId = propertyId;
    notifyListeners();

    try {
      // Load all stats concurrently
      final futures = await Future.wait([
        _loadBookingStats(propertyId),
        _loadReviewStats(propertyId),
        _loadCurrentBookings(propertyId),
        _loadUpcomingBookings(propertyId),
        _loadMaintenanceIssues(propertyId),
      ]);

      final bookingStats = futures[0] as PropertyBookingStats?;
      final reviewStats = futures[1] as PropertyReviewStats?;
      final currentBookings = futures[2] as List<BookingSummary>;
      final upcomingBookings = futures[3] as List<BookingSummary>;
      final maintenanceIssues = futures[4] as List<dynamic>;

      // Derive financial and occupancy stats from booking stats
      final financialStats = _deriveFinancialStats(bookingStats);
      final occupancyStats = _deriveOccupancyStats(bookingStats);

      _statsData = PropertyStatsData(
        propertyId: propertyId,
        bookingStats: bookingStats,
        reviewStats: reviewStats,
        financialStats: financialStats,
        occupancyStats: occupancyStats,
        currentBookings: currentBookings,
        upcomingBookings: upcomingBookings,
        maintenanceIssues: maintenanceIssues.cast(),
        lastUpdated: DateTime.now(),
      );

    } catch (e) {
      _statsError = 'Failed to load property statistics: $e';
    } finally {
      _isStatsLoading = false;
      notifyListeners();
    }
  }

  /// Load booking statistics for property
  Future<PropertyBookingStats?> _loadBookingStats(String propertyId) async {
    try {
      final cacheKey = 'booking_stats_$propertyId';
      final cached = _getCache<PropertyBookingStats>(cacheKey, const Duration(minutes: 15));
      if (cached != null) return cached;

      // Get all bookings for the property
      final allBookingsResponse = await _api.get('/bookings?propertyId=$propertyId&noPaging=true');
      final allBookingsData = json.decode(allBookingsResponse.body);
      final allBookingsItems = (allBookingsData['items'] as List<dynamic>?) ?? [];

      // Get current bookings
      final currentBookingsResponse = await _api.get('/bookings/current?propertyId=$propertyId');
      final currentBookingsData = json.decode(currentBookingsResponse.body) as List<dynamic>;

      // Calculate stats
      final totalBookings = allBookingsItems.length;
      final totalRevenue = allBookingsItems.fold<double>(0.0, (sum, booking) => 
          sum + (booking['totalPrice'] as num).toDouble());
      final averageBookingValue = totalBookings > 0 ? totalRevenue / totalBookings : 0.0;
      final currentOccupancy = currentBookingsData.length;
      final occupancyRate = currentOccupancy > 0 ? 1.0 : 0.0; // Simplified calculation

      final stats = PropertyBookingStats(
        totalBookings: totalBookings,
        totalRevenue: totalRevenue,
        averageBookingValue: averageBookingValue,
        currentOccupancy: currentOccupancy,
        occupancyRate: occupancyRate,
      );

      _setCache(cacheKey, stats, const Duration(minutes: 15));
      return stats;
    } catch (e) {
      debugPrint('Error loading booking stats: $e');
      return null;
    }
  }

  /// Load review statistics for property
  Future<PropertyReviewStats?> _loadReviewStats(String propertyId) async {
    try {
      final cacheKey = 'review_stats_$propertyId';
      final cached = _getCache<PropertyReviewStats>(cacheKey, const Duration(minutes: 10));
      if (cached != null) return cached;

      final response = await _api.get('/properties/$propertyId/review-stats');
      final data = json.decode(response.body) as Map<String, dynamic>;
      final stats = PropertyReviewStats.fromJson(data);

      _setCache(cacheKey, stats, const Duration(minutes: 10));
      return stats;
    } catch (e) {
      debugPrint('Error loading review stats: $e');
      return null;
    }
  }

  /// Load current bookings for property
  Future<List<BookingSummary>> _loadCurrentBookings(String propertyId) async {
    try {
      final response = await _api.get('/bookings/current?propertyId=$propertyId');
      final data = json.decode(response.body) as List<dynamic>;
      return data.map((json) => BookingSummary.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading current bookings: $e');
      return [];
    }
  }

  /// Load upcoming bookings for property
  Future<List<BookingSummary>> _loadUpcomingBookings(String propertyId) async {
    try {
      final response = await _api.get('/bookings/upcoming?propertyId=$propertyId');
      final data = json.decode(response.body) as List<dynamic>;
      return data.map((json) => BookingSummary.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading upcoming bookings: $e');
      return [];
    }
  }

  /// Load maintenance issues for property
  Future<List<dynamic>> _loadMaintenanceIssues(String propertyId) async {
    try {
      await _maintenanceProvider.getPaged(params: {'propertyId': propertyId});
      return _maintenanceProvider.pagedResult.items;
    } catch (e) {
      debugPrint('Error loading maintenance issues: $e');
      return [];
    }
  }

  /// Derive financial stats from booking stats
  PropertyFinancialStats? _deriveFinancialStats(PropertyBookingStats? bookingStats) {
    if (bookingStats == null) return null;
    return PropertyFinancialStats(
      monthlyRevenue: bookingStats.totalRevenue / 12, // Rough monthly estimate
      yearlyRevenue: bookingStats.totalRevenue,
      averageNightlyRate: bookingStats.averageBookingValue,
      profitMargin: 0.0, // Placeholder
      lastMonthRevenue: 0.0, // Placeholder
      revenueGrowth: 0.0, // Placeholder
    );
  }

  /// Derive occupancy stats from booking stats
  PropertyOccupancyStats? _deriveOccupancyStats(PropertyBookingStats? bookingStats) {
    if (bookingStats == null) return null;
    return PropertyOccupancyStats(
      currentOccupancyRate: bookingStats.occupancyRate,
      monthlyOccupancyRate: bookingStats.occupancyRate, // Placeholder
      yearlyOccupancyRate: bookingStats.occupancyRate, // Placeholder
      averageStayDuration: 0.0, // Placeholder
      totalNightsBooked: 0, // Placeholder
      totalNightsAvailable: 0, // Placeholder
    );
  }

  /// Refresh stats for current property
  Future<void> refreshStats() async {
    if (_currentStatsPropertyId != null) {
      await loadPropertyStats(_currentStatsPropertyId!, forceRefresh: true);
    }
  }

  /// Clear current stats
  void clearStats() {
    _currentStatsPropertyId = null;
    _statsData = null;
    notifyListeners();
  }

  // ─── Convenience Getters for Statistics ────────────────────────────────

  /// Get total bookings safely
  int get totalBookings => _statsData?.bookingStats?.totalBookings ?? 0;

  /// Get total revenue safely
  double get totalRevenue => _statsData?.bookingStats?.totalRevenue ?? 0.0;

  /// Get average rating safely
  double get averageRating => _statsData?.reviewStats?.averageRating ?? 0.0;

  /// Get total reviews safely
  int get totalReviews => _statsData?.reviewStats?.totalReviews ?? 0;

  /// Get occupancy rate safely
  double get occupancyRate => _statsData?.bookingStats?.occupancyRate ?? 0.0;

  /// Get current bookings safely
  List<BookingSummary> get currentBookings => _statsData?.currentBookings ?? [];

  /// Get upcoming bookings safely
  List<BookingSummary> get upcomingBookings => _statsData?.upcomingBookings ?? [];

  // ─── Utility Methods ───────────────────────────────────────────────────

  /// Clear error state
  void clearError() {
    _error = null;
    _reviewsError = null;
    _statsError = null;
    notifyListeners();
  }

  /// Build image files for multipart request
  List<http.MultipartFile> _buildImageFiles(
    List<Uint8List>? imageData,
    List<String>? imageFileNames,
  ) {
    final files = <http.MultipartFile>[];
    if (imageData != null && imageData.isNotEmpty) {
      for (int i = 0; i < imageData.length; i++) {
        final fileName = (imageFileNames != null && i < imageFileNames.length)
            ? imageFileNames[i]
            : 'image_$i.jpg';

        files.add(
          http.MultipartFile.fromBytes(
            'NewImages',
            imageData[i],
            filename: fileName,
          ),
        );
      }
    }
    return files;
  }

  /// Build property fields for API request
  Future<Map<String, String>> _buildPropertyFields(Property property) async {
    final fields = <String, String>{};

    if (property.name.isNotEmpty) fields['Name'] = property.name;
    fields['Price'] = property.price.toString();
    fields['Currency'] = property.currency;
    if (property.description.isNotEmpty) fields['Description'] = property.description;
    fields['Bedrooms'] = property.bedrooms.toString();
    fields['Bathrooms'] = property.bathrooms.toString();
    if (property.area > 0) fields['Area'] = property.area.toString();
    if (property.minimumStayDays != null && property.minimumStayDays! > 0) {
      fields['MinimumStayDays'] = property.minimumStayDays.toString();
    }
    if (property.status != null && property.status!.isNotEmpty) {
      fields['Status'] = property.status!;
    }
    if (property.propertyTypeId != null) {
      fields['PropertyTypeId'] = property.propertyTypeId.toString();
    }
    if (property.rentingTypeId != null) {
      fields['RentingTypeId'] = property.rentingTypeId.toString();
    }

    // Handle Address
    if (property.address != null && !property.address!.isEmpty) {
      final address = property.address!;
      if (address.streetLine1?.isNotEmpty == true) fields['Address.StreetLine1'] = address.streetLine1!;
      if (address.streetLine2?.isNotEmpty == true) fields['Address.StreetLine2'] = address.streetLine2!;
      if (address.city?.isNotEmpty == true) fields['Address.City'] = address.city!;
      if (address.state?.isNotEmpty == true) fields['Address.State'] = address.state!;
      if (address.postalCode?.isNotEmpty == true) fields['Address.PostalCode'] = address.postalCode!;
      if (address.country?.isNotEmpty == true) fields['Address.Country'] = address.country!;
      if (address.latitude != null) fields['Address.Latitude'] = address.latitude.toString();
      if (address.longitude != null) fields['Address.Longitude'] = address.longitude.toString();
    }

    // Handle Amenity IDs
    for (int i = 0; i < property.amenityIds.length; i++) {
      fields['AmenityIds[$i]'] = property.amenityIds[i].toString();
    }

    return fields;
  }
}
