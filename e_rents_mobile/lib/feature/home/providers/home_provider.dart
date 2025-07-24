import 'dart:async';
import 'dart:convert';

import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/models/paged_list.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/models/user.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:flutter/material.dart';

class HomeProvider extends ChangeNotifier {
  final ApiService _apiService;

  HomeProvider(this._apiService);

  // Overall state
  bool _isLoading = false;
  String? _error;

  // User state
  User? _currentUser;
  bool _isUserLoading = false;
  String? _userError;

  // Bookings state
  List<Booking> _currentStays = [];
  List<Booking> _upcomingStays = [];
  bool _isBookingsLoading = false;
  String? _bookingsError;

  // Properties state
  List<Property> _nearbyProperties = [];
  List<Property> _recommendedProperties = [];
  List<Property> _featuredProperties = [];

  bool _isNearbyLoading = false;
  String? _nearbyError;

  bool _isRecommendedLoading = false;
  String? _recommendedError;

  bool _isFeaturedLoading = false;
  String? _featuredError;

  // --- Getters ---
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasError =>
      _userError != null ||
      _bookingsError != null ||
      _nearbyError != null ||
      _recommendedError != null ||
      _featuredError != null;

  String? get errorMessage =>
      _userError ??
      _bookingsError ??
      _nearbyError ??
      _recommendedError ??
      _featuredError;

  User? get currentUser => _currentUser;
  bool get isUserLoading => _isUserLoading;

  List<Booking> get currentStays => _currentStays;
  List<Booking> get upcomingStays => _upcomingStays;
  bool get isBookingsLoading => _isBookingsLoading;

  List<Property> get nearbyProperties => _nearbyProperties;
  List<Property> get recommendedProperties => _recommendedProperties;
  List<Property> get featuredProperties => _featuredProperties;

  bool get isNearbyLoading => _isNearbyLoading;
  String? get nearbyError => _nearbyError;
  bool get isRecommendedLoading => _isRecommendedLoading;
  String? get recommendedError => _recommendedError;
  bool get isFeaturedLoading => _isFeaturedLoading;
  String? get featuredError => _featuredError;

  String get welcomeMessage {
    final user = _currentUser;
    if (user?.firstName != null) {
      return 'Welcome back, ${user!.firstName}!';
    }
    return 'Welcome back!';
  }

  String get userLocation {
    final user = _currentUser;
    if (user?.address?.city != null) {
      return user!.address!.city!;
    }
    return 'Unknown Location';
  }

  // --- Public Methods ---

  Future<void> initializeDashboard() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      _loadCurrentUser(),
      _loadUserBookings(),
      _loadNearbyProperties(),
      _loadRecommendedProperties(),
      _loadFeaturedProperties(),
    ]);

    _isLoading = false;
    _error = errorMessage;
    notifyListeners();
  }

  Future<void> refreshDashboard() async {
    await initializeDashboard();
  }

  Future<void> _loadCurrentUser() async {
    _isUserLoading = true;
    _userError = null;
    notifyListeners();
    try {
      final response = await _apiService.get('profile/me');
      _currentUser = User.fromJson(jsonDecode(response.body));
    } catch (e) {
      _userError = e.toString();
    } finally {
      _isUserLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserBookings() async {
    _isBookingsLoading = true;
    _bookingsError = null;
    notifyListeners();
    try {
      final currentResponse = await _apiService.get('bookings/current');
      final upcomingResponse = await _apiService.get('bookings/upcoming');

      final currentData = jsonDecode(currentResponse.body) as List;
      final upcomingData = jsonDecode(upcomingResponse.body) as List;

      _currentStays = currentData.map((item) => Booking.fromJson(item)).toList();
      _upcomingStays = upcomingData.map((item) => Booking.fromJson(item)).toList();
    } catch (e) {
      _bookingsError = e.toString();
    } finally {
      _isBookingsLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadNearbyProperties() async {
    _isNearbyLoading = true;
    _nearbyError = null;
    notifyListeners();

    try {
      final params = <String, String>{'PageSize': '5'};
      if (_currentUser?.address?.city != null) {
        params['City'] = _currentUser!.address!.city!;
      }

      final uri = Uri.parse('properties/search').replace(queryParameters: params);
      final response = await _apiService.get(uri.toString());
      final data = jsonDecode(response.body);
      final pagedList = PagedList<Property>.fromJson(data, (json) => Property.fromJson(json));
      _nearbyProperties = pagedList.items;
    } catch (e) {
      _nearbyError = e.toString();
    } finally {
      _isNearbyLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadRecommendedProperties() async {
    _isRecommendedLoading = true;
    _recommendedError = null;
    notifyListeners();

    try {
      final uri = Uri.parse('properties/search').replace(queryParameters: {
        'IsRecommended': 'true',
        'PageSize': '6',
        'SortBy': 'rating',
      });
      final response = await _apiService.get(uri.toString());
      final data = jsonDecode(response.body);
      final pagedList = PagedList<Property>.fromJson(data, (json) => Property.fromJson(json));
      _recommendedProperties = pagedList.items;
    } catch (e) {
      _recommendedError = e.toString();
    } finally {
      _isRecommendedLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFeaturedProperties() async {
    _isFeaturedLoading = true;
    _featuredError = null;
    notifyListeners();

    try {
      final uri = Uri.parse('properties/search').replace(queryParameters: {
        'IsFeatured': 'true',
        'PageSize': '8',
        'SortBy': 'popularity',
      });
      final response = await _apiService.get(uri.toString());
      final data = jsonDecode(response.body);
      final pagedList = PagedList<Property>.fromJson(data, (json) => Property.fromJson(json));
      _featuredProperties = pagedList.items;
    } catch (e) {
      _featuredError = e.toString();
    } finally {
      _isFeaturedLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchProperties(String query) async {
    if (query.trim().isEmpty) {
      await _loadFeaturedProperties();
      return;
    }

    _isFeaturedLoading = true;
    _featuredError = null;
    notifyListeners();

    try {
      final uri = Uri.parse('properties/search').replace(queryParameters: {'FTS': query, 'PageSize': '8'});
      final response = await _apiService.get(uri.toString());
      final data = jsonDecode(response.body);
      final pagedList = PagedList<Property>.fromJson(data, (json) => Property.fromJson(json));
      _featuredProperties = pagedList.items;
    } catch (e) {
      _featuredError = e.toString();
    } finally {
      _isFeaturedLoading = false;
      notifyListeners();
    }
  }

  Future<void> applyPropertyFilters(Map<String, dynamic> filters) async {
    _isFeaturedLoading = true;
    _featuredError = null;
    notifyListeners();

    try {
      final params = filters.map((key, value) => MapEntry(key, value.toString()));
      params['IsFeatured'] = 'true';

      final uri = Uri.parse('properties/search').replace(queryParameters: params);
      final response = await _apiService.get(uri.toString());
      final data = jsonDecode(response.body);
      final pagedList = PagedList<Property>.fromJson(data, (json) => Property.fromJson(json));
      _featuredProperties = pagedList.items;
    } catch (e) {
      _featuredError = e.toString();
    } finally {
      _isFeaturedLoading = false;
      notifyListeners();
    }
  }
}
