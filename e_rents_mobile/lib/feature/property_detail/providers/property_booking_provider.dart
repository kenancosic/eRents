import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'package:e_rents_mobile/core/base/app_error.dart';

/// Provider for managing property bookings
/// Handles booking creation and management for specific properties
class PropertyBookingProvider extends BaseProvider {
  PropertyBookingProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  List<Booking> _bookings = [];
  List<Booking> _allBookings = [];
  Booking? _selectedBooking;
  bool _isBooking = false;
  bool _isCancellingBooking = false;
  bool _isUpdatingBooking = false;
  DateTime? _startDate;
  DateTime? _endDate;
  int _guests = 1;
  String _bookingNote = '';
  bool _isDateRangeValid = true;
  String? _dateRangeError;

  // ─── Getters ────────────────────────────────────────────────────────────
  List<Booking> get bookings => _bookings;
  List<Booking> get allBookings => _allBookings;
  Booking? get selectedBooking => _selectedBooking;
  bool get isBooking => _isBooking;
  bool get isCancellingBooking => _isCancellingBooking;
  bool get isUpdatingBooking => _isUpdatingBooking;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  int get guests => _guests;
  String get bookingNote => _bookingNote;
  bool get isDateRangeValid => _isDateRangeValid;
  String? get dateRangeError => _dateRangeError;

  // ─── Public API ─────────────────────────────────────────────────────────
  
  /// Fetch bookings for a property
  Future<void> fetchBookings(int propertyId) async {
    final bookings = await executeWithState(() async {
      return await api.getListAndDecode('/bookings/property/$propertyId', Booking.fromJson, authenticated: true);
    });

    if (bookings != null) {
      _allBookings = bookings;
      _bookings = List.from(_allBookings);
    }
  }

  /// Create a new booking for the property
  Future<bool> createBooking(int propertyId) async {
    if (_startDate == null || _endDate == null) {
      setError(GenericError(message: 'Please select start and end dates', code: 'booking_dates_missing'));
      return false;
    }
    
    if (!_isDateRangeValid) {
      setError(GenericError(message: _dateRangeError ?? 'Invalid date range', code: 'booking_invalid_date_range'));
      return false;
    }
    
    if (_isBooking) return false;
    _isBooking = true;
    notifyListeners();

    final success = await executeWithStateForSuccess(() async {
      final newBooking = await api.postAndDecode('/bookings', {
        'propertyId': propertyId,
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'guests': _guests,
        'note': _bookingNote,
      }, Booking.fromJson, authenticated: true);
      
      _allBookings.insert(0, newBooking);
      _bookings = List.from(_allBookings);
    }, errorMessage: 'Failed to create booking');

    _isBooking = false;
    notifyListeners();
    return success;
  }

  /// Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    if (_isCancellingBooking) return false;
    _isCancellingBooking = true;
    notifyListeners();

    final success = await executeWithStateForSuccess(() async {
      await api.delete('/bookings/$bookingId', authenticated: true);
      
      final index = _allBookings.indexWhere((booking) => booking.bookingId.toString() == bookingId);
      if (index != -1) {
        _allBookings[index] = _allBookings[index].copyWith(status: BookingStatus.cancelled);
        _applyBookingSearchAndFilters();
      }
    }, errorMessage: 'Failed to cancel booking');

    _isCancellingBooking = false;
    notifyListeners();
    return success;
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

  /// Set number of guests
  void setGuests(int guests) {
    _guests = guests;
    notifyListeners();
  }

  /// Set booking note
  void setBookingNote(String note) {
    _bookingNote = note;
    notifyListeners();
  }

  /// Clear booking form
  void clearBookingForm() {
    _startDate = null;
    _endDate = null;
    _guests = 1;
    _bookingNote = '';
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
}
