import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/models/user.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/models/tenant_preference_model.dart';

/// Consolidated provider for all Profile feature functionality
/// Manages user profile, bookings, tenant preferences, and payment methods
/// Following the provider-only architecture pattern
class ProfileProvider extends ChangeNotifier {
  final ApiService _api;
  
  ProfileProvider(this._api);

  // ─── State ──────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;

  // User Profile State
  User? _currentUser;
  User? get currentUser => _currentUser;
  User? get user => _currentUser; // Compatibility alias
  
  TenantPreferenceModel? _tenantPreferences;
  TenantPreferenceModel? get tenantPreferences => _tenantPreferences;
  TenantPreferenceModel? get tenantPreference => _tenantPreferences; // Compatibility alias
  
  List<Map<String, dynamic>> _paymentMethods = [];
  List<Map<String, dynamic>> get paymentMethods => _paymentMethods;

  // Booking State
  List<Booking> _bookings = [];
  List<Booking> get bookings => _bookings;
  List<Booking> get items => _bookings; // Compatibility alias
  List<Booking> get allItems => _bookings; // Compatibility alias
  
  Map<String, dynamic> _bookingStats = {};
  Map<String, dynamic> get bookingStats => _bookingStats;
  
  Map<String, dynamic> _currentFilters = {};
  Map<String, dynamic> get currentFilters => _currentFilters;
  
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Filtered and sorted booking lists
  List<Booking> _filteredBookings = [];
  List<Booking> get filteredBookings => _filteredBookings;

  // Caching with TTL
  DateTime? _lastUserLoad;
  DateTime? _lastBookingsLoad;
  DateTime? _lastPaymentMethodsLoad;
  DateTime? _lastTenantPreferencesLoad;
  static const Duration _cacheTTL = Duration(minutes: 5);

  // ─── Convenience Getters ───────────────────────────────────────────────
  
  /// Get user's full name
  String get fullName {
    if (_currentUser == null) return 'Unknown User';
    return _currentUser!.fullName;
  }

  /// Get user's display name (first name or username)
  String get displayName {
    if (_currentUser == null) return 'Guest';
    return _currentUser!.firstName ?? _currentUser!.username;
  }

  /// Check if user has profile image
  bool get hasProfileImage {
    return _currentUser?.profileImageId != null;
  }

  /// Get user's role/type
  String get userRole {
    return _currentUser?.role ?? 'guest';
  }

  // Booking convenience getters
  List<Booking> get currentBookings {
    final now = DateTime.now();
    return _filteredBookings.where((booking) {
      return booking.status == BookingStatus.active &&
          booking.startDate.isBefore(now) &&
          (booking.endDate == null || booking.endDate!.isAfter(now));
    }).toList();
  }

  List<Booking> get upcomingBookings {
    final now = DateTime.now();
    return _filteredBookings.where((booking) {
      return booking.status == BookingStatus.upcoming &&
          booking.startDate.isAfter(now);
    }).toList();
  }

  List<Booking> get pastBookings {
    final now = DateTime.now();
    return _filteredBookings.where((booking) {
      return booking.endDate != null && booking.endDate!.isBefore(now);
    }).toList();
  }

  List<Booking> get pendingBookings {
    return _filteredBookings
        .where((booking) => booking.status == BookingStatus.upcoming)
        .toList();
  }

  List<Booking> get cancelledBookings {
    return _filteredBookings
        .where((booking) => booking.status == BookingStatus.cancelled)
        .toList();
  }

  // ─── Private Helpers ───────────────────────────────────────────────────
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  bool _isCacheValid(DateTime? lastLoad) {
    if (lastLoad == null) return false;
    return DateTime.now().difference(lastLoad) < _cacheTTL;
  }

  Future<T> _execute<T>(Future<T> Function() operation) async {
    try {
      _clearError();
      _setLoading(true);
      final result = await operation();
      return result;
    } catch (e) {
      debugPrint('ProfileProvider: Error in operation: $e');
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ─── User Profile Methods ──────────────────────────────────────────────
  
  /// Load current user profile
  Future<void> loadCurrentUser({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid(_lastUserLoad) && _currentUser != null) {
      return;
    }

    await _execute(() async {
      debugPrint('ProfileProvider: Loading current user profile');
      
      final response = await _api.get('/users/current', authenticated: true);
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _currentUser = User.fromJson(userData);
        _lastUserLoad = DateTime.now();
        
        debugPrint('ProfileProvider: User profile loaded - ${_currentUser!.fullName}');
        
        // Auto-load tenant preferences if user is loaded
        if (_currentUser!.userId != null) {
          await loadTenantPreferences(forceRefresh: forceRefresh);
        }
      } else {
        throw Exception('Failed to load user profile: ${response.statusCode}');
      }
    });
  }

  /// Initialize user (compatibility method)
  Future<void> initUser() async {
    await loadCurrentUser();
    await loadPaymentMethods();
  }

  /// Update current user profile
  Future<bool> updateUserProfile(User updatedUser) async {
    return await _execute(() async {
      debugPrint('ProfileProvider: Updating user profile');
      
      final response = await _api.put(
        '/users/current', 
        updatedUser.toJson(),
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _currentUser = User.fromJson(userData);
        _lastUserLoad = DateTime.now();
        
        debugPrint('ProfileProvider: User profile updated successfully');
        return true;
      } else {
        throw Exception('Failed to update user profile: ${response.statusCode}');
      }
    });
  }

  /// Update specific user fields (optimistic updates)
  void updateUserField({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
  }) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        firstName: firstName ?? _currentUser!.firstName,
        lastName: lastName ?? _currentUser!.lastName,
        email: email ?? _currentUser!.email,
        phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
      );
      notifyListeners();
    }
  }

  /// Update user's public status
  Future<bool> updateUserPublicStatus(bool isPublic) async {
    if (_currentUser == null) return false;

    return await _execute(() async {
      debugPrint('ProfileProvider: Updating user public status to $isPublic');
      
      final response = await _api.put(
        '/users/current/public-status',
        {'isPublic': isPublic},
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        _currentUser = _currentUser!.copyWith(isPublic: isPublic);
        debugPrint('ProfileProvider: User public status updated successfully');
        return true;
      } else {
        throw Exception('Failed to update public status: ${response.statusCode}');
      }
    });
  }

  /// Upload profile image
  Future<bool> uploadProfileImage(File imageFile) async {
    return await _execute(() async {
      debugPrint('ProfileProvider: Uploading profile image');
      
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${_api.baseUrl}/users/current/image'),
      );
      
      // Add authentication header
      final token = await _api.secureStorageService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Add file
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        // Reload user profile to get updated image
        await loadCurrentUser(forceRefresh: true);
        debugPrint('ProfileProvider: Profile image uploaded and profile reloaded');
        return true;
      } else {
        throw Exception('Failed to upload profile image: ${response.statusCode}');
      }
    });
  }

  /// Logout - clear all user data
  Future<void> logout() async {
    await _execute(() async {
      debugPrint('ProfileProvider: Logging out user');
      
      final response = await _api.delete('/auth/logout', authenticated: true);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Clear all cached data
        _currentUser = null;
        _tenantPreferences = null;
        _paymentMethods.clear();
        _bookings.clear();
        _filteredBookings.clear();
        _bookingStats.clear();
        _currentFilters.clear();
        _searchQuery = '';
        
        // Clear cache timestamps
        _lastUserLoad = null;
        _lastBookingsLoad = null;
        _lastPaymentMethodsLoad = null;
        _lastTenantPreferencesLoad = null;
        
        debugPrint('ProfileProvider: User logged out and data cleared');
      } else {
        throw Exception('Failed to logout: ${response.statusCode}');
      }
    });
  }

  // ─── Tenant Preferences Methods ────────────────────────────────────────
  
  /// Load tenant preferences for current user
  Future<void> loadTenantPreferences({bool forceRefresh = false}) async {
    if (_currentUser?.userId == null) return;
    
    if (!forceRefresh && _isCacheValid(_lastTenantPreferencesLoad) && _tenantPreferences != null) {
      return;
    }

    await _execute(() async {
      debugPrint('ProfileProvider: Loading tenant preferences');
      
      final response = await _api.get(
        '/users/${_currentUser!.userId}/tenant-preferences',
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        final prefsData = jsonDecode(response.body);
        _tenantPreferences = TenantPreferenceModel.fromJson(prefsData);
        _lastTenantPreferencesLoad = DateTime.now();
        
        debugPrint('ProfileProvider: Tenant preferences loaded');
      } else if (response.statusCode == 404) {
        // No preferences found, this is okay
        _tenantPreferences = null;
        _lastTenantPreferencesLoad = DateTime.now();
      } else {
        throw Exception('Failed to load tenant preferences: ${response.statusCode}');
      }
    });
  }

  /// Update tenant preferences
  Future<bool> updateTenantPreferences(TenantPreferenceModel preferences) async {
    return await _execute(() async {
      debugPrint('ProfileProvider: Updating tenant preferences');
      
      final response = await _api.put(
        '/users/${_currentUser!.userId}/tenant-preferences',
        preferences.toJson(),
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        _tenantPreferences = preferences;
        _lastTenantPreferencesLoad = DateTime.now();
        debugPrint('ProfileProvider: Tenant preferences updated successfully');
        return true;
      } else {
        throw Exception('Failed to update tenant preferences: ${response.statusCode}');
      }
    });
  }

  // ─── Payment Methods ───────────────────────────────────────────────────
  
  /// Load payment methods for current user
  Future<void> loadPaymentMethods({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid(_lastPaymentMethodsLoad) && _paymentMethods.isNotEmpty) {
      return;
    }

    await _execute(() async {
      debugPrint('ProfileProvider: Loading payment methods');
      
      final response = await _api.get('/users/current/payment-methods', authenticated: true);
      
      if (response.statusCode == 200) {
        final paymentData = jsonDecode(response.body) as List;
        _paymentMethods = paymentData.cast<Map<String, dynamic>>();
        _lastPaymentMethodsLoad = DateTime.now();
        
        debugPrint('ProfileProvider: Payment methods loaded');
      } else {
        throw Exception('Failed to load payment methods: ${response.statusCode}');
      }
    });
  }

  /// Get payment methods (compatibility method)
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      await loadPaymentMethods();
      return _paymentMethods;
    } catch (e) {
      debugPrint('ProfileProvider: Error getting payment methods: $e');
      _setError('Failed to load payment methods');
      return [];
    }
  }

  /// Add payment method for current user
  Future<bool> addPaymentMethod(Map<String, dynamic> paymentData) async {
    return await _execute(() async {
      debugPrint('ProfileProvider: Adding payment method');
      
      final response = await _api.post(
        '/users/current/payment-methods',
        paymentData,
        authenticated: true,
      );
      
      if (response.statusCode == 201) {
        // Reload payment methods to get updated list
        await loadPaymentMethods(forceRefresh: true);
        debugPrint('ProfileProvider: Payment method added successfully');
        return true;
      } else {
        throw Exception('Failed to add payment method: ${response.statusCode}');
      }
    });
  }

  // ─── Booking Management Methods ────────────────────────────────────────
  
  /// Load user bookings with optional filters
  Future<void> loadUserBookings({
    Map<String, dynamic>? filters,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _isCacheValid(_lastBookingsLoad) && _bookings.isNotEmpty) {
      _applyFiltersAndSearch();
      return;
    }

    await _execute(() async {
      debugPrint('ProfileProvider: Loading user bookings');
      
      // Build query parameters
      final queryParams = <String, String>{};
      if (filters != null) {
        filters.forEach((key, value) {
          if (value != null) {
            queryParams[key] = value.toString();
          }
        });
      }
      
      final queryString = queryParams.isNotEmpty 
          ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}'
          : '';
      
      final response = await _api.get('/bookings/user$queryString', authenticated: true);
      
      if (response.statusCode == 200) {
        final bookingsData = jsonDecode(response.body) as List;
        _bookings = bookingsData.map((json) => Booking.fromJson(json)).toList();
        _lastBookingsLoad = DateTime.now();
        
        // Auto-sort by newest first
        _bookings.sort((a, b) => b.startDate.compareTo(a.startDate));
        
        // Apply current filters and search
        _applyFiltersAndSearch();
        
        debugPrint('ProfileProvider: Loaded ${_bookings.length} bookings');
      } else {
        throw Exception('Failed to load bookings: ${response.statusCode}');
      }
    });
  }

  /// Create a new booking
  Future<bool> createBooking({
    required int propertyId,
    required DateTime startDate,
    DateTime? endDate,
    required double totalPrice,
    required int numberOfGuests,
    String? specialRequests,
    String paymentMethod = 'PayPal',
  }) async {
    return await _execute(() async {
      debugPrint('ProfileProvider: Creating booking for property $propertyId');
      
      final bookingData = {
        'propertyId': propertyId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'totalPrice': totalPrice,
        'numberOfGuests': numberOfGuests,
        'specialRequests': specialRequests,
        'paymentMethod': paymentMethod,
      };
      
      final response = await _api.post('/bookings', bookingData, authenticated: true);
      
      if (response.statusCode == 201) {
        final bookingJson = jsonDecode(response.body);
        final newBooking = Booking.fromJson(bookingJson);
        
        // Add to local collection
        _bookings.insert(0, newBooking);
        _applyFiltersAndSearch();
        
        debugPrint('ProfileProvider: Booking created successfully');
        return true;
      } else {
        throw Exception('Failed to create booking: ${response.statusCode}');
      }
    });
  }

  /// Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    return await _execute(() async {
      debugPrint('ProfileProvider: Cancelling booking $bookingId');
      
      final response = await _api.put(
        '/bookings/$bookingId/cancel',
        {},
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        // Remove cancelled booking from local collection and refresh
        _bookings.removeWhere(
          (booking) => booking.bookingId.toString() == bookingId,
        );
        _applyFiltersAndSearch();
        
        debugPrint('ProfileProvider: Booking cancelled successfully');
        return true;
      } else {
        throw Exception('Failed to cancel booking: ${response.statusCode}');
      }
    });
  }

  /// Get booking statistics
  Future<void> loadBookingStats() async {
    await _execute(() async {
      debugPrint('ProfileProvider: Loading booking statistics');
      
      final response = await _api.get('/bookings/user/stats', authenticated: true);
      
      if (response.statusCode == 200) {
        _bookingStats = jsonDecode(response.body);
        debugPrint('ProfileProvider: Booking statistics loaded');
      } else {
        throw Exception('Failed to load booking stats: ${response.statusCode}');
      }
    });
  }

  /// Get booking statistics (computed from local data)
  Map<String, dynamic> getBookingStats() {
    if (_bookings.isEmpty) {
      return {
        'total': 0,
        'confirmed': 0,
        'pending': 0,
        'cancelled': 0,
        'totalSpent': 0.0,
        'averagePrice': 0.0,
      };
    }

    final confirmed = _bookings.where((b) => b.status == BookingStatus.active).length;
    final pending = _bookings.where((b) => b.status == BookingStatus.upcoming).length;
    final cancelled = _bookings.where((b) => b.status == BookingStatus.cancelled).length;
    final totalSpent = _bookings.fold<double>(0.0, (sum, b) => sum + b.totalPrice);
    final averagePrice = totalSpent / _bookings.length;

    return {
      'total': _bookings.length,
      'confirmed': confirmed,
      'pending': pending,
      'cancelled': cancelled,
      'totalSpent': totalSpent,
      'averagePrice': averagePrice,
    };
  }

  // ─── Filtering and Search Methods ──────────────────────────────────────
  
  /// Apply filters to bookings
  void applyFilters(Map<String, dynamic> filters) {
    _currentFilters = Map.from(filters);
    _applyFiltersAndSearch();
  }

  /// Clear all filters
  void clearFilters() {
    _currentFilters.clear();
    _applyFiltersAndSearch();
  }

  /// Search bookings by query
  void searchBookings(String query) {
    _searchQuery = query;
    _applyFiltersAndSearch();
  }

  /// Filter bookings by status
  void filterByStatus(String status) {
    applyFilters({'status': status});
  }

  /// Filter bookings by property
  void filterByProperty(int propertyId) {
    applyFilters({'propertyId': propertyId});
  }

  /// Filter bookings by date range
  void filterByDateRange(DateTime? startDate, DateTime? endDate) {
    final filters = <String, dynamic>{};
    if (startDate != null) filters['startDate'] = startDate;
    if (endDate != null) filters['endDate'] = endDate;
    applyFilters(filters);
  }

  /// Filter bookings by price range
  void filterByPriceRange(double? minPrice, double? maxPrice) {
    final filters = <String, dynamic>{};
    if (minPrice != null) filters['minPrice'] = minPrice;
    if (maxPrice != null) filters['maxPrice'] = maxPrice;
    applyFilters(filters);
  }

  void _applyFiltersAndSearch() {
    _filteredBookings = _bookings.where((booking) {
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final lowerQuery = _searchQuery.toLowerCase();
        final matchesSearch = booking.propertyName.toLowerCase().contains(lowerQuery) ||
            booking.status.name.toLowerCase().contains(lowerQuery) ||
            (booking.specialRequests?.toLowerCase().contains(lowerQuery) ?? false) ||
            (booking.paymentMethod.toLowerCase().contains(lowerQuery));
        
        if (!matchesSearch) return false;
      }

      // Apply filters
      return _matchesFilters(booking, _currentFilters);
    }).toList();

    notifyListeners();
  }

  bool _matchesFilters(Booking booking, Map<String, dynamic> filters) {
    // Status filter
    if (filters.containsKey('status')) {
      final statusFilter = filters['status'] as String?;
      if (statusFilter != null && booking.status.name != statusFilter) {
        return false;
      }
    }

    // Property filter
    if (filters.containsKey('propertyId')) {
      final propertyId = filters['propertyId'] as int?;
      if (propertyId != null && booking.propertyId != propertyId) {
        return false;
      }
    }

    // Date range filters
    if (filters.containsKey('startDate')) {
      final startDate = filters['startDate'] as DateTime?;
      if (startDate != null && booking.startDate.isBefore(startDate)) {
        return false;
      }
    }

    if (filters.containsKey('endDate')) {
      final endDate = filters['endDate'] as DateTime?;
      if (endDate != null &&
          (booking.endDate == null || booking.endDate!.isAfter(endDate))) {
        return false;
      }
    }

    // Price range filters
    if (filters.containsKey('minPrice')) {
      final minPrice = filters['minPrice'] as double?;
      if (minPrice != null && booking.totalPrice < minPrice) {
        return false;
      }
    }

    if (filters.containsKey('maxPrice')) {
      final maxPrice = filters['maxPrice'] as double?;
      if (maxPrice != null && booking.totalPrice > maxPrice) {
        return false;
      }
    }

    // Payment method filter
    if (filters.containsKey('paymentMethod')) {
      final paymentMethod = filters['paymentMethod'] as String?;
      if (paymentMethod != null && booking.paymentMethod != paymentMethod) {
        return false;
      }
    }

    return true;
  }

  // ─── Sorting Methods ───────────────────────────────────────────────────
  
  /// Sort bookings by date (newest first)
  void sortByDateDesc() {
    _filteredBookings.sort((a, b) => b.startDate.compareTo(a.startDate));
    notifyListeners();
  }

  /// Sort bookings by date (oldest first)
  void sortByDateAsc() {
    _filteredBookings.sort((a, b) => a.startDate.compareTo(b.startDate));
    notifyListeners();
  }

  /// Sort bookings by price (highest first)
  void sortByPriceDesc() {
    _filteredBookings.sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
    notifyListeners();
  }

  /// Sort bookings by price (lowest first)
  void sortByPriceAsc() {
    _filteredBookings.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
    notifyListeners();
  }

  /// Sort bookings by property name
  void sortByPropertyName() {
    _filteredBookings.sort((a, b) => a.propertyName.compareTo(b.propertyName));
    notifyListeners();
  }

  // ─── Convenience Methods for Specific Booking Types ───────────────────
  
  /// Load active bookings
  Future<void> loadActiveBookings() async {
    await loadUserBookings();
    filterByStatus('active');
  }

  /// Load upcoming bookings
  Future<void> loadUpcomingBookings() async {
    await loadUserBookings();
    final now = DateTime.now();
    filterByDateRange(now, null);
  }

  /// Load past bookings
  Future<void> loadPastBookings() async {
    await loadUserBookings();
    final now = DateTime.now();
    filterByDateRange(null, now);
  }

  /// Load pending bookings
  Future<void> loadPendingBookings() async {
    await loadUserBookings();
    filterByStatus('upcoming');
  }
}
