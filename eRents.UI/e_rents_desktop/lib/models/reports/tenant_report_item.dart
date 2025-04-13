import 'package:intl/intl.dart';

enum TenantStatus { active, latePayment, endingSoon, ended }

class TenantReportItem {
  final String tenant;
  final String property;
  final String unit;
  final String leaseStart;
  final String leaseEnd;
  final double rent;
  final TenantStatus status;

  TenantReportItem({
    required this.tenant,
    required this.property,
    required this.unit,
    required this.leaseStart,
    required this.leaseEnd,
    required this.rent,
    required this.status,
  });

  // For formatting in the UI
  String get formattedRent => '\$${rent.toStringAsFixed(2)}';
  String get statusLabel {
    switch (status) {
      case TenantStatus.active:
        return 'Active';
      case TenantStatus.latePayment:
        return 'Late Payment';
      case TenantStatus.endingSoon:
        return 'Ending Soon';
      case TenantStatus.ended:
        return 'Ended';
    }
  }

  // Get DateTime objects from date strings
  DateTime get leaseStartDate => DateFormat('dd/MM/yyyy').parse(leaseStart);
  DateTime get leaseEndDate => DateFormat('dd/MM/yyyy').parse(leaseEnd);

  // Calculate lease duration in days
  int get leaseDurationDays => leaseEndDate.difference(leaseStartDate).inDays;

  // Calculate days remaining in lease
  int get daysRemaining => leaseEndDate.difference(DateTime.now()).inDays;
  bool get isLeaseActive => daysRemaining > 0;

  // For converting to/from JSON
  Map<String, dynamic> toJson() {
    return {
      'tenant': tenant,
      'property': property,
      'unit': unit,
      'leaseStart': leaseStart,
      'leaseEnd': leaseEnd,
      'rent': rent,
      'status': status.toString().split('.').last,
    };
  }

  factory TenantReportItem.fromJson(Map<String, dynamic> json) {
    return TenantReportItem(
      tenant: json['tenant'],
      property: json['property'],
      unit: json['unit'],
      leaseStart: json['leaseStart'],
      leaseEnd: json['leaseEnd'],
      rent: json['rent'],
      status: _statusFromString(json['status']),
    );
  }

  static TenantStatus _statusFromString(String statusStr) {
    switch (statusStr.toLowerCase().replaceAll(' ', '')) {
      case 'active':
        return TenantStatus.active;
      case 'latepayment':
        return TenantStatus.latePayment;
      case 'endingsoon':
        return TenantStatus.endingSoon;
      case 'ended':
        return TenantStatus.ended;
      default:
        return TenantStatus.active;
    }
  }
}
