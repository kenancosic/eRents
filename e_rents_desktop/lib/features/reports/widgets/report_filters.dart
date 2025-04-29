import 'package:e_rents_desktop/services/mock_data_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportFilters extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final void Function(DateTime, DateTime) onDateRangeChanged;

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
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final List<String> _quickDateRanges = MockDataService.getQuickDateRanges();
  final String _selectedRange = 'This Month';

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _startDateController = TextEditingController(
      text: _dateFormat.format(_startDate),
    );
    _endDateController = TextEditingController(
      text: _dateFormat.format(_endDate),
    );
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ReportFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startDate != oldWidget.startDate) {
      _startDate = widget.startDate;
      _startDateController.text = _dateFormat.format(_startDate);
    }
    if (widget.endDate != oldWidget.endDate) {
      _endDate = widget.endDate;
      _endDateController.text = _dateFormat.format(_endDate);
    }
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
          _startDateController.text = _dateFormat.format(_startDate);
        } else {
          _endDate = picked;
          _endDateController.text = _dateFormat.format(_endDate);
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
                      _applyPresetRange(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
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
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  MockDataService.getQuickDateRangePresets().map((preset) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ActionChip(
                        label: Text(preset),
                        onPressed: () => _applyPresetRange(preset),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
