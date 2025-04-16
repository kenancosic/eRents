class FinancialStatistics {
  final double totalRevenue;
  final double totalExpenses;
  final double netIncome;
  final Map<String, double> monthlyRevenue; // Last 6 months revenue

  FinancialStatistics({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netIncome,
    required this.monthlyRevenue,
  });

  factory FinancialStatistics.fromJson(Map<String, dynamic> json) {
    return FinancialStatistics(
      totalRevenue: json['totalRevenue'] as double,
      totalExpenses: json['totalExpenses'] as double,
      netIncome: json['netIncome'] as double,
      monthlyRevenue: Map<String, double>.from(json['monthlyRevenue']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRevenue': totalRevenue,
      'totalExpenses': totalExpenses,
      'netIncome': netIncome,
      'monthlyRevenue': monthlyRevenue,
    };
  }
}
