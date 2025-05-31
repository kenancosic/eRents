class MonthlyRevenue {
  final int year;
  final int month;
  final double revenue;

  MonthlyRevenue({
    required this.year,
    required this.month,
    required this.revenue,
  });

  factory MonthlyRevenue.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenue(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      revenue: json['revenue']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'year': year, 'month': month, 'revenue': revenue};
  }
}
