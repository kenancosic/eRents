import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/enums/booking_enums.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'package:e_rents_mobile/core/base/app_error.dart';
import 'package:e_rents_mobile/core/models/property_detail.dart';
import 'package:e_rents_mobile/core/models/review.dart';
import 'package:e_rents_mobile/core/models/user.dart';
import 'package:e_rents_mobile/core/models/amenity.dart';

/// Provider for managing property rentals (both daily and monthly)
/// Product decision:
/// - Checkout is the only path to create bookings (daily and monthly)
/// - Monthly rentals are billed via subscription created server-side after monthly booking
/// Note: Any legacy monthly “tenant request” flow is deprecated.
class PropertyRentalProvider extends BaseProvider {
  PropertyRentalProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  
  // Daily rental state
  List<Booking> _bookings = [];
  List<Booking> _allBookings = [];
  Booking? _selectedBooking;
  bool _isCancellingBooking = false;
  bool _isUpdatingBooking = false;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isDateRangeValid = true;
  String? _dateRangeError;

  // Monthly flow is handled via Checkout + server-side subscription creation

  // Property Details and Reviews
  PropertyDetail? _property;
  List<Review> _reviews = [];
  User? _owner;
  List<Amenity> _amenities = [];
  bool _isFetchingAmenities = false;
  bool _isFetchingOwner = false;
  final Map<int, Amenity> _amenityCache = {};

  // ─── Getters ────────────────────────────────────────────────────────────
  
  // Daily rental getters
  List<Booking> get bookings => _bookings;
  List<Booking> get allBookings => _allBookings;
  Booking? get selectedBooking => _selectedBooking;
  bool get isCancellingBooking => _isCancellingBooking;
  bool get isUpdatingBooking => _isUpdatingBooking;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get isDateRangeValid => _isDateRangeValid;
  String? get dateRangeError => _dateRangeError;

  // Monthly-specific request state and getters removed (deprecated flow)

  // Property Details and Reviews getters
  PropertyDetail? get property => _property;
  List<Review> get reviews => _reviews;
  User? get owner => _owner;
  List<Amenity> get amenities => _amenities;

  /// Return amenities for the provided IDs using the in-memory cache when possible
  List<Amenity> getAmenitiesFor(List<int> amenityIds) {
    if (amenityIds.isEmpty) return const [];
    final ids = amenityIds.where((e) => e > 0).toList();
    final results = <Amenity>[];
    for (final id in ids) {
      final cached = _amenityCache[id];
      if (cached != null) {
        results.add(cached);
      } else {
        final idx = _amenities.indexWhere((a) => a.amenityId == id);
        if (idx != -1) results.add(_amenities[idx]);
      }
    }
    return results;
  }

  // ─── Public API ─────────────────────────────────────────────────────────
  
  /// Request an extension for a monthly booking (approval workflow)
  /// Provide either newEndDate (exact) OR extendByMonths (relative). Optionally update monthly amount.
  Future<bool> extendBooking({
    required int bookingId,
    DateTime? newEndDate,
    int? extendByMonths,
    double? newMonthlyAmount,
  }) async {
    if (_isUpdatingBooking) return false;
    // Validate mutually exclusive params
    if ((newEndDate == null && extendByMonths == null) ||
        (newEndDate != null && extendByMonths != null)) {
      setError(ValidationError(message: 'Provide either new end date or extend by months.'));
      return false;
    }

    _isUpdatingBooking = true;
    notifyListeners();

    final payload = <String, dynamic>{};
    if (newEndDate != null) {
      // Send as yyyy-MM-dd to match backend DateOnly binder
      final y = newEndDate.year.toString().padLeft(4, '0');
      final m = newEndDate.month.toString().padLeft(2, '0');
      final d = newEndDate.day.toString().padLeft(2, '0');
      payload['newEndDate'] = '$y-$m-$d';
    }
    if (extendByMonths != null) {
      payload['extendByMonths'] = extendByMonths;
    }
    if (newMonthlyAmount != null) {
      payload['newMonthlyAmount'] = newMonthlyAmount;
    }

    final success = await executeWithStateForSuccess(() async {
      // Submit extension request for landlord approval
      await api.post(
        '/leaseextensions/booking/$bookingId',
        payload,
        authenticated: true,
      );
      // No immediate booking update; landlord must approve
    }, errorMessage: 'Failed to request extension');

    _isUpdatingBooking = false;
    notifyListeners();
    return success;
  }

  /// Fetch the property's owner information by ownerId
  Future<void> fetchOwner(int ownerId) async {
    if (_isFetchingOwner) return;
    if (_owner?.userId == ownerId) return;

    _isFetchingOwner = true;
    try {
      final user = await executeWithState(() async {
        return await api.getAndDecode('/users/$ownerId', User.fromJson, authenticated: true);
      });
      if (user != null) {
        _owner = user;
        notifyListeners();
      }
    } finally {
      _isFetchingOwner = false;
    }
  }

  /// Fetch amenity details for the given amenity IDs
  Future<void> fetchAmenitiesByIds(List<int> amenityIds) async {
    // Normalize and guard
    final ids = amenityIds.where((e) => e > 0).toSet();
    if (ids.isEmpty) {
      if (_amenities.isNotEmpty) {
        _amenities = [];
        notifyListeners();
      }
      return;
    }

    // Avoid duplicate fetches during rebuilds
    if (_isFetchingAmenities) return;

    // If we already have all requested amenities, reuse in-memory data and update the visible list
    final existingIds = _amenities.map((a) => a.amenityId).toSet();
    if (ids.difference(existingIds).isEmpty) {
      final results = <Amenity>[];
      for (final id in ids) {
        final fromCache = _amenityCache[id];
        if (fromCache != null) {
          results.add(fromCache);
        } else {
          final idx = _amenities.indexWhere((a) => a.amenityId == id);
          if (idx != -1) {
            final a = _amenities[idx];
            results.add(a);
            _amenityCache[a.amenityId] = a;
          }
        }
      }
      _amenities = results;
      notifyListeners();
      return;
    }

    _isFetchingAmenities = true;
    try {
      // 1) Try new batch endpoint first
      final batch = await api.postListAndDecode(
        '/amenity/batch',
        {'ids': ids.toList()},
        Amenity.fromJson,
        authenticated: true,
      );

      // Preserve original ID order
      final byId = {for (final a in batch) a.amenityId: a};
      final results = <Amenity>[];
      for (final id in ids) {
        final a = byId[id];
        if (a != null) results.add(a);
      }
      for (final a in results) {
        _amenityCache[a.amenityId] = a;
      }
      _amenities = results;
      notifyListeners();
    } catch (e) {
      // 2) Fallback to a single paginated fetch and filter locally
      debugPrint('Amenity batch fetch failed, falling back to paged fetch. Error: $e');
      try {
        final qs = api.buildQueryString({'page': 1, 'pageSize': 500});
        final paged = await api.getPagedAndDecode('/amenity$qs', Amenity.fromJson, authenticated: true);
        final byId = {for (final a in paged.items) a.amenityId: a};
        final results = <Amenity>[];
        for (final id in ids) {
          final a = byId[id];
          if (a != null) results.add(a);
        }
        for (final a in results) {
          _amenityCache[a.amenityId] = a;
        }
        _amenities = results;
        notifyListeners();
      } catch (e2) {
        // Do not bubble up; leave existing amenities as-is
        debugPrint('Failed to fetch amenities via fallback: $e2');
      }
    } finally {
      _isFetchingAmenities = false;
    }
  }

  /// Fetch bookings for a property
  Future<void> fetchBookings(int propertyId) async {
    final bookings = await executeWithState(() async {
      final qs = api.buildQueryString({'PropertyId': propertyId.toString()});
      return await api.getListAndDecode('/bookings$qs', Booking.fromJson, authenticated: true);
    });

    if (bookings != null) {
      _allBookings = bookings;
      _bookings = List.from(_allBookings);
    }
  }

  /// Cancel a booking
  /// Optionally provide a [cancellationDate] (yyyy-MM-dd will be sent) for monthly in-stay cancellations
  Future<bool> cancelBooking(int bookingId, {DateTime? cancellationDate}) async {
    if (_isCancellingBooking) return false;
    _isCancellingBooking = true;
    notifyListeners();

    final success = await executeWithStateForSuccess(() async {
      // Backend expects POST /bookings/{id}/cancel
      final payload = <String, dynamic>{};
      if (cancellationDate != null) {
        final y = cancellationDate.year.toString().padLeft(4, '0');
        final m = cancellationDate.month.toString().padLeft(2, '0');
        final d = cancellationDate.day.toString().padLeft(2, '0');
        payload['cancellationDate'] = '$y-$m-$d';
      }
      await api.post('/bookings/$bookingId/cancel', payload, authenticated: true);
      
      final index = _allBookings.indexWhere((booking) => booking.bookingId == bookingId);
      if (index != -1) {
        _allBookings[index] = _allBookings[index].copyWith(status: BookingStatus.cancelled);
        _applyBookingSearchAndFilters();
      }
    }, errorMessage: 'Failed to cancel booking');

    _isCancellingBooking = false;
    notifyListeners();
    return success;
  }

  /// Get booking details
  Future<Booking?> getBookingDetails(int bookingId) async {
    return await executeWithState<Booking?>(() async {
      return await api.getAndDecode('/bookings/$bookingId', Booking.fromJson, authenticated: true);
    });
  }

  /// Select a booking
  void selectBooking(Booking booking) {
    _selectedBooking = booking;
    notifyListeners();
  }

  /// Set booking date range
  void setBookingDateRange(DateTime? start, DateTime? end) {
    final changed = _startDate != start || _endDate != end;
    _startDate = start;
    _endDate = end;
    _validateDateRange();
    if (changed) {
      notifyListeners();
    }
  }

  /// Clear booking form
  void clearBookingForm() {
    _startDate = null;
    _endDate = null;
    _isDateRangeValid = true;
    _dateRangeError = null;
    notifyListeners();
  }

  void _validateDateRange() {
    if (_startDate == null || _endDate == null) {
      _isDateRangeValid = true;
      _dateRangeError = null;
      return;
    }

    if (_startDate!.isAfter(_endDate!)) {
      _isDateRangeValid = false;
      _dateRangeError = 'Start date must be before end date';
      return;
    }

    if (_startDate!.isBefore(DateTime.now())) {
      _isDateRangeValid = false;
      _dateRangeError = 'Start date cannot be in the past';
      return;
    }

    final difference = _endDate!.difference(_startDate!).inDays;
    if (difference > 30) {
      _isDateRangeValid = false;
      _dateRangeError = 'Booking duration cannot exceed 30 days';
      return;
    }

    _isDateRangeValid = true;
    _dateRangeError = null;
  }

  void _applyBookingSearchAndFilters() {
    // For now, we're just updating the bookings list with all bookings
    // In the future, we might add search/filter functionality
    _bookings = List.from(_allBookings);
    notifyListeners();
  }

  // ─── Property Details and Reviews API ───────────────────────────────────

  /// Fetch property details by ID
  Future<void> fetchPropertyDetails(int propertyId) async {
    // Avoid redundant fetch if we already have this property's details
    if (_property?.propertyId == propertyId) {
      return;
    }
    final property = await executeWithState(() async {
      return await api.getAndDecode('/properties/$propertyId', PropertyDetail.fromJson, authenticated: true);
    });
    if (property != null) {
      _property = property;
    }
  }

  /// Fetch reviews for a property
  Future<void> fetchReviews(int propertyId) async {
    // Avoid redundant fetch on rebuilds if reviews are already loaded for this property
    if (_property?.propertyId == propertyId && _reviews.isNotEmpty) {
      return;
    }
    final reviews = await executeWithState(() async {
      final qs = api.buildQueryString({'PropertyId': propertyId.toString()});
      return await api.getListAndDecode('/reviews$qs', Review.fromJson, authenticated: true);
    });
    if (reviews != null) {
      _reviews = reviews;
    }
  }

  /// Add a review for a property
  Future<bool> addReview(int propertyId, String comment, double rating) async {
    final success = await executeWithStateForSuccess(() async {
      final newReview = await api.postAndDecode('/reviews', {
        // Backend expects enum as an integer (no JsonStringEnumConverter configured)
        // 0 = PropertyReview per eRents.Domain.Models.Enums.ReviewType
        'reviewType': 0,
        'propertyId': propertyId,
        'description': comment,
        'starRating': rating,
      }, Review.fromJson, authenticated: true);
      _reviews.insert(0, newReview);
    }, errorMessage: 'Failed to submit review');

    return success;
  }

  // Subscriptions are created automatically by the backend upon creating a
  // monthly booking in Checkout. No client-side subscription creation is needed.
}
