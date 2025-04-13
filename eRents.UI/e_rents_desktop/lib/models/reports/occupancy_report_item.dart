class OccupancyReportItem {
  final String property;
  final int totalUnits;
  final int occupied;
  final int vacant;
  final double occupancyRate;
  final double avgRent;

  OccupancyReportItem({
    required this.property,
    required this.totalUnits,
    required this.occupied,
    required this.vacant,
    required this.occupancyRate,
    required this.avgRent,
  });

  // For formatting in the UI
  String get formattedOccupancyRate =>
      '${(occupancyRate * 100).toStringAsFixed(1)}%';
  String get formattedAvgRent => '\$${avgRent.toStringAsFixed(2)}';

  // For converting to/from JSON
  Map<String, dynamic> toJson() {
    return {
      'property': property,
      'totalUnits': totalUnits,
      'occupied': occupied,
      'vacant': vacant,
      'occupancyRate': occupancyRate,
      'avgRent': avgRent,
    };
  }

  factory OccupancyReportItem.fromJson(Map<String, dynamic> json) {
    return OccupancyReportItem(
      property: json['property'],
      totalUnits: json['totalUnits'],
      occupied: json['occupied'],
      vacant: json['vacant'],
      occupancyRate: json['occupancyRate'],
      avgRent: json['avgRent'],
    );
  }
}
