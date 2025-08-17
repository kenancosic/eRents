import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/enums/rental_request_status.dart';
import 'package:intl/intl.dart';

class RentalRequest {
  final int requestId;
  final int propertyId;
  final int userId;
  final DateTime proposedStartDate;
  final DateTime proposedEndDate;
  final double proposedMonthlyRent;
  final int leaseDurationMonths;
  final String message;
  final RentalRequestStatus status;
  final String? landlordResponse;
  final DateTime requestDate;

  // BaseEntity fields
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? createdBy;
  final int? modifiedBy;

  // Related entities (populated from joins) - these should be @JsonKey(includeFromJson: false, includeToJson: false)
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
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.modifiedBy,
    this.property,
    this.user,
  });

  factory RentalRequest.fromJson(Map<String, dynamic> json) {
    DateTime _reqDate(dynamic v) {
      final d = (v == null)
          ? null
          : (v is DateTime)
              ? v
              : DateTime.tryParse(v.toString());
      return d ?? DateTime.now();
    }
    DateTime _date(dynamic v) => _reqDate(v);
    double _toDouble(dynamic v) => v is num ? v.toDouble() : double.parse(v.toString());
    int _toInt(dynamic v) => v is num ? v.toInt() : int.parse(v.toString());
    int? _asInt(dynamic v) => v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));
    String _str(dynamic v) => v?.toString() ?? '';
    String? _asString(dynamic v) => v == null ? null : v.toString();
    RentalRequestStatus _parseStatus(dynamic v) {
      if (v == null) return RentalRequestStatus.pending;
      if (v is int) {
        try { return RentalRequestStatus.fromValue(v); } catch (_) { return RentalRequestStatus.pending; }
      }
      final s = v.toString();
      try { return RentalRequestStatus.fromString(s); } catch (_) { return RentalRequestStatus.pending; }
    }
    final created = _reqDate(json['createdAt']);
    final updated = _reqDate(json['updatedAt'] ?? created);
    return RentalRequest(
      requestId: _toInt(json['requestId']),
      propertyId: _toInt(json['propertyId']),
      userId: _toInt(json['userId']),
      proposedStartDate: _date(json['proposedStartDate']),
      proposedEndDate: _date(json['proposedEndDate']),
      proposedMonthlyRent: _toDouble(json['proposedMonthlyRent']),
      leaseDurationMonths: _toInt(json['leaseDurationMonths']),
      message: _str(json['message']),
      status: _parseStatus(json['status']),
      landlordResponse: _asString(json['landlordResponse']),
      requestDate: _date(json['requestDate']),
      createdAt: created,
      updatedAt: updated,
      createdBy: _asInt(json['createdBy']),
      modifiedBy: _asInt(json['modifiedBy']),
      property: null,
      user: null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'requestId': requestId,
        'propertyId': propertyId,
        'userId': userId,
        'proposedStartDate': proposedStartDate.toIso8601String(),
        'proposedEndDate': proposedEndDate.toIso8601String(),
        'proposedMonthlyRent': proposedMonthlyRent,
        'leaseDurationMonths': leaseDurationMonths,
        'message': message,
        'status': status.name,
        'landlordResponse': landlordResponse,
        'requestDate': requestDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'createdBy': createdBy,
        'modifiedBy': modifiedBy,
      };

  // Convenience getters for UI
  String get propertyName => property?.name ?? 'Unknown Property';
  String get userName => user?.fullName ?? 'Unknown User';
  String get formattedStartDate => DateFormat('MMM dd, yyyy').format(proposedStartDate);
  String get formattedEndDate => DateFormat('MMM dd, yyyy').format(proposedEndDate);
  String get formattedRent => '\$${proposedMonthlyRent.toStringAsFixed(2)}/month';
  bool get isPending => status == RentalRequestStatus.pending;
}