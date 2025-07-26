import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/models/user.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';

class HomeProvider extends BaseProvider {
  HomeProvider(super.api);

  // Data state
  User? _currentUser;
  List<Booking> _currentStays = [];
  List<Booking> _upcomingStays = [];
  List<Property> _nearbyProperties = [];
  List<Property> _recommendedProperties = [];
  List<Property> _featuredProperties = [];

  // Getters
  User? get currentUser => _currentUser;
  List<Booking> get currentStays => _currentStays;
  List<Booking> get upcomingStays => _upcomingStays;
  List<Property> get nearbyProperties => _nearbyProperties;
  List<Property> get recommendedProperties => _recommendedProperties;
  List<Property> get featuredProperties => _featuredProperties;

  String get welcomeMessage {
    if (_currentUser?.firstName != null) {
      return 'Welcome back, ${_currentUser!.firstName}!';
    }
    return 'Welcome back!';
  }

  String get userLocation {
    if (_currentUser?.address?.city != null) {
      return _currentUser!.address!.city!;
    }
    return 'Unknown Location';
  }

  // --- Public Methods ---

  Future<void> initializeDashboard() async {
    await executeWithState(() async {
      await Future.wait([
        _loadCurrentUser(),
        _loadUserBookings(),
        _loadNearbyProperties(),
        _loadRecommendedProperties(),
        _loadFeaturedProperties(),
      ]);
    });
  }

  Future<void> refreshDashboard() async {
    // Invalidate all cache and reload
    invalidateCache();
    await initializeDashboard();
  }

  Future<void> _loadCurrentUser() async {
    _currentUser = await executeWithCache(
      'current_user',
      () => api.getAndDecode('profile/me', User.fromJson),
      cacheTtl: const Duration(minutes: 15),
      errorMessage: 'Failed to load user profile',
    );
  }

  Future<void> _loadUserBookings() async {
    final results = await Future.wait([
      executeWithCache(
        'current_bookings',
        () => api.getListAndDecode('bookings/current', Booking.fromJson),
        cacheTtl: const Duration(minutes: 5),
      ),
      executeWithCache(
        'upcoming_bookings',
        () => api.getListAndDecode('bookings/upcoming', Booking.fromJson),
        cacheTtl: const Duration(minutes: 5),
      ),
    ]);
    
    _currentStays = results[0] ?? [];
    _upcomingStays = results[1] ?? [];
  }

  Future<void> _loadNearbyProperties() async {
    final filters = <String, dynamic>{'PageSize': 5};
    if (_currentUser?.address?.city != null) {
      filters['City'] = _currentUser!.address!.city!;
    }
    
    final pagedResult = await executeWithCache(
      generateCacheKey('nearby_properties', filters),
      () => api.searchAndDecode('properties/search', Property.fromJson, filters: filters),
      cacheTtl: const Duration(minutes: 10),
    );
    
    _nearbyProperties = pagedResult?.items ?? [];
  }

  Future<void> _loadRecommendedProperties() async {
    final pagedResult = await executeWithCache(
      'recommended_properties',
      () => api.searchAndDecode(
        'properties/search',
        Property.fromJson,
        filters: {'IsRecommended': true},
        pageSize: 6,
        sortBy: 'rating',
      ),
      cacheTtl: const Duration(minutes: 15),
    );
    
    _recommendedProperties = pagedResult?.items ?? [];
  }

  Future<void> _loadFeaturedProperties() async {
    final pagedResult = await executeWithCache(
      'featured_properties',
      () => api.searchAndDecode(
        'properties/search',
        Property.fromJson,
        filters: {'IsFeatured': true},
        pageSize: 8,
        sortBy: 'popularity',
      ),
      cacheTtl: const Duration(minutes: 10),
    );
    
    _featuredProperties = pagedResult?.items ?? [];
  }

  Future<void> searchProperties(String query) async {
    if (query.trim().isEmpty) {
      await _loadFeaturedProperties();
      return;
    }

    final pagedResult = await executeWithState(() async {
      // Don't cache search results as they change frequently
      return api.searchAndDecode(
        'properties/search',
        Property.fromJson,
        query: query,
        pageSize: 8,
      );
    });
    
    _featuredProperties = pagedResult?.items ?? [];
  }

  Future<void> applyPropertyFilters(Map<String, dynamic> filters) async {
    final searchFilters = Map<String, dynamic>.from(filters);
    searchFilters['IsFeatured'] = true;
    
    final pagedResult = await executeWithState(() async {
      // Use cache for filtered results with TTL
      final cacheKey = generateCacheKey('filtered_properties', searchFilters);
      return getCachedOrExecute(
        cacheKey,
        () => api.searchAndDecode(
          'properties/search',
          Property.fromJson,
          filters: searchFilters,
        ),
        ttl: const Duration(minutes: 5),
      );
    });
    
    _featuredProperties = pagedResult?.items ?? [];
  }
}
