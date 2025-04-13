import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportFilters extends StatefulWidget {
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
  State<ReportFilters> createState() => _ReportFiltersState();
}

class _ReportFiltersState extends State<ReportFilters> {
  late DateTime _startDate;
  late DateTime _endDate;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final List<String> _quickDateRanges = [
    'Today',
    'Yesterday',
    'This Week',
    'Last Week',
    'This Month',
    'Last Month',
    'This Quarter',
    'Last Quarter',
    'This Year',
    'Last Year',
    'Custom',
  ];
  String _selectedRange = 'This Month';

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  void didUpdateWidget(ReportFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      setState(() {
        _startDate = widget.startDate;
        _endDate = widget.endDate;
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _selectedRange = 'Custom';
      });
      widget.onDateRangeChanged(_startDate, _endDate);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(
        const Duration(days: 1),
      ), // Allow selecting today
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        _selectedRange = 'Custom';
      });
      widget.onDateRangeChanged(_startDate, _endDate);
    }
  }

  void _applyQuickDateRange(String range) {
    DateTime now = DateTime.now();
    DateTime start;
    DateTime end;

    // Set the time to end of day for end date
    final endOfDay =
        (DateTime date) =>
            DateTime(date.year, date.month, date.day, 23, 59, 59);

    switch (range) {
      case 'Today':
        start = DateTime(now.year, now.month, now.day);
        end = endOfDay(now);
        break;
      case 'Yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        start = DateTime(yesterday.year, yesterday.month, yesterday.day);
        end = endOfDay(yesterday);
        break;
      case 'This Week':
        // Start of the week (Monday)
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        end = endOfDay(now);
        break;
      case 'Last Week':
        // Last week's Monday
        start = now.subtract(Duration(days: now.weekday - 1 + 7));
        start = DateTime(start.year, start.month, start.day);
        // Last week's Sunday
        end = now.subtract(Duration(days: now.weekday));
        end = endOfDay(end);
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        end = endOfDay(now);
        break;
      case 'Last Month':
        // First day of last month
        start = DateTime(now.year, now.month - 1, 1);
        // Last day of last month
        end = DateTime(now.year, now.month, 0);
        end = endOfDay(end);
        break;
      case 'This Quarter':
        final quarter = (now.month - 1) ~/ 3;
        start = DateTime(now.year, quarter * 3 + 1, 1);
        end = endOfDay(now);
        break;
      case 'Last Quarter':
        final quarter = (now.month - 1) ~/ 3;
        if (quarter == 0) {
          // Last quarter of previous year
          start = DateTime(now.year - 1, 10, 1);
          end = DateTime(now.year, 1, 0);
        } else {
          // Previous quarter of current year
          start = DateTime(now.year, (quarter - 1) * 3 + 1, 1);
          end = DateTime(now.year, quarter * 3 + 1, 0);
        }
        end = endOfDay(end);
        break;
      case 'This Year':
        start = DateTime(now.year, 1, 1);
        end = endOfDay(now);
        break;
      case 'Last Year':
        start = DateTime(now.year - 1, 1, 1);
        end = DateTime(now.year, 1, 0);
        end = endOfDay(end);
        break;
      default:
        return; // Keep the existing dates for 'Custom'
    }

    setState(() {
      _startDate = start;
      _endDate = end;
      _selectedRange = range;
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
            color: Colors.black.withOpacity(0.05),
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
                  value: _selectedRange,
                  items:
                      _quickDateRanges
                          .map(
                            (range) => DropdownMenuItem(
                              value: range,
                              child: Text(range),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null && value != 'Custom') {
                      _applyQuickDateRange(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectStartDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(_dateFormat.format(_startDate)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectEndDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(_dateFormat.format(_endDate)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
