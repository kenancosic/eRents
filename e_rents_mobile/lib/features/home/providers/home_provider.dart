import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/models/property_card_model.dart';
import 'package:e_rents_mobile/core/models/user.dart';
import 'package:e_rents_mobile/core/enums/property_enums.dart';
import 'package:e_rents_mobile/core/enums/booking_enums.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'package:e_rents_mobile/core/providers/current_user_provider.dart';

/// Home dashboard provider for managing user data and property listings
/// Refactored to use new standardized BaseProvider without caching
class HomeProvider extends BaseProvider {
  HomeProvider(super.api);

  // Data state
  User? _currentUser;
  List<Booking> _upcomingBookings = [];
  List<Booking> _pendingBookings = [];
  List<PropertyCardModel> _recommendedCards = [];
  List<PropertyCardModel> _featuredCards = [];
  List<PropertyCardModel> _currentResidences = [];
  List<PropertyCardModel> _upcomingCards = [];
  List<PropertyCardModel> _pendingCards = [];
  
  // Store bookings for navigation context
  List<Booking> _currentResidenceBookings = [];

  // Getters
  User? get currentUser => _currentUser;
  List<Booking> get currentStays => _upcomingBookings; // For backward compatibility
  List<Booking> get upcomingStays => _upcomingBookings; // For backward compatibility
  List<Booking> get upcomingBookings => _upcomingBookings;
  List<Booking> get pendingBookings => _pendingBookings;
  // Card lists for UI
  List<PropertyCardModel> get recommendedCards => _recommendedCards;
  List<PropertyCardModel> get featuredCards => _featuredCards;
  List<PropertyCardModel> get currentResidences => _currentResidences;
  List<PropertyCardModel> get upcomingCards => _upcomingCards;
  List<PropertyCardModel> get pendingCards => _pendingCards;

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

  /// Initialize dashboard with current user from shared provider
  /// 
  /// Uses CurrentUserProvider to avoid duplicate /profile API calls.
  /// Call this from HomeScreen with context.read<CurrentUserProvider>().
  Future<void> initializeDashboard(CurrentUserProvider currentUserProvider) async {
    await executeWithState(() async {
      // Get user from shared provider (uses caching)
      final user = await currentUserProvider.ensureLoaded();
      _currentUser = user;
      
      // Only proceed if we have a valid user
      if (_currentUser == null) {
        debugPrint('HomeProvider: No user data available, skipping dashboard load');
        return;
      }
      
      debugPrint('HomeProvider: Initializing dashboard for user ${_currentUser!.userId}');
      
      await Future.wait([
        _loadCurrentResidences(),
        _loadUpcomingBookings(),
        _loadPendingBookings(),
        _loadRecommendedProperties(),
      ]);
    });
  }

  /// Refresh dashboard data
  Future<void> refreshDashboard(CurrentUserProvider currentUserProvider) async {
    // Force refresh user data and reload dashboard
    await currentUserProvider.refresh();
    await initializeDashboard(currentUserProvider);
  }

  /// Update current user from external source (e.g., when CurrentUserProvider updates)
  void updateCurrentUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> _loadUpcomingBookings() async {
    // Match booking history approach: load user bookings without status filter,
    // then filter locally for 'Upcoming' or 'Active' status.
    // This ensures upcoming bookings on Home match those in Booking History.
    final userId = _currentUser?.userId;
    if (userId == null) {
      _upcomingBookings = [];
      _upcomingCards = [];
      return;
    }
    
    final filters = {
      'UserId': userId.toString(),
      'PageSize': '20',
      'SortBy': 'startdate',
      'SortDirection': 'asc',
    };
    final queryString = api.buildQueryString(filters);
    final allBookings = await executeWithState(() async {
      return await api.getPagedAndDecode(
        '/bookings$queryString',
        Booking.fromJson,
        authenticated: true,
      );
    });
    
    if (allBookings != null) {
      // Filter locally for upcoming bookings (status = Upcoming or Active)
      // This matches the booking history screen's upcomingBookings getter
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      _upcomingBookings = allBookings.items.where((booking) {
        // Include Upcoming or Active status bookings that haven't ended yet
        final isUpcoming = booking.status == BookingStatus.upcoming;
        final isActive = booking.status == BookingStatus.active;
        final endDate = booking.endDate;
        final notEnded = endDate == null || endDate.isAfter(today) || endDate.isAtSameMomentAs(today);
        return (isUpcoming || isActive) && notEnded;
      }).toList();
      
      debugPrint('HomeProvider: Found ${_upcomingBookings.length} upcoming bookings from ${allBookings.items.length} total');
      final cards = await _enrichBookingsToCards(_upcomingBookings);
      // Deduplicate by propertyId - show only one card per property
      final seen = <int>{};
      _upcomingCards = cards.where((c) => seen.add(c.propertyId)).toList();
    }
  }

  Future<void> _loadCurrentResidences() async {
    // Active stays where StartDate <= today and EndDate >= today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final userId = _currentUser?.userId;
    final filters = {
      'UserId': userId?.toString(),
      'Status': 'Active',
      'StartDateTo': _formatDate(today),
      'EndDateFrom': _formatDate(today),
      'PageSize': '10',
      'SortBy': 'startdate',
      'SortDirection': 'asc',
    };
    final queryString = api.buildQueryString(filters);
    final current = await executeWithState(() async {
      return await api.getPagedAndDecode(
        '/bookings$queryString',
        Booking.fromJson,
        authenticated: true,
      );
    });

    if (current != null) {
      _currentResidenceBookings = current.items;
      final cards = await _enrichBookingsToCards(current.items);
      // Deduplicate by propertyId - user can only reside at one property at a time
      final seen = <int>{};
      _currentResidences = cards.where((c) => seen.add(c.propertyId)).toList();
    }
  }

  Future<void> _loadPendingBookings() async {
    // Fetch upcoming monthly bookings
    final userId = _currentUser?.userId;
    final filters = {
      'UserId': userId?.toString(),
      'Status': 'Upcoming',
      'RentingType': 'Monthly',
      'PageSize': '10',
      'SortBy': 'startdate',
      'SortDirection': 'asc',
    };
    final queryString = api.buildQueryString(filters);
    final pending = await executeWithState(() async {
      return await api.getPagedAndDecode(
        '/bookings$queryString',
        Booking.fromJson,
        authenticated: true,
      );
    });
    
    if (pending != null) {
      _pendingBookings = pending.items;
      _pendingCards = await _enrichBookingsToCards(_pendingBookings, forceMonthly: true);
    }
  }

  /// Public refresh for only pending monthly bookings (used by HomeScreen timer)
  Future<void> refreshPendingBookings() async {
    final userId = _currentUser?.userId;
    final filters = {
      'UserId': userId?.toString(),
      'Status': 'Upcoming',
      'RentingType': 'Monthly',
      'PageSize': '10',
      'SortBy': 'startdate',
      'SortDirection': 'asc',
    };
    final queryString = api.buildQueryString(filters);
    final pending = await executeWithState(() async {
      return await api.getPagedAndDecode(
        '/bookings$queryString',
        Booking.fromJson,
        authenticated: true,
      );
    });

    if (pending != null) {
      _pendingBookings = pending.items;
      _pendingCards = await _enrichBookingsToCards(_pendingBookings, forceMonthly: true);
      notifyListeners();
    }
  }

  


  Future<void> _loadRecommendedProperties() async {
    // Fetch personalized recommendations as PropertyCardModel for UI
    final recommendedCards = await executeWithState(() async {
      return await api.getListAndDecode(
        '/properties/me/recommendations?count=6',
        PropertyCardModel.fromJson,
        authenticated: true,
      );
    });

    if (recommendedCards != null) {
      _recommendedCards = recommendedCards;
    }

    // Fallback: if no recommendations returned, try location-based available properties
    if (_recommendedCards.isEmpty && _currentUser?.address?.city != null) {
      final city = _currentUser!.address!.city!;
      final filters = <String, dynamic>{
        'City': city,
        'Status': 'Available',
        'PageSize': '8',
        'SortBy': 'createdat',
      };
      final queryString = api.buildQueryString(filters);
      final pagedResult = await executeWithState(() async {
        return await api.getPagedAndDecode(
          '/properties$queryString',
          PropertyCardModel.fromJson,
          authenticated: true,
        );
      });
      if (pagedResult != null) {
        _recommendedCards = pagedResult.items;
      }
    }
  }

  Future<void> searchProperties(String query) async {
    if (query.trim().isEmpty) {
      return;
    }

    final filters = <String, dynamic>{
      'NameContains': query,
      'PageSize': '8',
    };
    
    final queryString = api.buildQueryString(filters);
    final pagedResult = await executeWithState(() async {
      return await api.getPagedAndDecode(
        '/properties$queryString',
        PropertyCardModel.fromJson,
      );
    });

    if (pagedResult != null) {
      _featuredCards = pagedResult.items;
    }
  }

  Future<void> applyPropertyFilters(Map<String, dynamic> filters) async {
    final searchFilters = Map<String, dynamic>.from(filters);
    
    final queryString = api.buildQueryString(searchFilters);
    final pagedResult = await executeWithState(() async {
      return await api.getPagedAndDecode(
        '/properties$queryString',
        PropertyCardModel.fromJson,
      );
    });

    if (pagedResult != null) {
      _featuredCards = pagedResult.items;
    }
  }

  /// Get booking for a property from current residences
  Booking? getBookingForProperty(int propertyId) {
    try {
      return _currentResidenceBookings.firstWhere((b) => b.propertyId == propertyId);
    } catch (_) {
      // Check upcoming bookings as fallback
      try {
        return _upcomingBookings.firstWhere((b) => b.propertyId == propertyId);
      } catch (_) {
        // Check pending bookings
        try {
          return _pendingBookings.firstWhere((b) => b.propertyId == propertyId);
        } catch (_) {
          return null;
        }
      }
    }
  }

  // --- Helpers ---
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Clear all cached data on logout
  /// 
  /// Should be called when the user logs out to ensure
  /// stale data isn't used on next login.
  void clearOnLogout() {
    _currentUser = null;
    _upcomingBookings = [];
    _pendingBookings = [];
    _recommendedCards = [];
    _featuredCards = [];
    _currentResidences = [];
    _upcomingCards = [];
    _pendingCards = [];
    _currentResidenceBookings = [];
    debugPrint('HomeProvider: All data cleared on logout');
    notifyListeners();
  }

  Future<List<PropertyCardModel>> _enrichBookingsToCards(List<Booking> bookings, {bool forceMonthly = false}) async {
    if (bookings.isEmpty) return [];

    // Collect unique property IDs
    final ids = bookings.map((b) => b.propertyId).where((id) => id > 0).toSet().toList();
    Map<int, PropertyCardModel> cardMap = {};

    try {
      final cards = await api.postListAndDecode(
        '/properties/cards/batch',
        {'ids': ids},
        PropertyCardModel.fromJson,
        authenticated: true,
      );
      cardMap = {for (final c in cards) c.propertyId: c};
    } catch (_) {
      // Fallback to minimal mapping if batch endpoint fails
      cardMap = {};
    }

    PropertyCardModel mergeCard(PropertyCardModel? base, Booking booking) {
      final inferredRentalType = forceMonthly
          ? PropertyRentalType.monthly
          : (base?.rentalType ??
              (booking.dailyRate > 0 ? PropertyRentalType.daily : PropertyRentalType.monthly));

      // Choose price based on inferred rental type:
      // - Daily: prefer booking.dailyRate, fallback to base price
      // - Monthly: prefer base price, fallback to booking.dailyRate if present
      final double effectivePrice = inferredRentalType == PropertyRentalType.daily
          ? (booking.dailyRate > 0 ? booking.dailyRate : (base?.price ?? 0))
          : (base?.price ?? (booking.dailyRate > 0 ? booking.dailyRate : 0));

      return PropertyCardModel(
        propertyId: booking.propertyId,
        name: base?.name ?? booking.propertyName,
        price: effectivePrice,
        currency: booking.currency ?? (base?.currency ?? 'USD'),
        averageRating: base?.averageRating,
        coverImageId: base?.coverImageId,
        address: base?.address,
        rentalType: inferredRentalType,
      );
    }

    return bookings.map((b) => mergeCard(cardMap[b.propertyId], b)).toList();
  }
}
