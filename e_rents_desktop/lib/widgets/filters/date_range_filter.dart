import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Configuration class for date range filter behavior
class DateRangeFilterConfig {
  final String title;
  final List<String> presetRanges;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool showPresets;
  final bool showPropertyFilter;

  const DateRangeFilterConfig({
    this.title = 'Filter Options',
    this.presetRanges = const [
      'Last 7 Days',
      'Last 30 Days',
      'Last 90 Days',
      'This Year',
      'Last Year',
    ],
    this.initialStartDate,
    this.initialEndDate,
    this.firstDate,
    this.lastDate,
    this.showPresets = true,
    this.showPropertyFilter = false,
  });
}

/// Flexible and reusable date range filter widget
class DateRangeFilter extends StatefulWidget {
  final Function(DateTime, DateTime) onDateRangeChanged;
  final Function(List<String>)? onPropertyFilterChanged;
  final DateRangeFilterConfig config;

  const DateRangeFilter({
    super.key,
    required this.onDateRangeChanged,
    this.onPropertyFilterChanged,
    this.config = const DateRangeFilterConfig(),
  });

  @override
  State<DateRangeFilter> createState() => _DateRangeFilterState();
}

class _DateRangeFilterState extends State<DateRangeFilter> {
  late DateTime _startDate;
  late DateTime _endDate;
  // Date formatters and controllers
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  @override
  void initState() {
    super.initState();

    // Initialize dates from config or defaults
    _startDate =
        widget.config.initialStartDate ??
        DateTime.now().subtract(const Duration(days: 30));
    _endDate = widget.config.initialEndDate ?? DateTime.now();

    _startDateController = TextEditingController(
      text: _dateFormat.format(_startDate),
    );
    _endDateController = TextEditingController(
      text: _dateFormat.format(_endDate),
    );

    if (widget.config.showPropertyFilter) {
      _loadAvailableProperties();
    }

    // Notify parent of initial date range
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDateRangeChanged(_startDate, _endDate);
    });
  }

  /// TODO: Replace with actual API call to get properties
  void _loadAvailableProperties() {
    // Placeholder - replace with actual property service
    // No properties loaded currently
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _showDatePicker(bool isStartDate) async {
    final now = DateTime.now();
    final firstDate = widget.config.firstDate ?? DateTime(2020);
    final lastDate =
        widget.config.lastDate ?? now.add(const Duration(days: 365));

    // Ensure initial date is within bounds
    DateTime initialDate;
    if (isStartDate) {
      initialDate = _startDate;
      if (initialDate.isBefore(firstDate)) {
        initialDate = firstDate;
      } else if (initialDate.isAfter(lastDate)) {
        initialDate = now;
      }
    } else {
      initialDate = _endDate;
      if (initialDate.isBefore(firstDate)) {
        initialDate = firstDate;
      } else if (initialDate.isAfter(lastDate)) {
        initialDate = now;
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = _dateFormat.format(_startDate);
          // Ensure end date is not before start date
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
            _endDateController.text = _dateFormat.format(_endDate);
          }
        } else {
          _endDate = picked;
          _endDateController.text = _dateFormat.format(_endDate);
          // Ensure start date is not after end date
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate;
            _startDateController.text = _dateFormat.format(_startDate);
          }
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
      case 'Last 3 Months':
        // Go back 3 months from current date
        newStartDate = DateTime(now.year, now.month - 3, now.day);
        // If the day doesn't exist in the target month, use the last day of that month
        if (newStartDate.month != now.month - 3) {
          newStartDate = DateTime(
            now.year,
            now.month - 2,
            0,
          ); // Last day of the month before
        }
        break;
      case 'This Year':
        newStartDate = DateTime(now.year, 1, 1);
        break;
      case 'Last Year':
        newStartDate = DateTime(now.year - 1, 1, 1);
        newEndDate = DateTime(now.year - 1, 12, 31);
        break;
      case 'This Month':
        newStartDate = DateTime(now.year, now.month, 1);
        newEndDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        newStartDate = lastMonth;
        newEndDate = DateTime(lastMonth.year, lastMonth.month + 1, 0);
        break;
      default:
        return;
    }

    setState(() {
      _startDate = newStartDate;
      _endDate = newEndDate;
      _startDateController.text = _dateFormat.format(_startDate);
      _endDateController.text = _dateFormat.format(_endDate);
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
          Text(
            widget.config.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Preset dropdown (optional)
              if (widget.config.showPresets) ...[
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Date Range',
                      border: OutlineInputBorder(),
                    ),
                    value: 'Custom',
                    items: [
                      const DropdownMenuItem(
                        value: 'Custom',
                        child: Text('Custom'),
                      ),
                      ...widget.config.presetRanges.map(
                        (range) =>
                            DropdownMenuItem(value: range, child: Text(range)),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null && value != 'Custom') {
                        _applyPresetRange(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
              ],

              // Start date picker
              Expanded(
                child: TextField(
                  controller: _startDateController,
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

              // End date picker
              Expanded(
                child: TextField(
                  controller: _endDateController,
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

          // Property filter section (optional)
          if (widget.config.showPropertyFilter) ...[
            const SizedBox(height: 16),
            // TODO: Implement property filter UI
            const Text(
              'Property filters will be implemented here',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}
