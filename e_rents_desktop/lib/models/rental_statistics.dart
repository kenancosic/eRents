/// Unified statistics model combining booking and rental request data
class RentalStatistics {
  // === STAY (BOOKING) STATISTICS ===
  final int totalStays;
  final int activeStays;
  final int upcomingStays;
  final int completedStays;
  final int cancelledStays;
  final double stayRevenue;

  // === LEASE (RENTAL REQUEST) STATISTICS ===
  final int totalLeaseRequests;
  final int pendingLeaseRequests;
  final int approvedLeaseRequests;
  final int rejectedLeaseRequests;
  final int activeLeases;
  final double leaseRevenue;

  // === COMBINED STATISTICS ===
  final int totalRentals;
  final double totalRevenue;

  const RentalStatistics({
    // Stay statistics
    required this.totalStays,
    required this.activeStays,
    required this.upcomingStays,
    required this.completedStays,
    required this.cancelledStays,
    required this.stayRevenue,

    // Lease statistics
    required this.totalLeaseRequests,
    required this.pendingLeaseRequests,
    required this.approvedLeaseRequests,
    required this.rejectedLeaseRequests,
    required this.activeLeases,
    required this.leaseRevenue,

    // Combined
    required this.totalRentals,
    required this.totalRevenue,
  });

  /// Factory to combine booking and rental request statistics
  factory RentalStatistics.combine(
    Map<String, dynamic> bookingStats,
    Map<String, dynamic> rentalRequestStats,
  ) {
    // Extract booking statistics
    final totalStays = bookingStats['totalBookings'] ?? 0;
    final activeStays = bookingStats['activeBookings'] ?? 0;
    final upcomingStays = bookingStats['upcomingBookings'] ?? 0;
    final completedStays = bookingStats['completedBookings'] ?? 0;
    final cancelledStays = bookingStats['cancelledBookings'] ?? 0;
    final stayRevenue = (bookingStats['totalRevenue'] ?? 0.0).toDouble();

    // Extract rental request statistics
    final totalLeaseRequests = rentalRequestStats['totalRequests'] ?? 0;
    final pendingLeaseRequests = rentalRequestStats['pendingRequests'] ?? 0;
    final approvedLeaseRequests = rentalRequestStats['approvedRequests'] ?? 0;
    final rejectedLeaseRequests = rentalRequestStats['rejectedRequests'] ?? 0;
    final activeLeases =
        approvedLeaseRequests; // Approved requests become active leases
    final leaseRevenue = (rentalRequestStats['totalRevenue'] ?? 0.0).toDouble();

    return RentalStatistics(
      // Stay statistics
      totalStays: totalStays,
      activeStays: activeStays,
      upcomingStays: upcomingStays,
      completedStays: completedStays,
      cancelledStays: cancelledStays,
      stayRevenue: stayRevenue,

      // Lease statistics
      totalLeaseRequests: totalLeaseRequests,
      pendingLeaseRequests: pendingLeaseRequests,
      approvedLeaseRequests: approvedLeaseRequests,
      rejectedLeaseRequests: rejectedLeaseRequests,
      activeLeases: activeLeases,
      leaseRevenue: leaseRevenue,

      // Combined
      totalRentals: totalStays + totalLeaseRequests,
      totalRevenue: stayRevenue + leaseRevenue,
    );
  }

  /// Factory for empty statistics
  factory RentalStatistics.empty() {
    return const RentalStatistics(
      totalStays: 0,
      activeStays: 0,
      upcomingStays: 0,
      completedStays: 0,
      cancelledStays: 0,
      stayRevenue: 0.0,
      totalLeaseRequests: 0,
      pendingLeaseRequests: 0,
      approvedLeaseRequests: 0,
      rejectedLeaseRequests: 0,
      activeLeases: 0,
      leaseRevenue: 0.0,
      totalRentals: 0,
      totalRevenue: 0.0,
    );
  }

  /// Get stay (booking) approval rate
  double get stayCompletionRate {
    if (totalStays == 0) return 0.0;
    return (completedStays / totalStays) * 100;
  }

  /// Get lease request approval rate
  double get leaseApprovalRate {
    if (totalLeaseRequests == 0) return 0.0;
    return (approvedLeaseRequests / totalLeaseRequests) * 100;
  }

  /// Get overall rental performance score
  double get overallPerformanceScore {
    final stayScore = totalStays > 0 ? stayCompletionRate : 0.0;
    final leaseScore = totalLeaseRequests > 0 ? leaseApprovalRate : 0.0;

    if (totalStays > 0 && totalLeaseRequests > 0) {
      return (stayScore + leaseScore) / 2;
    } else if (totalStays > 0) {
      return stayScore;
    } else if (totalLeaseRequests > 0) {
      return leaseScore;
    } else {
      return 0.0;
    }
  }

  /// Get formatted total revenue
  String get formattedTotalRevenue => '${totalRevenue.toStringAsFixed(2)} BAM';

  /// Get formatted stay revenue
  String get formattedStayRevenue => '${stayRevenue.toStringAsFixed(2)} BAM';

  /// Get formatted lease revenue
  String get formattedLeaseRevenue => '${leaseRevenue.toStringAsFixed(2)} BAM';

  /// Convert to JSON for caching or API transmission
  Map<String, dynamic> toJson() {
    return {
      // Stay statistics
      'totalStays': totalStays,
      'activeStays': activeStays,
      'upcomingStays': upcomingStays,
      'completedStays': completedStays,
      'cancelledStays': cancelledStays,
      'stayRevenue': stayRevenue,

      // Lease statistics
      'totalLeaseRequests': totalLeaseRequests,
      'pendingLeaseRequests': pendingLeaseRequests,
      'approvedLeaseRequests': approvedLeaseRequests,
      'rejectedLeaseRequests': rejectedLeaseRequests,
      'activeLeases': activeLeases,
      'leaseRevenue': leaseRevenue,

      // Combined
      'totalRentals': totalRentals,
      'totalRevenue': totalRevenue,
    };
  }

  /// Create from JSON
  factory RentalStatistics.fromJson(Map<String, dynamic> json) {
    return RentalStatistics(
      // Stay statistics
      totalStays: json['totalStays'] ?? 0,
      activeStays: json['activeStays'] ?? 0,
      upcomingStays: json['upcomingStays'] ?? 0,
      completedStays: json['completedStays'] ?? 0,
      cancelledStays: json['cancelledStays'] ?? 0,
      stayRevenue: (json['stayRevenue'] ?? 0.0).toDouble(),

      // Lease statistics
      totalLeaseRequests: json['totalLeaseRequests'] ?? 0,
      pendingLeaseRequests: json['pendingLeaseRequests'] ?? 0,
      approvedLeaseRequests: json['approvedLeaseRequests'] ?? 0,
      rejectedLeaseRequests: json['rejectedLeaseRequests'] ?? 0,
      activeLeases: json['activeLeases'] ?? 0,
      leaseRevenue: (json['leaseRevenue'] ?? 0.0).toDouble(),

      // Combined
      totalRentals: json['totalRentals'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0.0).toDouble(),
    );
  }

  @override
  String toString() {
    return 'RentalStatistics(totalRentals: $totalRentals, totalRevenue: $formattedTotalRevenue, activeStays: $activeStays, activeLeases: $activeLeases, pending: $pendingLeaseRequests)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RentalStatistics &&
          runtimeType == other.runtimeType &&
          totalStays == other.totalStays &&
          activeStays == other.activeStays &&
          totalLeaseRequests == other.totalLeaseRequests &&
          pendingLeaseRequests == other.pendingLeaseRequests &&
          totalRevenue == other.totalRevenue;

  @override
  int get hashCode =>
      totalStays.hashCode ^
      activeStays.hashCode ^
      totalLeaseRequests.hashCode ^
      pendingLeaseRequests.hashCode ^
      totalRevenue.hashCode;
}
