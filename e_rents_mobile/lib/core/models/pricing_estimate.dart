/// Simplified pricing estimate model for property booking cost calculations
class PricingEstimate {
  final double totalPrice;
  final int propertyId;
  final DateTime startDate;
  final DateTime endDate;

  PricingEstimate({
    required this.totalPrice,
    required this.propertyId,
    required this.startDate,
    required this.endDate,
  });

  factory PricingEstimate.fromJson(Map<String, dynamic> json) {
    return PricingEstimate(
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      propertyId: json['propertyId'] as int? ?? 0,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPrice': totalPrice,
      'propertyId': propertyId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }
}
