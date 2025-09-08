import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/enums/booking_enums.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'package:e_rents_mobile/core/base/app_error.dart';
import 'package:e_rents_mobile/core/models/property_detail.dart';
import 'package:e_rents_mobile/core/models/review.dart';

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
  Future<bool> cancelBooking(int bookingId, String reason) async {
    if (_isCancellingBooking) return false;
    _isCancellingBooking = true;
    notifyListeners();

    final success = await executeWithStateForSuccess(() async {
      // Backend expects POST /bookings/{id}/cancel; reason is currently not used server-side
      await api.post('/bookings/$bookingId/cancel', {'reason': reason}, authenticated: true);
      
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
    _startDate = start;
    _endDate = end;
    _validateDateRange();
    notifyListeners();
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
    final property = await executeWithState(() async {
      return await api.getAndDecode('/properties/$propertyId', PropertyDetail.fromJson, authenticated: true);
    });
    if (property != null) {
      _property = property;
    }
  }

  /// Fetch reviews for a property
  Future<void> fetchReviews(int propertyId) async {
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
        'propertyId': propertyId,
        'comment': comment,
        'rating': rating,
      }, Review.fromJson, authenticated: true);
      _reviews.insert(0, newReview);
    }, errorMessage: 'Failed to submit review');

    return success;
  }

  // Subscriptions are created automatically by the backend upon creating a
  // monthly booking in Checkout. No client-side subscription creation is needed.
}
