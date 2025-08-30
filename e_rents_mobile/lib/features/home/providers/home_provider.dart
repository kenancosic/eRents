import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/models/user.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';

/// Home dashboard provider for managing user data and property listings
/// Refactored to use new standardized BaseProvider without caching
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
    // Simply reload all data without caching
    await initializeDashboard();
  }

  Future<void> _loadCurrentUser() async {
    final user = await executeWithState(() async {
      return await api.getAndDecode('profile/me', User.fromJson, authenticated: true);
    });
    
    if (user != null) {
      _currentUser = user;
    }
  }

  Future<void> _loadUserBookings() async {
    final results = await executeWithState(() async {
      return await Future.wait([
        api.getListAndDecode('bookings/current', Booking.fromJson, authenticated: true),
        api.getListAndDecode('bookings/upcoming', Booking.fromJson, authenticated: true),
      ]);
    });
    
    if (results != null) {
      _currentStays = results[0];
      _upcomingStays = results[1];
    }
  }

  Future<void> _loadNearbyProperties() async {
    final filters = <String, dynamic>{'PageSize': '5'};
    if (_currentUser?.address?.city != null) {
      filters['City'] = _currentUser!.address!.city!;
    }
    
    final queryString = api.buildQueryString(filters);
    final pagedResult = await executeWithState(() async {
      return await api.getPagedAndDecode(
        'properties/search$queryString', 
        Property.fromJson,
      );
    });
    
    if (pagedResult != null) {
      _nearbyProperties = pagedResult.items;
    }
  }

  Future<void> _loadRecommendedProperties() async {
    final filters = <String, dynamic>{
      'IsRecommended': 'true',
      'PageSize': '6',
      'SortBy': 'rating',
    };
    
    final queryString = api.buildQueryString(filters);
    final pagedResult = await executeWithState(() async {
      return await api.getPagedAndDecode(
        'properties/search$queryString',
        Property.fromJson,
      );
    });
    
    if (pagedResult != null) {
      _recommendedProperties = pagedResult.items;
    }
  }

  Future<void> _loadFeaturedProperties() async {
    final filters = <String, dynamic>{
      'IsFeatured': 'true',
      'PageSize': '8',
      'SortBy': 'popularity',
    };
    
    final queryString = api.buildQueryString(filters);
    final pagedResult = await executeWithState(() async {
      return await api.getPagedAndDecode(
        'properties/search$queryString',
        Property.fromJson,
      );
    });
    
    if (pagedResult != null) {
      _featuredProperties = pagedResult.items;
    }
  }

  Future<void> searchProperties(String query) async {
    if (query.trim().isEmpty) {
      await _loadFeaturedProperties();
      return;
    }

    final filters = <String, dynamic>{
      'Query': query,
      'PageSize': '8',
    };
    
    final queryString = api.buildQueryString(filters);
    final pagedResult = await executeWithState(() async {
      return await api.getPagedAndDecode(
        'properties/search$queryString',
        Property.fromJson,
      );
    });
    
    if (pagedResult != null) {
      _featuredProperties = pagedResult.items;
    }
  }

  Future<void> applyPropertyFilters(Map<String, dynamic> filters) async {
    final searchFilters = Map<String, dynamic>.from(filters);
    searchFilters['IsFeatured'] = 'true';
    
    final queryString = api.buildQueryString(searchFilters);
    final pagedResult = await executeWithState(() async {
      return await api.getPagedAndDecode(
        'properties/search$queryString',
        Property.fromJson,
      );
    });
    
    if (pagedResult != null) {
      _featuredProperties = pagedResult.items;
    }
  }
}
