/// Availability model for property booking availability checks
class Availability {
  final int? availabilityId;
  final int propertyId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isAvailable;
  final String? reason; // Reason for unavailability if not available

  Availability({
    this.availabilityId,
    required this.propertyId,
    required this.startDate,
    required this.endDate,
    required this.isAvailable,
    this.reason,
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      availabilityId: json['availabilityId'] as int?,
      propertyId: json['propertyId'] as int? ?? 0,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isAvailable: json['isAvailable'] as bool? ?? false,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'availabilityId': availabilityId,
      'propertyId': propertyId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isAvailable': isAvailable,
      'reason': reason,
    };
  }
}
