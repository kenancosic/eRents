import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/booking_summary.dart';
import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/services/booking_service.dart';
import 'package:e_rents_desktop/services/review_service.dart';
import 'package:e_rents_desktop/services/statistics_service.dart';
import 'package:e_rents_desktop/services/maintenance_service.dart';

class PropertyDetailsProvider extends BaseProvider<Property> {
  final BookingService _bookingService;
  final ReviewService _reviewService;
  final StatisticsService _statisticsService;
  final MaintenanceService _maintenanceService;

  PropertyDetailsProvider(
    this._bookingService,
    this._reviewService,
    this._statisticsService,
    this._maintenanceService,
  );

  // Property statistics
  PropertyBookingStats? _bookingStats;
  PropertyReviewStats? _reviewStats;

  // Property data
  List<BookingSummary> _currentBookings = [];
  List<BookingSummary> _upcomingBookings = [];
  List<BookingSummary> _recentBookings = [];
  List<Review> _reviews = [];
  List<MaintenanceIssue> _maintenanceIssues = [];

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
  List<MaintenanceIssue> get fetchedMaintenanceIssues => _maintenanceIssues;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get detailsError => _detailsError;

  // Method to manually control loading and error states from outside if needed
  void setLoadingState(bool isLoading, [String? error]) {
    _isLoadingDetails = isLoading;
    _detailsError = error;
    if (isLoading) {
      // Optionally, could map this to BaseProvider's ViewState if desired
      // setState(ViewState.Busy); // If using BaseProvider's state directly
    } else if (error != null) {
      // setState(ViewState.Error); // If using BaseProvider's state directly
    } else {
      // setState(ViewState.Idle); // If using BaseProvider's state directly
    }
    notifyListeners();
  }

  // Convenience getters for UI
  int get totalBookings => _bookingStats?.totalBookings ?? 0;
  double get totalRevenue => _bookingStats?.totalRevenue ?? 0.0;
  double get averageRating => _reviewStats?.averageRating ?? 0.0;
  int get totalReviews => _reviewStats?.totalReviews ?? 0;
  double get occupancyRate => _bookingStats?.occupancyRate ?? 0.0;
  int get currentOccupancy => _bookingStats?.currentOccupancy ?? 0;

  // Maintenance convenience getters
  int get totalMaintenanceIssues => _maintenanceIssues.length;
  int get pendingMaintenanceIssues =>
      _maintenanceIssues
          .where((issue) => issue.status == IssueStatus.pending)
          .length;
  int get inProgressMaintenanceIssues =>
      _maintenanceIssues
          .where((issue) => issue.status == IssueStatus.inProgress)
          .length;

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
          _loadMaintenanceIssues(propertyId),
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
      _reviews.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
    } catch (e) {
      print('Error loading reviews: $e');
      _reviews = [];
    }
  }

  Future<void> _loadMaintenanceIssues(String propertyId) async {
    try {
      print(
        'PropertyDetailsProvider: Loading maintenance issues for property $propertyId',
      );
      final propertyIdInt = int.tryParse(propertyId);
      if (propertyIdInt != null) {
        print(
          'PropertyDetailsProvider: Calling maintenance service with PropertyId: $propertyIdInt and Status: Pending,InProgress',
        );
        _maintenanceIssues = await _maintenanceService.getIssues(
          queryParams: {
            'PropertyId': propertyIdInt.toString(),
            'Status': 'Pending,InProgress',
          },
        );
        _maintenanceIssues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        print(
          'PropertyDetailsProvider: Successfully loaded ${_maintenanceIssues.length} maintenance issues for property $propertyId',
        );
      } else {
        print(
          'PropertyDetailsProvider: Invalid propertyId format: $propertyId',
        );
        _maintenanceIssues = [];
      }
    } catch (e) {
      print('Error loading maintenance issues: $e');
      _maintenanceIssues = [];
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
