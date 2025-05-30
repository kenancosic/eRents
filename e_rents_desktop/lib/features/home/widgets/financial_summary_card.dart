import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for NumberFormat

/// Displays a summary of financial data for landlord dashboard
/// Optimized for backend integration and simplified property management
class FinancialSummaryCard extends StatelessWidget {
  final double income;
  final double expenses;
  final double netProfit;
  final NumberFormat currencyFormat; // Receive the formatter

  const FinancialSummaryCard({
    super.key,
    required this.income,
    required this.expenses,
    required this.netProfit,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isProfit = netProfit >= 0;
    final Color profitColor =
        isProfit ? Colors.green.shade700 : Colors.red.shade700;

    return Column(
      children: [
        _buildFinancialRow(
          context: context,
          icon: Icons.arrow_downward_rounded,
          iconColor: Colors.green.shade600,
          label: 'Total Income',
          value: currencyFormat.format(income),
        ),
        const Divider(height: 20),
        _buildFinancialRow(
          context: context,
          icon: Icons.arrow_upward_rounded,
          iconColor: Colors.red.shade600,
          label: 'Total Expenses',
          value: currencyFormat.format(expenses),
        ),
        const Divider(height: 20),
        _buildFinancialRow(
          context: context,
          icon: Icons.account_balance_wallet_outlined,
          iconColor: profitColor,
          label: 'Net Profit/Loss',
          value: currencyFormat.format(netProfit),
          valueStyle: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: profitColor,
          ),
        ),
      ],
    );
  }

  // Helper to build consistent rows
  Widget _buildFinancialRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Text(label, style: theme.textTheme.bodyLarge),
          ],
        ),
        Text(
          value,
          style:
              valueStyle ??
              theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
