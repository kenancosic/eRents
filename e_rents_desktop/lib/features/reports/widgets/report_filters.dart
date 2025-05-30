import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/reports/tenant_report_item.dart';

class ReportFilters extends StatefulWidget {
  final Function(DateTime, DateTime) onDateRangeChanged;
  final Function(List<String>) onPropertyFilterChanged;

  const ReportFilters({
    super.key,
    required this.onDateRangeChanged,
    required this.onPropertyFilterChanged,
  });

  @override
  State<ReportFilters> createState() => _ReportFiltersState();
}

class _ReportFiltersState extends State<ReportFilters> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<String> _selectedProperties = [];

  // TODO: Replace with actual property service call
  List<String> _availableProperties = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableProperties();
  }

  /// TODO: Replace with actual API call to get properties
  void _loadAvailableProperties() {
    // Placeholder - replace with actual property service
    _availableProperties = [];
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(ReportFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void _showDatePicker(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });

      widget.onDateRangeChanged(_startDate, _endDate);
    }
  }

  void _applyPresetRange(String preset) {
    final now = DateTime.now();
    DateTime newStartDate;
    DateTime newEndDate = DateTime(now.year, now.month, now.day);

    switch (preset) {
      case 'Last 7 Days':
        newStartDate = newEndDate.subtract(const Duration(days: 7));
        break;
      case 'Last 30 Days':
        newStartDate = newEndDate.subtract(const Duration(days: 30));
        break;
      case 'Last 90 Days':
        newStartDate = newEndDate.subtract(const Duration(days: 90));
        break;
      case 'This Year':
        newStartDate = DateTime(now.year, 1, 1);
        break;
      case 'Last Year':
        newStartDate = DateTime(now.year - 1, 1, 1);
        newEndDate = DateTime(now.year - 1, 12, 31);
        break;
      default:
        return;
    }

    setState(() {
      _startDate = newStartDate;
      _endDate = newEndDate;
    });

    widget.onDateRangeChanged(_startDate, _endDate);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // 0.05 opacity
            offset: const Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Reports',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Date Range',
                    border: OutlineInputBorder(),
                  ),
                  value: 'This Month',
                  items: const [
                    DropdownMenuItem(
                      value: 'This Month',
                      child: Text('This Month'),
                    ),
                    DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                  ],
                  onChanged: (value) {
                    if (value != null && value != 'Custom') {
                      _applyPresetRange(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  readOnly: true,
                  onTap: () => _showDatePicker(true),
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  readOnly: true,
                  onTap: () => _showDatePicker(false),
                  decoration: const InputDecoration(
                    labelText: 'End Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                // Placeholder for property filter
              ],
            ),
          ),
        ],
      ),
    );
  }
}
