/// Pricing estimate model for property booking cost calculations
class PricingEstimate {
  final double totalPrice;
  final double basePrice;
  final double cleaningFee;
  final double serviceFee;
  final double taxes;
  final int propertyId;
  final DateTime startDate;
  final DateTime endDate;
  final int guests;

  PricingEstimate({
    required this.totalPrice,
    required this.basePrice,
    required this.cleaningFee,
    required this.serviceFee,
    required this.taxes,
    required this.propertyId,
    required this.startDate,
    required this.endDate,
    required this.guests,
  });

  factory PricingEstimate.fromJson(Map<String, dynamic> json) {
    return PricingEstimate(
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      cleaningFee: (json['cleaningFee'] as num?)?.toDouble() ?? 0.0,
      serviceFee: (json['serviceFee'] as num?)?.toDouble() ?? 0.0,
      taxes: (json['taxes'] as num?)?.toDouble() ?? 0.0,
      propertyId: json['propertyId'] as int? ?? 0,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      guests: json['guests'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPrice': totalPrice,
      'basePrice': basePrice,
      'cleaningFee': cleaningFee,
      'serviceFee': serviceFee,
      'taxes': taxes,
      'propertyId': propertyId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'guests': guests,
    };
  }
}
