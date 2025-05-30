import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/services/booking_service.dart';
import 'package:e_rents_desktop/services/review_service.dart';
import 'package:e_rents_desktop/services/statistics_service.dart';

class PropertyDetailsProvider extends BaseProvider<Property> {
  final BookingService _bookingService;
  final ReviewService _reviewService;
  final StatisticsService _statisticsService;

  PropertyDetailsProvider(
    this._bookingService,
    this._reviewService,
    this._statisticsService,
  );

  // Property statistics
  PropertyBookingStats? _bookingStats;
  PropertyReviewStats? _reviewStats;

  // Property data
  List<BookingSummary> _currentBookings = [];
  List<BookingSummary> _upcomingBookings = [];
  List<BookingSummary> _recentBookings = [];
  List<Review> _reviews = [];

  // Loading state
  bool _isLoadingDetails = false;
  String? _detailsError;

  // Getters
  PropertyBookingStats? get bookingStats => _bookingStats;
  PropertyReviewStats? get reviewStats => _reviewStats;
  List<BookingSummary> get currentBookings => _currentBookings;
  List<BookingSummary> get upcomingBookings => _upcomingBookings;
  List<BookingSummary> get recentBookings => _recentBookings;
  List<Review> get reviews => _reviews;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get detailsError => _detailsError;

  // Convenience getters for UI
  int get totalBookings => _bookingStats?.totalBookings ?? 0;
  double get totalRevenue => _bookingStats?.totalRevenue ?? 0.0;
  double get averageRating => _reviewStats?.averageRating ?? 0.0;
  int get totalReviews => _reviewStats?.totalReviews ?? 0;
  double get occupancyRate => _bookingStats?.occupancyRate ?? 0.0;
  int get currentOccupancy => _bookingStats?.currentOccupancy ?? 0;

  // Current tenant info
  BookingSummary? get currentTenant =>
      _currentBookings.isNotEmpty ? _currentBookings.first : null;

  Future<void> loadPropertyDetails(String propertyId) async {
    // Set loading state immediately without triggering setState during build
    _isLoadingDetails = true;
    _detailsError = null;

    // Schedule the actual loading for the next frame to avoid setState during build
    Future.microtask(() async {
      try {
        // Load all data concurrently
        await Future.wait([
          _loadBookingStats(propertyId),
          _loadReviewStats(propertyId),
          _loadBookings(propertyId),
          _loadReviews(propertyId),
        ]);

        _isLoadingDetails = false;
        _detailsError = null;
      } catch (e) {
        _isLoadingDetails = false;
        _detailsError = e.toString();
        print('Error loading property details: $e');
      }

      // Only trigger setState after the initial build is complete
      notifyListeners();
    });
  }

  Future<void> _loadBookingStats(String propertyId) async {
    try {
      _bookingStats = await _bookingService.getPropertyBookingStats(propertyId);
    } catch (e) {
      print('Error loading booking stats: $e');
      _bookingStats = PropertyBookingStats(
        totalBookings: 0,
        totalRevenue: 0.0,
        averageBookingValue: 0.0,
        currentOccupancy: 0,
        occupancyRate: 0.0,
      );
    }
  }

  Future<void> _loadReviewStats(String propertyId) async {
    try {
      _reviewStats = await _reviewService.getPropertyReviewStats(propertyId);
    } catch (e) {
      print('Error loading review stats: $e');
      _reviewStats = PropertyReviewStats(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {},
        recentReviews: [],
      );
    }
  }

  Future<void> _loadBookings(String propertyId) async {
    try {
      final futures = await Future.wait([
        _bookingService.getCurrentBookings(propertyId),
        _bookingService.getUpcomingBookings(propertyId),
        _bookingService.getPropertyBookings(propertyId),
      ]);

      _currentBookings = futures[0];
      _upcomingBookings = futures[1];
      _recentBookings = futures[2].take(5).toList(); // Last 5 bookings
    } catch (e) {
      print('Error loading bookings: $e');
      _currentBookings = [];
      _upcomingBookings = [];
      _recentBookings = [];
    }
  }

  Future<void> _loadReviews(String propertyId) async {
    try {
      _reviews = await _reviewService.getPropertyReviews(propertyId);
      // Sort by date, most recent first
      _reviews.sort((a, b) => b.dateReported.compareTo(a.dateReported));
    } catch (e) {
      print('Error loading reviews: $e');
      _reviews = [];
    }
  }

  @override
  String get endpoint => '/properties';

  @override
  Property fromJson(Map<String, dynamic> json) {
    return Property.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(Property item) {
    return item.toJson();
  }

  @override
  List<Property> getMockItems() {
    return [];
  }
}
