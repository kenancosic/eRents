import 'package:flutter/foundation.dart';
import '../../../base/base.dart';
import '../../../models/property_stats_data.dart';
import '../../../services/booking_service.dart';
import '../../../services/review_service.dart';
import '../../../services/maintenance_service.dart';
import '../../../models/booking_summary.dart';
import '../../../models/maintenance_issue.dart';

/// Statistics provider for property analytics
///
/// Handles property-specific statistics like booking stats, review stats,
/// and occupancy metrics. Uses StateProvider with enhanced lifecycle management.
class PropertyStatsProvider extends StateProvider<PropertyStatsData?> {
  final BookingService _bookingService;
  final ReviewService _reviewService;
  final MaintenanceService _maintenanceService;

  PropertyStatsProvider(
    this._bookingService,
    this._reviewService,
    this._maintenanceService,
  ) : super(null);

  /// Current property ID being tracked
  String? _currentPropertyId;

  /// Get current property ID
  String? get currentPropertyId => _currentPropertyId;

  /// Get current stats data
  PropertyStatsData? get stats => state;

  /// Check if stats are loaded
  bool get hasStats => state != null;

  /// Check if stats are for the given property
  bool isStatsFor(String propertyId) => _currentPropertyId == propertyId;

  // Loading and data management

  /// Load all statistics for a property
  Future<void> loadPropertyStats(
    String propertyId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && state != null && _currentPropertyId == propertyId) {
      return;
    }
    await executeAsync(() async {
      _currentPropertyId = propertyId;

      debugPrint(
        '🏠 PropertyStatsProvider: Loading stats for property $propertyId',
      );

      // Load all stats concurrently
      final futures = await Future.wait([
        _bookingService.getPropertyBookingStats(propertyId),
        _reviewService.getPropertyReviewStats(propertyId),
        _bookingService.getCurrentBookings(propertyId),
        _bookingService.getUpcomingBookings(propertyId),
        _maintenanceService.getMaintenanceIssues(
          queryParams: {'propertyId': propertyId},
        ),
      ]);

      final bookingStats = futures[0] as PropertyBookingStats?;
      final reviewStats = futures[1] as PropertyReviewStats?;
      final currentBookings = futures[2] as List<BookingSummary>;
      final upcomingBookings = futures[3] as List<BookingSummary>;
      final maintenanceIssues = futures[4] as List<MaintenanceIssue>;

      // Financial and Occupancy stats are derived from booking stats for now
      final financialStats = _deriveFinancialStats(bookingStats);
      final occupancyStats = _deriveOccupancyStats(bookingStats);

      final statsData = PropertyStatsData(
        propertyId: propertyId,
        bookingStats: bookingStats,
        reviewStats: reviewStats,
        financialStats: financialStats,
        occupancyStats: occupancyStats,
        currentBookings: currentBookings,
        upcomingBookings: upcomingBookings,
        maintenanceIssues: maintenanceIssues,
        lastUpdated: DateTime.now(),
      );

      updateState(statsData);

      debugPrint(
        '🏠 PropertyStatsProvider: Successfully loaded stats for property $propertyId',
      );
    });
  }

  /// Refresh stats for current property
  Future<void> refreshStats() async {
    if (_currentPropertyId != null) {
      await loadPropertyStats(_currentPropertyId!, forceRefresh: true);
    }
  }

  /// Clear current stats
  void clearStats() {
    if (disposed) return;

    _currentPropertyId = null;
    updateState(null);
  }

  // Private methods for deriving stat models

  PropertyFinancialStats? _deriveFinancialStats(
    PropertyBookingStats? bookingStats,
  ) {
    if (bookingStats == null) return null;
    return PropertyFinancialStats(
      monthlyRevenue: bookingStats.totalRevenue / 12, // Rough monthly estimate
      yearlyRevenue: bookingStats.totalRevenue,
      averageNightlyRate: bookingStats.averageBookingValue,
      profitMargin: 0.0, // Placeholder
      lastMonthRevenue: 0.0, // Placeholder
      revenueGrowth: 0.0, // Placeholder
    );
  }

  PropertyOccupancyStats? _deriveOccupancyStats(
    PropertyBookingStats? bookingStats,
  ) {
    if (bookingStats == null) return null;
    return PropertyOccupancyStats(
      currentOccupancyRate: bookingStats.occupancyRate,
      monthlyOccupancyRate: bookingStats.occupancyRate, // Placeholder
      yearlyOccupancyRate: bookingStats.occupancyRate, // Placeholder
      averageStayDuration: 0.0, // Placeholder
      totalNightsBooked: 0, // Placeholder
      totalNightsAvailable: 0, // Placeholder
    );
  }

  // Convenience getters for UI

  /// Get total bookings safely
  int get totalBookings => stats?.bookingStats?.totalBookings ?? 0;

  /// Get total revenue safely
  double get totalRevenue => stats?.bookingStats?.totalRevenue ?? 0.0;

  /// Get average rating safely
  double get averageRating => stats?.reviewStats?.averageRating ?? 0.0;

  /// Get total reviews safely
  int get totalReviews => stats?.reviewStats?.totalReviews ?? 0;

  /// Get occupancy rate safely
  double get occupancyRate => stats?.bookingStats?.occupancyRate ?? 0.0;

  /// Get current occupancy safely
  int get currentOccupancy => stats?.bookingStats?.currentOccupancy ?? 0;

  /// Get monthly revenue safely
  double get monthlyRevenue => stats?.financialStats?.monthlyRevenue ?? 0.0;

  /// Get average nightly rate safely
  double get averageNightlyRate =>
      stats?.financialStats?.averageNightlyRate ?? 0.0;

  /// Get current occupancy rate safely
  double get currentOccupancyRate =>
      stats?.occupancyStats?.currentOccupancyRate ?? 0.0;

  /// Get average stay duration safely
  double get averageStayDuration =>
      stats?.occupancyStats?.averageStayDuration ?? 0.0;

  /// Get current bookings safely
  List<BookingSummary> get currentBookings => stats?.currentBookings ?? [];

  /// Get upcoming bookings safely
  List<BookingSummary> get upcomingBookings => stats?.upcomingBookings ?? [];

  /// Get maintenance issues safely
  List<MaintenanceIssue> get maintenanceIssues =>
      stats?.maintenanceIssues ?? [];

  /// Get current tenant from current bookings
  BookingSummary? get currentTenant =>
      currentBookings.isNotEmpty ? currentBookings.first : null;

  // Formatted getters for UI display

  /// Get formatted revenue string
  String getFormattedRevenue([String currency = 'BAM']) {
    return '${totalRevenue.toStringAsFixed(0)} $currency';
  }

  /// Get formatted average rating
  String getFormattedRating() {
    if (totalReviews == 0) return 'No reviews';
    return '${averageRating.toStringAsFixed(1)} ($totalReviews review${totalReviews != 1 ? 's' : ''})';
  }

  /// Get formatted occupancy rate
  String getFormattedOccupancyRate() {
    return '${(occupancyRate * 100).toStringAsFixed(1)}%';
  }

  /// Get stats summary for display
  String getStatsSummary() {
    if (!hasStats) return 'No statistics available';

    return '$totalBookings bookings, ${getFormattedRevenue()}, ${getFormattedOccupancyRate()} occupancy';
  }

  // Performance metrics

  /// Check if property is performing well
  bool get isPerformingWell {
    return occupancyRate > 0.7 && averageRating > 4.0 && totalBookings > 5;
  }

  /// Get performance indicator
  String get performanceIndicator {
    if (!hasStats) return 'Unknown';

    if (occupancyRate > 0.8 && averageRating > 4.5) return 'Excellent';
    if (occupancyRate > 0.6 && averageRating > 4.0) return 'Good';
    if (occupancyRate > 0.4 && averageRating > 3.5) return 'Average';
    return 'Needs Improvement';
  }
}
