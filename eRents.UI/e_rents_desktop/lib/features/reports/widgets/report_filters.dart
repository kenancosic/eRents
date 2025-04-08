import 'package:flutter/material.dart';

class ReportFilters extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Function(DateTime, DateTime) onDateRangeChanged;

  const ReportFilters({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onDateRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Date Range:',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(width: 16),
          _buildDatePicker(
            context,
            'Start Date',
            startDate,
            (date) => onDateRangeChanged(date, endDate),
          ),
          const SizedBox(width: 16),
          _buildDatePicker(
            context,
            'End Date',
            endDate,
            (date) => onDateRangeChanged(startDate, date),
          ),
          const Spacer(),
          _buildQuickSelectButtons(context),
        ],
      ),
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
    String label,
    DateTime date,
    Function(DateTime) onDateSelected,
  ) {
    return InkWell(
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (selected != null) {
          onDateSelected(selected);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(width: 8),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSelectButtons(BuildContext context) {
    return Row(
      children: [
        _buildQuickSelectButton(context, 'Last 7 Days', () {
          final end = DateTime.now();
          final start = end.subtract(const Duration(days: 7));
          onDateRangeChanged(start, end);
        }),
        const SizedBox(width: 8),
        _buildQuickSelectButton(context, 'Last 30 Days', () {
          final end = DateTime.now();
          final start = end.subtract(const Duration(days: 30));
          onDateRangeChanged(start, end);
        }),
        const SizedBox(width: 8),
        _buildQuickSelectButton(context, 'Last 90 Days', () {
          final end = DateTime.now();
          final start = end.subtract(const Duration(days: 90));
          onDateRangeChanged(start, end);
        }),
      ],
    );
  }

  Widget _buildQuickSelectButton(
    BuildContext context,
    String label,
    VoidCallback onPressed,
  ) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: Colors.grey[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
      ),
    );
  }
}
