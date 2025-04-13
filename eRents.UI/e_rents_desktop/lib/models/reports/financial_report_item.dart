class FinancialReportItem {
  final String date;
  final String property;
  final String unit;
  final String transactionType;
  final double amount;
  final double balance;

  FinancialReportItem({
    required this.date,
    required this.property,
    required this.unit,
    required this.transactionType,
    required this.amount,
    required this.balance,
  });

  // For formatting in the UI
  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';
  String get formattedBalance => '\$${balance.toStringAsFixed(2)}';

  // For converting to/from JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'property': property,
      'unit': unit,
      'transactionType': transactionType,
      'amount': amount,
      'balance': balance,
    };
  }

  factory FinancialReportItem.fromJson(Map<String, dynamic> json) {
    return FinancialReportItem(
      date: json['date'],
      property: json['property'],
      unit: json['unit'],
      transactionType: json['transactionType'],
      amount: json['amount'],
      balance: json['balance'],
    );
  }
}
