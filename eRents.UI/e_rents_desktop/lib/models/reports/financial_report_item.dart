import 'package:intl/intl.dart';

class FinancialReportItem {
  final String dateFrom;
  final String dateTo;
  final String property;
  final double totalRent;
  final double maintenanceCosts;
  final double total;

  FinancialReportItem({
    required this.dateFrom,
    required this.dateTo,
    required this.property,
    required this.totalRent,
    required this.maintenanceCosts,
    required this.total,
  });

  // Formatting helpers
  String get formattedTotalRent => '\$${totalRent.toStringAsFixed(2)}';
  String get formattedMaintenanceCosts =>
      '\$${maintenanceCosts.toStringAsFixed(2)}';
  String get formattedTotal => '\$${total.toStringAsFixed(2)}';

  // Date helpers
  DateTime get dateFromObj => DateFormat('dd/MM/yyyy').parse(dateFrom);
  DateTime get dateToObj => DateFormat('dd/MM/yyyy').parse(dateTo);

  // JSON conversion
  Map<String, dynamic> toJson() {
    return {
      'dateFrom': dateFrom,
      'dateTo': dateTo,
      'property': property,
      'totalRent': totalRent,
      'maintenanceCosts': maintenanceCosts,
      'total': total,
    };
  }

  factory FinancialReportItem.fromJson(Map<String, dynamic> json) {
    return FinancialReportItem(
      dateFrom: json['dateFrom'],
      dateTo: json['dateTo'],
      property: json['property'],
      totalRent: json['totalRent'],
      maintenanceCosts: json['maintenanceCosts'],
      total: json['total'],
    );
  }
}
