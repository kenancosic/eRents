import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/services/booking_service.dart';

class UserBookingsProvider extends BaseProvider {
  final BookingService _bookingService;

  UserBookingsProvider(this._bookingService) {
    _fetchUserBookings();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Class-level declarations for booking lists
  List<Booking> _allBookings = [];
  List<Booking> _upcomingBookings = [];
  List<Booking> _completedBookings = [];
  List<Booking> _cancelledBookings = [];

  List<Booking> get upcomingBookings => _upcomingBookings;
  List<Booking> get completedBookings => _completedBookings;
  List<Booking> get cancelledBookings => _cancelledBookings;

  Future<void> fetchBookings() async {
    await _fetchUserBookings();
  }

  Future<void> _fetchUserBookings() async {
    _isLoading = true;
    notifyListeners();
    try {
      // _allBookings = await _bookingService.getUserBookings(); // Real API call
      _allBookings = _getMockBookings(); // Using mock data for now
    } catch (e) {
      // Handle error, perhaps set an error state
      print('Error fetching bookings: $e');
      _allBookings = _getMockBookings(); // Fallback to mock on error during dev
    }
    _categorizeBookings();
    _isLoading = false;
    notifyListeners();
  }

  void _categorizeBookings() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<Booking> active = [];
    List<Booking> upcoming = [];
    List<Booking> completed = [];
    List<Booking> cancelled = [];

    for (var booking in _allBookings) {
      final bookingStartDate = DateTime(booking.startDate.year,
          booking.startDate.month, booking.startDate.day);
      final bookingEndDate = booking.endDate != null
          ? DateTime(booking.endDate!.year, booking.endDate!.month,
              booking.endDate!.day)
          : null;

      if (booking.status == BookingStatus.Cancelled) {
        cancelled.add(booking);
      } else if (booking.status == BookingStatus.Completed) {
        completed.add(booking);
      } else if (booking.status == BookingStatus.Active) {
        if (bookingStartDate.isAfter(today)) {
          // Active status but start date is future
          upcoming.add(booking);
        } else if (bookingEndDate != null && bookingEndDate.isBefore(today)) {
          // Active status but end date is past
          completed.add(booking);
        } else {
          // Genuinely active
          active.add(booking);
        }
      } else if (booking.status == BookingStatus.Upcoming) {
        if (bookingStartDate.isBefore(today) ||
            bookingStartDate.isAtSameMomentAs(today)) {
          // Upcoming but start date has arrived
          if (bookingEndDate == null ||
              bookingEndDate.isAfter(today) ||
              bookingEndDate.isAtSameMomentAs(today)) {
            active.add(booking); // Treat as active
          } else {
            completed.add(booking); // Start date arrived but already ended
          }
        } else {
          // Genuinely upcoming
          upcoming.add(booking);
        }
      }
    }

    // Combine active and upcoming, then sort
    _upcomingBookings = [...active, ...upcoming];
    _completedBookings = completed;
    _cancelledBookings = cancelled;

    // Sort _upcomingBookings:
    // 1. Active bookings first.
    // 2. Among active: Indefinite (null endDate) before fixed-term.
    // 3. Sort by startDate, then for active fixed-term by endDate.
    _upcomingBookings.sort((a, b) {
      bool isAActive = a.status == BookingStatus.Active ||
          (a.status == BookingStatus.Upcoming &&
              DateTime(a.startDate.year, a.startDate.month, a.startDate.day)
                  .isBefore(DateTime.now()));
      bool isBActive = b.status == BookingStatus.Active ||
          (b.status == BookingStatus.Upcoming &&
              DateTime(b.startDate.year, b.startDate.month, b.startDate.day)
                  .isBefore(DateTime.now()));

      if (isAActive && !isBActive) return -1;
      if (!isAActive && isBActive) return 1;

      if (isAActive && isBActive) {
        // Both are effectively active
        if (a.endDate == null && b.endDate != null)
          return -1; // Indefinite 'a' first
        if (a.endDate != null && b.endDate == null)
          return 1; // Indefinite 'b' first

        // Both indefinite or both fixed-term, sort by start date
        int startDateComparison = a.startDate.compareTo(b.startDate);
        if (startDateComparison != 0) return startDateComparison;

        // If start dates same, and both are fixed-term, sort by end date
        if (a.endDate != null && b.endDate != null) {
          return a.endDate!.compareTo(b.endDate!);
        }
        return 0; // Both indefinite with same start date
      }

      // Both are upcoming (not yet active)
      return a.startDate.compareTo(b.startDate);
    });

    _completedBookings.sort((a, b) {
      if (a.endDate == null && b.endDate == null)
        return a.startDate
            .compareTo(b.startDate); // Should not happen for completed
      if (a.endDate == null) return 1;
      if (b.endDate == null) return -1;
      return b.endDate!.compareTo(a.endDate!); // Most recent completed first
    });

    _cancelledBookings.sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  List<Booking> _getMockBookings() {
    final now = DateTime.now();
    return [
      // Active - Indefinite Lease (No EndDate)
      Booking(
        bookingId: 201,
        propertyId: 101,
        userId: 1,
        propertyName: "Urban Studio - Indefinite Stay",
        propertyImageUrl: "assets/images/properties/prop2.jpg",
        startDate: now.subtract(const Duration(days: 60)),
        endDate: null,
        minimumStayEndDate: now.add(const Duration(days: 30)),
        totalPrice: 1200.00,
        status: BookingStatus.Active,
      ),
      // Active - Fixed term, normal
      Booking(
        bookingId: 1,
        propertyId: 101,
        userId: 1,
        propertyName: "Cozy Downtown Apartment",
        propertyImageUrl: "assets/images/properties/prop1.jpg",
        startDate: now.subtract(const Duration(days: 15)),
        endDate: now.add(const Duration(days: 15)),
        totalPrice: 500.00,
        status: BookingStatus.Active,
      ),
      // Active - with minimum stay
      Booking(
        bookingId: 202,
        propertyId: 201,
        userId: 1,
        propertyName: "Serviced Apartment - Long Project",
        propertyImageUrl: "assets/images/properties/prop3.jpg",
        startDate: now.subtract(const Duration(days: 20)),
        endDate: now.add(const Duration(days: 100)),
        minimumStayEndDate: now.add(const Duration(days: 40)),
        totalPrice: 2500.00,
        status: BookingStatus.Active,
      ),
      // Upcoming - Indefinite
      Booking(
        bookingId: 203,
        propertyId: 202,
        userId: 1,
        propertyName: "Future Open-Ended Lease",
        propertyImageUrl: "assets/images/properties/prop4.jpg",
        startDate: now.add(const Duration(days: 60)),
        endDate: null,
        minimumStayEndDate: now.add(const Duration(days: 60 + 90)),
        totalPrice: 1500.00,
        status: BookingStatus.Upcoming,
      ),
      // --- Upcoming Bookings ---
      Booking(
        bookingId: 2,
        propertyId: 102,
        userId: 1,
        propertyName: 'Beachside Villa Getaway',
        propertyImageUrl: 'assets/images/villa.jpg',
        startDate: now.add(const Duration(days: 30)),
        endDate: now.add(const Duration(days: 37)),
        totalPrice: 1200.00,
        status: BookingStatus.Upcoming,
        currency: 'USD',
        bookingDate: now.subtract(const Duration(days: 2)),
      ),
      Booking(
        bookingId: 3,
        propertyId: 103,
        userId: 1,
        propertyName: 'Mountain Cabin Retreat',
        propertyImageUrl: 'assets/images/cabin.jpg',
        startDate: now.add(const Duration(days: 90)),
        endDate: now.add(const Duration(days: 97)),
        totalPrice: 750.00,
        status: BookingStatus.Upcoming,
        currency: 'USD',
        bookingDate: now.subtract(const Duration(days: 10)),
      ),
      // --- Completed Bookings ---
      Booking(
        bookingId: 4,
        propertyId: 104,
        userId: 1,
        propertyName: 'Past City Loft Experience',
        propertyImageUrl: 'assets/images/loft.jpg',
        startDate: now.subtract(const Duration(days: 60)),
        endDate: now.subtract(const Duration(days: 53)),
        totalPrice: 600.00,
        status: BookingStatus.Completed,
        currency: 'USD',
        bookingDate: now.subtract(const Duration(days: 70)),
        reviewContent: "Great place, very central!",
        reviewRating: 5,
      ),
      Booking(
        bookingId: 5,
        propertyId: 105,
        userId: 1,
        propertyName: 'Rustic Farmhouse Stay',
        propertyImageUrl: 'assets/images/farmhouse.jpg',
        startDate: now.subtract(const Duration(days: 120)),
        endDate: now.subtract(const Duration(days: 110)),
        totalPrice: 950.00,
        status: BookingStatus.Completed,
        currency: 'USD',
        bookingDate: now.subtract(const Duration(days: 130)),
      ),
      // --- Cancelled Bookings ---
      Booking(
        bookingId: 6,
        propertyId: 106,
        userId: 1,
        propertyName: 'Cancelled Lakeside Bungalow',
        propertyImageUrl: 'assets/images/bungalow.jpg',
        startDate: now.add(const Duration(days: 14)), // Was upcoming
        endDate: now.add(const Duration(days: 21)),
        totalPrice: 450.00,
        status: BookingStatus.Cancelled,
        currency: 'USD',
        bookingDate: now.subtract(const Duration(days: 3)),
      ),
      // Active booking that ended yesterday
      Booking(
        bookingId: 7,
        propertyId: 107,
        userId: 1,
        propertyName: 'Just Ended Downtown Flat',
        propertyImageUrl: 'assets/images/properties/prop5.jpg',
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now.subtract(const Duration(days: 1)),
        totalPrice: 300.00,
        status: BookingStatus.Active, // Status might still be Active in DB
      ),
      // Upcoming booking that starts today
      Booking(
        bookingId: 8,
        propertyId: 108,
        userId: 1,
        propertyName: 'Starts Today City Pad',
        propertyImageUrl: 'assets/images/properties/prop6.jpg',
        startDate: now,
        endDate: now.add(const Duration(days: 5)),
        totalPrice: 250.00,
        status: BookingStatus.Upcoming, // Status might be Upcoming in DB
      ),
    ];
  }

  // Method to get a specific booking by ID
  Booking? getBookingById(int bookingId) {
    try {
      return _allBookings
          .firstWhere((booking) => booking.bookingId == bookingId);
    } catch (e) {
      // Booking not found
      print('Booking with ID $bookingId not found in UserBookingsProvider.');
      return null;
    }
  }

  // TODO: Add methods for specific booking actions if needed, e.g., cancelBooking(int bookingId)
}
