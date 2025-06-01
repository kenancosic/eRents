import 'package:e_rents_desktop/models/statistics/monthly_revenue.dart';

class FinancialSummaryDto {
  final double totalRentIncome;
  final double totalMaintenanceCosts;
  final double otherIncome;
  final double otherExpenses;
  final double netTotal;
  final List<MonthlyRevenueDto> revenueHistory;

  FinancialSummaryDto({
    required this.totalRentIncome,
    required this.totalMaintenanceCosts,
    required this.otherIncome,
    required this.otherExpenses,
    required this.netTotal,
    required this.revenueHistory,
  });

  factory FinancialSummaryDto.fromJson(Map<String, dynamic> json) {
    List<MonthlyRevenueDto> history = [];
    if (json['revenueHistory'] != null && json['revenueHistory'] is List) {
      history =
          (json['revenueHistory'] as List)
              .map(
                (item) =>
                    MonthlyRevenueDto.fromJson(item as Map<String, dynamic>),
              )
              .toList();
    }

    return FinancialSummaryDto(
      totalRentIncome: (json['totalRentIncome'] ?? 0.0).toDouble(),
      totalMaintenanceCosts: (json['totalMaintenanceCosts'] ?? 0.0).toDouble(),
      otherIncome: (json['otherIncome'] ?? 0.0).toDouble(),
      otherExpenses: (json['otherExpenses'] ?? 0.0).toDouble(),
      netTotal: (json['netTotal'] ?? 0.0).toDouble(),
      revenueHistory: history,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRentIncome': totalRentIncome,
      'totalMaintenanceCosts': totalMaintenanceCosts,
      'otherIncome': otherIncome,
      'otherExpenses': otherExpenses,
      'netTotal': netTotal,
      'revenueHistory': revenueHistory.map((item) => item.toJson()).toList(),
    };
  }
}

class MonthlyRevenueDto {
  final int year;
  final int month;
  final double revenue;
  final double maintenanceCosts;

  MonthlyRevenueDto({
    required this.year,
    required this.month,
    required this.revenue,
    required this.maintenanceCosts,
  });

  factory MonthlyRevenueDto.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenueDto(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      revenue: (json['revenue'] ?? 0.0).toDouble(),
      maintenanceCosts: (json['maintenanceCosts'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'revenue': revenue,
      'maintenanceCosts': maintenanceCosts,
    };
  }
}
