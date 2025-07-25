import 'package:e_rents_desktop/models/booking_summary.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/utils/formatters.dart';

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

  factory PropertyStatsData.fromJson(Map<String, dynamic> json) {
    return PropertyStatsData(
      propertyId: json['propertyId'] ?? '',
      bookingStats: json['bookingStats'] != null
          ? PropertyBookingStats.fromJson(json['bookingStats'])
          : null,
      reviewStats: json['reviewStats'] != null
          ? PropertyReviewStats.fromJson(json['reviewStats'])
          : null,
      financialStats: json['financialStats'] != null
          ? PropertyFinancialStats.fromJson(json['financialStats'])
          : null,
      occupancyStats: json['occupancyStats'] != null
          ? PropertyOccupancyStats.fromJson(json['occupancyStats'])
          : null,
      currentBookings: (json['currentBookings'] as List<dynamic>? ?? [])
          .map((item) => BookingSummary.fromJson(item))
          .toList(),
      upcomingBookings: (json['upcomingBookings'] as List<dynamic>? ?? [])
          .map((item) => BookingSummary.fromJson(item))
          .toList(),
      maintenanceIssues: (json['maintenanceIssues'] as List<dynamic>? ?? [])
          .map((item) => MaintenanceIssue.fromJson(item))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

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

  String getFormattedRevenue() {
    return kCurrencyFormat.format(financialStats?.yearlyRevenue ?? 0);
  }

  String getFormattedRating() {
    return reviewStats?.averageRating.toStringAsFixed(1) ?? 'N/A';
  }

  String getFormattedOccupancyRate() {
    final rate = occupancyStats?.currentOccupancyRate ?? 0;
    return '${(rate * 100).toStringAsFixed(1)}%';
  }

  String get performanceIndicator {
    final rating = reviewStats?.averageRating ?? 0;
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Good';
    if (rating >= 3.0) return 'Average';
    return 'Needs Improvement';
  }
}

/// Booking statistics for a property
/// Note: This is a simplified version based on what the provider was creating.
/// It might need to be replaced with a proper model from your backend if available.
class PropertyBookingStats {
  final int totalBookings;
  final double totalRevenue;
  final double averageBookingValue;
  final double occupancyRate;
  final int currentOccupancy;

  PropertyBookingStats({
    required this.totalBookings,
    required this.totalRevenue,
    required this.averageBookingValue,
    required this.occupancyRate,
    required this.currentOccupancy,
  });

  factory PropertyBookingStats.fromJson(Map<String, dynamic> json) {
    return PropertyBookingStats(
      totalBookings: json['totalBookings'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      averageBookingValue: (json['averageBookingValue'] as num?)?.toDouble() ?? 0.0,
      occupancyRate: (json['occupancyRate'] as num?)?.toDouble() ?? 0.0,
      currentOccupancy: json['currentOccupancy'] as int? ?? 0,
    );
  }
}

/// Review statistics for a property
class PropertyReviewStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;

  PropertyReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory PropertyReviewStats.fromJson(Map<String, dynamic> json) {
    return PropertyReviewStats(
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      ratingDistribution: _parseRatingDistribution(json['ratingDistribution']),
    );
  }

  static Map<int, int> _parseRatingDistribution(dynamic distribution) {
    if (distribution == null) return {};
    if (distribution is Map<String, dynamic>) {
      return distribution.map(
        (key, value) => MapEntry(int.tryParse(key) ?? 0, value as int? ?? 0),
      );
    }
    return {};
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

  factory PropertyFinancialStats.fromJson(Map<String, dynamic> json) {
    return PropertyFinancialStats(
      monthlyRevenue: (json['monthlyRevenue'] as num?)?.toDouble() ?? 0.0,
      yearlyRevenue: (json['yearlyRevenue'] as num?)?.toDouble() ?? 0.0,
      averageNightlyRate: (json['averageNightlyRate'] as num?)?.toDouble() ?? 0.0,
      profitMargin: (json['profitMargin'] as num?)?.toDouble() ?? 0.0,
      lastMonthRevenue: (json['lastMonthRevenue'] as num?)?.toDouble() ?? 0.0,
      revenueGrowth: (json['revenueGrowth'] as num?)?.toDouble() ?? 0.0,
    );
  }
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

  factory PropertyOccupancyStats.fromJson(Map<String, dynamic> json) {
    return PropertyOccupancyStats(
      currentOccupancyRate: (json['currentOccupancyRate'] as num?)?.toDouble() ?? 0.0,
      monthlyOccupancyRate: (json['monthlyOccupancyRate'] as num?)?.toDouble() ?? 0.0,
      yearlyOccupancyRate: (json['yearlyOccupancyRate'] as num?)?.toDouble() ?? 0.0,
      averageStayDuration: (json['averageStayDuration'] as num?)?.toDouble() ?? 0.0,
      totalNightsBooked: json['totalNightsBooked'] as int? ?? 0,
      totalNightsAvailable: json['totalNightsAvailable'] as int? ?? 0,
    );
  }

  /// Calculate utilization efficiency
  double get utilizationEfficiency {
    if (totalNightsAvailable == 0) return 0.0;
    return totalNightsBooked / totalNightsAvailable;
  }
}
