import 'package:e_rents_desktop/models/statistics/monthly_revenue.dart';
import 'package:e_rents_desktop/models/statistics/financial_summary_dto.dart';

/// API model for financial statistics from backend
/// This is different from the UI model used by the provider
class FinancialStatisticsApi {
  final double currentMonthRevenue;
  final double previousMonthRevenue;
  final double projectedRevenue;
  final List<MonthlyRevenue> revenueHistory;
  final Map<String, double> revenueByPropertyType;

  FinancialStatisticsApi({
    required this.currentMonthRevenue,
    required this.previousMonthRevenue,
    required this.projectedRevenue,
    required this.revenueHistory,
    required this.revenueByPropertyType,
  });

  factory FinancialStatisticsApi.fromJson(Map<String, dynamic> json) {
    // Convert revenueByPropertyType from JSON
    Map<String, double> revenueByType = {};
    if (json['revenueByPropertyType'] != null) {
      json['revenueByPropertyType'].forEach((key, value) {
        revenueByType[key] = value.toDouble();
      });
    }

    return FinancialStatisticsApi(
      currentMonthRevenue: json['currentMonthRevenue']?.toDouble() ?? 0.0,
      previousMonthRevenue: json['previousMonthRevenue']?.toDouble() ?? 0.0,
      projectedRevenue: json['projectedRevenue']?.toDouble() ?? 0.0,
      revenueHistory:
          (json['revenueHistory'] as List<dynamic>?)
              ?.map((item) => MonthlyRevenue.fromJson(item))
              .toList() ??
          [],
      revenueByPropertyType: revenueByType,
    );
  }

  // Convert from FinancialSummaryDto to FinancialStatisticsApi for UI compatibility
  factory FinancialStatisticsApi.fromSummaryDto(FinancialSummaryDto dto) {
    return FinancialStatisticsApi(
      currentMonthRevenue: dto.totalRentIncome,
      previousMonthRevenue: 0.0, // Not available in summary
      projectedRevenue: dto.netTotal,
      revenueHistory: [], // Not available in simple summary
      revenueByPropertyType: {}, // Not available in simple summary
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentMonthRevenue': currentMonthRevenue,
      'previousMonthRevenue': previousMonthRevenue,
      'projectedRevenue': projectedRevenue,
      'revenueHistory': revenueHistory.map((item) => item.toJson()).toList(),
      'revenueByPropertyType': revenueByPropertyType,
    };
  }
}
