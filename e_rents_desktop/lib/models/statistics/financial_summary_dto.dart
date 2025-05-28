class FinancialSummaryDto {
  final double totalRentIncome;
  final double totalMaintenanceCosts;
  final double otherIncome;
  final double otherExpenses;
  final double netTotal;

  FinancialSummaryDto({
    required this.totalRentIncome,
    required this.totalMaintenanceCosts,
    required this.otherIncome,
    required this.otherExpenses,
    required this.netTotal,
  });

  factory FinancialSummaryDto.fromJson(Map<String, dynamic> json) {
    return FinancialSummaryDto(
      totalRentIncome: (json['totalRentIncome'] ?? 0.0).toDouble(),
      totalMaintenanceCosts: (json['totalMaintenanceCosts'] ?? 0.0).toDouble(),
      otherIncome: (json['otherIncome'] ?? 0.0).toDouble(),
      otherExpenses: (json['otherExpenses'] ?? 0.0).toDouble(),
      netTotal: (json['netTotal'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRentIncome': totalRentIncome,
      'totalMaintenanceCosts': totalMaintenanceCosts,
      'otherIncome': otherIncome,
      'otherExpenses': otherExpenses,
      'netTotal': netTotal,
    };
  }
}
