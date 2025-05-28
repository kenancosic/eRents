class PropertyStatistics {
  final int totalProperties;
  final int availableUnits;
  final int rentedUnits;
  final double occupancyRate;
  final List<PropertyMiniSummary> vacantPropertiesPreview;

  PropertyStatistics({
    required this.totalProperties,
    required this.availableUnits,
    required this.rentedUnits,
    required this.occupancyRate,
    required this.vacantPropertiesPreview,
  });

  factory PropertyStatistics.fromJson(Map<String, dynamic> json) {
    return PropertyStatistics(
      totalProperties: json['totalProperties'] ?? 0,
      availableUnits: json['availableUnits'] ?? 0,
      rentedUnits: json['rentedUnits'] ?? 0,
      occupancyRate: (json['occupancyRate'] ?? 0.0).toDouble(),
      vacantPropertiesPreview:
          (json['vacantPropertiesPreview'] as List<dynamic>? ?? [])
              .map((e) => PropertyMiniSummary.fromJson(e))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalProperties': totalProperties,
      'availableUnits': availableUnits,
      'rentedUnits': rentedUnits,
      'occupancyRate': occupancyRate,
      'vacantPropertiesPreview':
          vacantPropertiesPreview.map((e) => e.toJson()).toList(),
    };
  }
}

class PropertyMiniSummary {
  final String propertyId;
  final String title;
  final double price;

  PropertyMiniSummary({
    required this.propertyId,
    required this.title,
    required this.price,
  });

  factory PropertyMiniSummary.fromJson(Map<String, dynamic> json) {
    return PropertyMiniSummary(
      propertyId: json['propertyId'] ?? '',
      title: json['title'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'propertyId': propertyId, 'title': title, 'price': price};
  }
}
