import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:intl/intl.dart';

class FinancialStatistics {
  final double totalRent;
  final double totalMaintenanceCosts;
  final double netTotal;
  final DateTime startDate;
  final DateTime endDate;
  final List<FinancialReportItem> monthlyBreakdown;

  FinancialStatistics({
    required this.totalRent,
    required this.totalMaintenanceCosts,
    required this.netTotal,
    required this.startDate,
    required this.endDate,
    this.monthlyBreakdown = const [],
  });

  // Formatting helpers
  String get formattedTotalRent => '\$${totalRent.toStringAsFixed(2)}';
  String get formattedTotalMaintenanceCosts =>
      '\$${totalMaintenanceCosts.toStringAsFixed(2)}';
  String get formattedNetTotal => '\$${netTotal.toStringAsFixed(2)}';
  String get formattedDateRange {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    return '${formatter.format(startDate)} - ${formatter.format(endDate)}';
  }

  factory FinancialStatistics.fromJson(Map<String, dynamic> json) {
    List<FinancialReportItem> breakdown = [];
    if (json['monthlyBreakdown'] != null && json['monthlyBreakdown'] is List) {
      breakdown =
          (json['monthlyBreakdown'] as List)
              .map(
                (item) =>
                    FinancialReportItem.fromJson(item as Map<String, dynamic>),
              )
              .toList();
    }

    return FinancialStatistics(
      totalRent: (json['totalRent'] as num?)?.toDouble() ?? 0.0,
      totalMaintenanceCosts:
          (json['totalMaintenanceCosts'] as num?)?.toDouble() ?? 0.0,
      netTotal: (json['netTotal'] as num?)?.toDouble() ?? 0.0,
      startDate: DateTime.parse(
        json['startDate'] as String? ?? DateTime.now().toIso8601String(),
      ),
      endDate: DateTime.parse(
        json['endDate'] as String? ?? DateTime.now().toIso8601String(),
      ),
      monthlyBreakdown: breakdown,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRent': totalRent,
      'totalMaintenanceCosts': totalMaintenanceCosts,
      'netTotal': netTotal,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'monthlyBreakdown':
          monthlyBreakdown.map((item) => item.toJson()).toList(),
    };
  }
}
