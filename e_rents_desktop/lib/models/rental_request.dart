import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/user.dart';

/// Model representing an annual rental request (lease)
class RentalRequest {
  final int requestId;
  final int propertyId;
  final int userId;
  final DateTime proposedStartDate;
  final DateTime proposedEndDate;
  final double proposedMonthlyRent;
  final int leaseDurationMonths;
  final String message;
  final String status; // "Pending", "Approved", "Rejected"
  final String? landlordResponse;
  final DateTime requestDate;

  // Related entities (populated from joins)
  final Property? property;
  final User? user;

  const RentalRequest({
    required this.requestId,
    required this.propertyId,
    required this.userId,
    required this.proposedStartDate,
    required this.proposedEndDate,
    required this.proposedMonthlyRent,
    required this.leaseDurationMonths,
    required this.message,
    required this.status,
    this.landlordResponse,
    required this.requestDate,
    this.property,
    this.user,
  });

  factory RentalRequest.fromJson(Map<String, dynamic> json) {
    return RentalRequest(
      requestId: json['requestId'] ?? 0,
      propertyId: json['propertyId'] ?? 0,
      userId: json['userId'] ?? 0,
      proposedStartDate: DateTime.parse(json['proposedStartDate']),
      proposedEndDate: DateTime.parse(json['proposedEndDate']),
      proposedMonthlyRent: (json['proposedMonthlyRent'] ?? 0.0).toDouble(),
      leaseDurationMonths: json['leaseDurationMonths'] ?? 0,
      message: json['message'] ?? '',
      status: json['status'] ?? 'Pending',
      landlordResponse: json['landlordResponse'],
      requestDate: DateTime.parse(json['requestDate']),
      property:
          json['property'] != null ? Property.fromJson(json['property']) : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'propertyId': propertyId,
      'userId': userId,
      'proposedStartDate': proposedStartDate.toIso8601String(),
      'proposedEndDate': proposedEndDate.toIso8601String(),
      'proposedMonthlyRent': proposedMonthlyRent,
      'leaseDurationMonths': leaseDurationMonths,
      'message': message,
      'status': status,
      'landlordResponse': landlordResponse,
      'requestDate': requestDate.toIso8601String(),
    };
  }

  // Helper getters for display
  String get formattedStartDate =>
      '${proposedStartDate.day}/${proposedStartDate.month}/${proposedStartDate.year}';

  String get formattedEndDate =>
      '${proposedEndDate.day}/${proposedEndDate.month}/${proposedEndDate.year}';

  String get formattedRent =>
      '${proposedMonthlyRent.toStringAsFixed(2)} BAM/month';

  String get propertyName => property?.name ?? 'Property $propertyId';

  String get userName => user?.fullName ?? 'User $userId';

  bool get isPending => status == 'Pending';
  bool get isApproved => status == 'Approved';
  bool get isRejected => status == 'Rejected';

  @override
  String toString() {
    return 'RentalRequest(requestId: $requestId, propertyId: $propertyId, status: $status)';
  }
}

/// Enum for rental request status
enum RentalRequestStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  const RentalRequestStatus(this.displayName);
  final String displayName;
}
