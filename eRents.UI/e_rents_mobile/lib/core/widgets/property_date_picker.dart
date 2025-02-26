import 'package:flutter/material.dart';

class DatePicker extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Map<DateTime, bool>
      availability; // true for available, false for unavailable dates
  final Function(DateTime, DateTime) onDateRangeSelected;
  final Function(DateTime, DateTime) onInvalidSelection;
  final double pricePerNight;

  const DatePicker({
    super.key,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.firstDate,
    required this.lastDate,
    required this.availability,
    required this.onDateRangeSelected,
    required this.onInvalidSelection,
    required this.pricePerNight,
  });

  @override
  _DatePickerState createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  DateTime? _startDate;
  DateTime? _endDate;
  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _calculateTotalPrice();
  }

  void _calculateTotalPrice() {
    if (_startDate != null && _endDate != null) {
      setState(() {
        _totalPrice =
            _endDate!.difference(_startDate!).inDays * widget.pricePerNight;
      });
    }
  }

  bool _isDateAvailable(DateTime date) {
    return widget.availability[date] ?? true;
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate!, end: _endDate!),
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
    );

    if (picked != null &&
        picked != DateTimeRange(start: _startDate!, end: _endDate!)) {
      bool validSelection = true;

      for (var day = picked.start;
          day.isBefore(picked.end) || day.isAtSameMomentAs(picked.end);
          day = day.add(const Duration(days: 1))) {
        if (!_isDateAvailable(day)) {
          validSelection = false;
          break;
        }
      }

      if (validSelection) {
        setState(() {
          _startDate = picked.start;
          _endDate = picked.end;
          _calculateTotalPrice();
        });
        widget.onDateRangeSelected(_startDate!, _endDate!);
      } else {
        widget.onInvalidSelection(picked.start, picked.end);
        // Show some error feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Selected dates include unavailable days.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: () => _selectDateRange(context),
          child: const Text('Select Date Range'),
        ),
        if (_startDate != null && _endDate != null) ...[
          Text(
              'Selected Dates: ${_startDate!.toLocal()} - ${_endDate!.toLocal()}'),
          const Text('Total Price: \$_totalPrice'),
        ],
        if (_startDate == null || _endDate == null)
          const Text('Please select a valid date range.'),
      ],
    );
  }
}
