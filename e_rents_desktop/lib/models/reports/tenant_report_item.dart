import 'package:intl/intl.dart';

class TenantReportItem {
  final String dateFrom;
  final String dateTo;
  final String tenantName;
  final String propertyName;
  final double costOfRent;
  final double totalPaidRent;

  TenantReportItem({
    required this.dateFrom,
    required this.dateTo,
    required this.tenantName,
    required this.propertyName,
    required this.costOfRent,
    required this.totalPaidRent,
  });

  // Date helpers
  DateTime get dateFromObj => DateFormat('dd/MM/yyyy').parse(dateFrom);
  DateTime get dateToObj => DateFormat('dd/MM/yyyy').parse(dateTo);

  // Lease info helpers
  int get leaseDurationDays => dateToObj.difference(dateFromObj).inDays;
  int get daysRemaining => dateToObj.difference(DateTime.now()).inDays;
  bool get isLeaseActive => daysRemaining > 0;

  // JSON conversion
  Map<String, dynamic> toJson() {
    return {
      'tenant': tenantName,
      'property': propertyName,
      'leaseStart': dateFrom,
      'leaseEnd': dateTo,
      'costOfRent': costOfRent,
      'totalPaidRent': totalPaidRent,
    };
  }

  factory TenantReportItem.fromJson(Map<String, dynamic> json) {
    return TenantReportItem(
      dateFrom: json['leaseStart'] ?? '',
      dateTo: json['leaseEnd'] ?? '',
      tenantName: json['tenant'] ?? '',
      propertyName: json['property'] ?? '',
      costOfRent: (json['costOfRent'] ?? 0.0).toDouble(),
      totalPaidRent: (json['totalPaidRent'] ?? 0.0).toDouble(),
    );
  }
}
