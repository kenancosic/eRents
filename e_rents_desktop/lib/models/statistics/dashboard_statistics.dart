class DashboardStatistics {
  final int totalProperties;
  final int occupiedProperties;
  final double occupancyRate;
  final double averageRating;
  final List<PopularProperty> topProperties;
  final int pendingMaintenanceIssues;
  final double monthlyRevenue;
  final double yearlyRevenue;
  // Financial details - consolidated from FinancialSummaryDto
  final double totalRentIncome;
  final double totalMaintenanceCosts;
  final double netTotal;

  DashboardStatistics({
    required this.totalProperties,
    required this.occupiedProperties,
    required this.occupancyRate,
    required this.averageRating,
    required this.topProperties,
    required this.pendingMaintenanceIssues,
    required this.monthlyRevenue,
    required this.yearlyRevenue,
    required this.totalRentIncome,
    required this.totalMaintenanceCosts,
    required this.netTotal,
  });

  factory DashboardStatistics.fromJson(Map<String, dynamic> json) {
    return DashboardStatistics(
      // Map from quick-metrics response format
      totalProperties: json['PropertiesCount'] ?? json['totalProperties'] ?? 0,
      occupiedProperties: json['ActiveBookings'] ?? json['occupiedProperties'] ?? 0,
      occupancyRate: json['occupancyRate']?.toDouble() ?? 0.0,
      averageRating: json['averageRating']?.toDouble() ?? 0.0,
      topProperties:
          (json['topProperties'] as List<dynamic>?)
              ?.map((property) => PopularProperty.fromJson(property))
              .toList() ??
          [],
      pendingMaintenanceIssues: json['pendingMaintenanceIssues'] ?? 0,
      monthlyRevenue: json['MonthlyAverage'] ?? json['monthlyRevenue']?.toDouble() ?? 0.0,
      yearlyRevenue: json['TotalIncome'] ?? json['yearlyRevenue']?.toDouble() ?? 0.0,
      totalRentIncome: json['TotalIncome'] ?? json['totalRentIncome']?.toDouble() ?? 0.0,
      totalMaintenanceCosts: json['TotalExpenses'] ?? json['totalMaintenanceCosts']?.toDouble() ?? 0.0,
      netTotal: json['NetProfit'] ?? json['netTotal']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalProperties': totalProperties,
      'occupiedProperties': occupiedProperties,
      'occupancyRate': occupancyRate,
      'averageRating': averageRating,
      'topProperties': topProperties.map((e) => e.toJson()).toList(),
      'pendingMaintenanceIssues': pendingMaintenanceIssues,
      'monthlyRevenue': monthlyRevenue,
      'yearlyRevenue': yearlyRevenue,
      'totalRentIncome': totalRentIncome,
      'totalMaintenanceCosts': totalMaintenanceCosts,
      'netTotal': netTotal,
    };
  }
}

class PopularProperty {
  final int propertyId;
  final String name;
  final int bookingCount;
  final double totalRevenue;
  final double? averageRating;

  PopularProperty({
    required this.propertyId,
    required this.name,
    required this.bookingCount,
    required this.totalRevenue,
    this.averageRating,
  });

  factory PopularProperty.fromJson(Map<String, dynamic> json) {
    return PopularProperty(
      propertyId: json['propertyId'] ?? 0,
      name: json['name'] ?? '',
      bookingCount: json['bookingCount'] ?? 0,
      totalRevenue: json['totalRevenue']?.toDouble() ?? 0.0,
      averageRating: json['averageRating']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'name': name,
      'bookingCount': bookingCount,
      'totalRevenue': totalRevenue,
      'averageRating': averageRating,
    };
  }
}
