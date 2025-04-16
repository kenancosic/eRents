class OccupancyStatistics {
  final int totalUnits;
  final int occupiedUnits;
  final double occupancyRate;
  final Map<String, int> unitsByType; // e.g., {'1BR': 5, '2BR': 3, '3BR': 2}

  OccupancyStatistics({
    required this.totalUnits,
    required this.occupiedUnits,
    required this.occupancyRate,
    required this.unitsByType,
  });

  factory OccupancyStatistics.fromJson(Map<String, dynamic> json) {
    return OccupancyStatistics(
      totalUnits: json['totalUnits'] as int,
      occupiedUnits: json['occupiedUnits'] as int,
      occupancyRate: json['occupancyRate'] as double,
      unitsByType: Map<String, int>.from(json['unitsByType']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUnits': totalUnits,
      'occupiedUnits': occupiedUnits,
      'occupancyRate': occupancyRate,
      'unitsByType': unitsByType,
    };
  }
}
