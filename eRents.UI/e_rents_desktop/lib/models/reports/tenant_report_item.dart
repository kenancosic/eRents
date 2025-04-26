import 'package:intl/intl.dart';

class TenantReportItem {
  final String tenant;
  final String property;
  final String leaseStart;
  final String leaseEnd;
  final double costOfRent;
  final double totalPaidRent;

  TenantReportItem({
    required this.tenant,
    required this.property,
    required this.leaseStart,
    required this.leaseEnd,
    required this.costOfRent,
    required this.totalPaidRent,
  });

  // Formatting helpers
  String get formattedCostOfRent => '\$${costOfRent.toStringAsFixed(2)}';
  String get formattedTotalPaidRent => '\$${totalPaidRent.toStringAsFixed(2)}';

  // Date helpers
  DateTime get leaseStartDate => DateFormat('dd/MM/yyyy').parse(leaseStart);
  DateTime get leaseEndDate => DateFormat('dd/MM/yyyy').parse(leaseEnd);

  // Lease info helpers
  int get leaseDurationDays => leaseEndDate.difference(leaseStartDate).inDays;
  int get daysRemaining => leaseEndDate.difference(DateTime.now()).inDays;
  bool get isLeaseActive => daysRemaining > 0;

  // JSON conversion
  Map<String, dynamic> toJson() {
    return {
      'tenant': tenant,
      'property': property,
      'leaseStart': leaseStart,
      'leaseEnd': leaseEnd,
      'costOfRent': costOfRent,
      'totalPaidRent': totalPaidRent,
    };
  }

  factory TenantReportItem.fromJson(Map<String, dynamic> json) {
    return TenantReportItem(
      tenant: json['tenant'],
      property: json['property'],
      leaseStart: json['leaseStart'],
      leaseEnd: json['leaseEnd'],
      costOfRent: json['costOfRent'],
      totalPaidRent: json['totalPaidRent'],
    );
  }
}
