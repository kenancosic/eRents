import '../../../base/base.dart';
import '../../../services/booking_service.dart';
import '../../../services/review_service.dart';
import '../../../services/maintenance_service.dart';
import '../../../models/booking_summary.dart';
import '../../../models/maintenance_issue.dart';

/// Statistics provider for property analytics
///
/// Handles property-specific statistics like booking stats, review stats,
/// and occupancy metrics. Uses StateProvider for simple state management.
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
  Future<void> loadPropertyStats(String propertyId) async {
    try {
      _currentPropertyId = propertyId;

      // Load all stats concurrently
      final futures = await Future.wait([
        _loadBookingStats(propertyId),
        _loadReviewStats(propertyId),
        _loadFinancialStats(propertyId),
        _loadOccupancyStats(propertyId),
        _loadCurrentBookings(propertyId),
        _loadUpcomingBookings(propertyId),
        _loadMaintenanceIssues(propertyId),
      ]);

      final bookingStats = futures[0] as PropertyBookingStats?;
      final reviewStats = futures[1] as PropertyReviewStats?;
      final financialStats = futures[2] as PropertyFinancialStats?;
      final occupancyStats = futures[3] as PropertyOccupancyStats?;
      final currentBookings = futures[4] as List<BookingSummary>;
      final upcomingBookings = futures[5] as List<BookingSummary>;
      final maintenanceIssues = futures[6] as List<MaintenanceIssue>;

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
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Refresh stats for current property
  Future<void> refreshStats() async {
    if (_currentPropertyId != null) {
      await loadPropertyStats(_currentPropertyId!);
    }
  }

  /// Clear current stats
  void clearStats() {
    _currentPropertyId = null;
    updateState(null);
  }

  // Private methods for loading individual stat types

  Future<PropertyBookingStats?> _loadBookingStats(String propertyId) async {
    try {
      // Use the BookingService which has the correct method
      final bookingStats = await _bookingService.getPropertyBookingStats(
        propertyId,
      );
      return bookingStats;
    } catch (e) {
      print('Error loading booking stats: $e');
      return PropertyBookingStats(
        totalBookings: 0,
        totalRevenue: 0.0,
        averageBookingValue: 0.0,
        currentOccupancy: 0,
        occupancyRate: 0.0,
      );
    }
  }

  Future<PropertyReviewStats?> _loadReviewStats(String propertyId) async {
    try {
      // Use the ReviewService to call the actual backend endpoint
      final reviewStats = await _reviewService.getPropertyReviewStats(
        propertyId,
      );
      return reviewStats;
    } catch (e) {
      print('Error loading review stats: $e');
      return PropertyReviewStats(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {},
        recentReviews: [],
      );
    }
  }

  Future<PropertyFinancialStats?> _loadFinancialStats(String propertyId) async {
    try {
      // For now, calculate from booking stats if available
      // This could be enhanced with a dedicated financial stats endpoint
      final bookingStats = await _bookingService.getPropertyBookingStats(
        propertyId,
      );

      return PropertyFinancialStats(
        monthlyRevenue:
            bookingStats.totalRevenue / 12, // Rough monthly estimate
        yearlyRevenue: bookingStats.totalRevenue,
        averageNightlyRate: bookingStats.averageBookingValue,
        profitMargin: 0.0, // Would need cost data
        lastMonthRevenue: 0.0, // Would need historical data
        revenueGrowth: 0.0, // Would need historical data
      );
    } catch (e) {
      print('Error loading financial stats: $e');
      return PropertyFinancialStats(
        monthlyRevenue: 0.0,
        yearlyRevenue: 0.0,
        averageNightlyRate: 0.0,
        profitMargin: 0.0,
        lastMonthRevenue: 0.0,
        revenueGrowth: 0.0,
      );
    }
  }

  Future<PropertyOccupancyStats?> _loadOccupancyStats(String propertyId) async {
    try {
      // Calculate from booking stats if available
      final bookingStats = await _bookingService.getPropertyBookingStats(
        propertyId,
      );

      return PropertyOccupancyStats(
        currentOccupancyRate: bookingStats.occupancyRate,
        monthlyOccupancyRate: bookingStats.occupancyRate,
        yearlyOccupancyRate: bookingStats.occupancyRate,
        averageStayDuration: 0.0, // Would need booking duration data
        totalNightsBooked: 0, // Would need detailed booking data
        totalNightsAvailable: 0, // Would need calendar data
      );
    } catch (e) {
      print('Error loading occupancy stats: $e');
      return PropertyOccupancyStats(
        currentOccupancyRate: 0.0,
        monthlyOccupancyRate: 0.0,
        yearlyOccupancyRate: 0.0,
        averageStayDuration: 0.0,
        totalNightsBooked: 0,
        totalNightsAvailable: 0,
      );
    }
  }

  Future<List<BookingSummary>> _loadCurrentBookings(String propertyId) async {
    try {
      print(
        '🔍 PropertyStatsProvider: Loading current bookings for property ID: $propertyId',
      );
      final result = await _bookingService.getCurrentBookings(propertyId);
      print(
        '✅ PropertyStatsProvider: Found ${result.length} current bookings for property $propertyId',
      );
      return result;
    } catch (e) {
      print('❌ Error loading current bookings for property $propertyId: $e');
      return [];
    }
  }

  Future<List<BookingSummary>> _loadUpcomingBookings(String propertyId) async {
    try {
      print(
        '🔍 PropertyStatsProvider: Loading upcoming bookings for property ID: $propertyId',
      );
      final result = await _bookingService.getUpcomingBookings(propertyId);
      print(
        '✅ PropertyStatsProvider: Found ${result.length} upcoming bookings for property $propertyId',
      );
      return result;
    } catch (e) {
      print('❌ Error loading upcoming bookings for property $propertyId: $e');
      return [];
    }
  }

  Future<List<MaintenanceIssue>> _loadMaintenanceIssues(
    String propertyId,
  ) async {
    try {
      return await _maintenanceService.getMaintenanceIssues(
        queryParams: {'propertyId': propertyId},
      );
    } catch (e) {
      print('Error loading maintenance issues: $e');
      return [];
    }
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

/// Data class for property statistics
class PropertyStatsData {
  final String propertyId;
  final PropertyBookingStats? bookingStats;
  final PropertyReviewStats? reviewStats;
  final PropertyFinancialStats? financialStats;
  final PropertyOccupancyStats? occupancyStats;
  final List<BookingSummary> currentBookings;
  final List<BookingSummary> upcomingBookings;
  final List<MaintenanceIssue> maintenanceIssues;
  final DateTime lastUpdated;

  PropertyStatsData({
    required this.propertyId,
    this.bookingStats,
    this.reviewStats,
    this.financialStats,
    this.occupancyStats,
    this.currentBookings = const [],
    this.upcomingBookings = const [],
    this.maintenanceIssues = const [],
    required this.lastUpdated,
  });

  /// Check if stats are recent (less than 1 hour old)
  bool get isRecent {
    return DateTime.now().difference(lastUpdated).inHours < 1;
  }

  /// Check if all stats are loaded
  bool get isComplete {
    return bookingStats != null &&
        reviewStats != null &&
        financialStats != null &&
        occupancyStats != null;
  }
}

/// Financial statistics for a property
class PropertyFinancialStats {
  final double monthlyRevenue;
  final double yearlyRevenue;
  final double averageNightlyRate;
  final double profitMargin;
  final double lastMonthRevenue;
  final double revenueGrowth;

  PropertyFinancialStats({
    required this.monthlyRevenue,
    required this.yearlyRevenue,
    required this.averageNightlyRate,
    required this.profitMargin,
    required this.lastMonthRevenue,
    required this.revenueGrowth,
  });
}

/// Occupancy statistics for a property
class PropertyOccupancyStats {
  final double currentOccupancyRate;
  final double monthlyOccupancyRate;
  final double yearlyOccupancyRate;
  final double averageStayDuration;
  final int totalNightsBooked;
  final int totalNightsAvailable;

  PropertyOccupancyStats({
    required this.currentOccupancyRate,
    required this.monthlyOccupancyRate,
    required this.yearlyOccupancyRate,
    required this.averageStayDuration,
    required this.totalNightsBooked,
    required this.totalNightsAvailable,
  });

  /// Calculate utilization efficiency
  double get utilizationEfficiency {
    if (totalNightsAvailable == 0) return 0.0;
    return totalNightsBooked / totalNightsAvailable;
  }
}
