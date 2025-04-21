class FinancialStatistics {
  final Map<String, double>
  rentalIncomeAllocation; // e.g., {'Rent': 70%, 'Utilities': 20%, 'Maintenance': 10%}
  final Map<String, Map<String, double>>
  propertyIncomes; // Property -> {Rent, Utilities, Maintenance}
  final Map<String, Map<String, double>>
  propertyBillsOverTime; // Property -> Month -> Amount

  FinancialStatistics({
    required this.rentalIncomeAllocation,
    required this.propertyIncomes,
    required this.propertyBillsOverTime,
  });

  factory FinancialStatistics.fromJson(Map<String, dynamic> json) {
    return FinancialStatistics(
      rentalIncomeAllocation: Map<String, double>.from(
        json['rentalIncomeAllocation'],
      ),
      propertyIncomes: Map<String, Map<String, double>>.from(
        json['propertyIncomes'].map(
          (key, value) => MapEntry(key, Map<String, double>.from(value)),
        ),
      ),
      propertyBillsOverTime: Map<String, Map<String, double>>.from(
        json['propertyBillsOverTime'].map(
          (key, value) => MapEntry(key, Map<String, double>.from(value)),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rentalIncomeAllocation': rentalIncomeAllocation,
      'propertyIncomes': propertyIncomes,
      'propertyBillsOverTime': propertyBillsOverTime,
    };
  }
}
