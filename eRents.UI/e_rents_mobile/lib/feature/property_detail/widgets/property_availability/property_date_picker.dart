// lib/feature/property_detail/widgets/property_availability/property_date_picker.dart
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';

class PropertyDatePicker extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Map<DateTime, bool> availability;
  final Function(DateTime, DateTime) onDateRangeSelected;
  final Function(DateTime, DateTime) onInvalidSelection;
  final double pricePerNight;
  final bool isDailyRental;

  const PropertyDatePicker({
    super.key,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.firstDate,
    required this.lastDate,
    required this.availability,
    required this.onDateRangeSelected,
    required this.onInvalidSelection,
    required this.pricePerNight,
    this.isDailyRental = true,
  });

  @override
  State<PropertyDatePicker> createState() => _PropertyDatePickerState();
}

class _PropertyDatePickerState extends State<PropertyDatePicker> {
  DateTime? _startDate;
  DateTime? _endDate;
  double _totalPrice = 0.0;
  int _nightsCount = 0;
  int _monthsCount = 0;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _calculateTotalPrice();
  }

  @override
  void didUpdateWidget(PropertyDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDailyRental != widget.isDailyRental) {
      // Adjust end date when switching between daily and monthly
      if (widget.isDailyRental) {
        _endDate = _startDate?.add(const Duration(days: 5));
      } else {
        _endDate =
            DateTime(_startDate!.year, _startDate!.month + 1, _startDate!.day);
      }
      _calculateTotalPrice();
    }
  }

  void _calculateTotalPrice() {
    if (_startDate != null && _endDate != null) {
      if (widget.isDailyRental) {
        _nightsCount = _endDate!.difference(_startDate!).inDays;
        _totalPrice = _nightsCount * widget.pricePerNight;
      } else {
        // Calculate months between dates
        _monthsCount = (_endDate!.year - _startDate!.year) * 12 +
            _endDate!.month -
            _startDate!.month;
        if (_endDate!.day < _startDate!.day) _monthsCount--;
        if (_monthsCount < 1) _monthsCount = 1;

        _totalPrice = _monthsCount * widget.pricePerNight;
      }
    }
  }

  bool _isDateAvailable(DateTime date) {
    // Normalize date to remove time component for comparison
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return widget.availability[normalizedDate] ?? true;
  }

  Future<void> _selectDateRange(BuildContext context) async {
    if (widget.isDailyRental) {
      await _selectDailyDateRange(context);
    } else {
      await _selectMonthlyDateRange(context);
    }
  }

  Future<void> _selectDailyDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate!, end: _endDate!),
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
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
      }
    }
  }

  Future<void> _selectMonthlyDateRange(BuildContext context) async {
    // Make sure initialDate is not before firstDate
    DateTime initialPickDate = _startDate!;
    if (initialPickDate.isBefore(widget.firstDate)) {
      initialPickDate = widget.firstDate;
    }

    final DateTime? pickedStartMonth = await showDatePicker(
      context: context,
      initialDate: initialPickDate,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedStartMonth != null) {
      // Normalize to first day of month
      final startMonth =
          DateTime(pickedStartMonth.year, pickedStartMonth.month, 1);

      // Make sure the initialDate for end month picker is valid
      DateTime initialEndDate =
          DateTime(startMonth.year, startMonth.month + 1, 1);
      if (initialEndDate.isAfter(widget.lastDate)) {
        initialEndDate = widget.lastDate;
      }

      // Show second picker for end month
      final DateTime? pickedEndMonth = await showDatePicker(
        context: context,
        initialDate: initialEndDate,
        firstDate: startMonth, // Start month is the minimum for end month
        lastDate: widget.lastDate,
        initialDatePickerMode: DatePickerMode.year,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).primaryColor,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedEndMonth != null) {
        // Normalize to last day of month
        final endMonth = DateTime(
          pickedEndMonth.year,
          pickedEndMonth.month + 1,
          0, // Last day of the month
        );

        setState(() {
          _startDate = startMonth;
          _endDate = endMonth;
          _calculateTotalPrice();
        });
        widget.onDateRangeSelected(_startDate!, _endDate!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String unitLabel = widget.isDailyRental ? 'nights' : 'months';
    final int unitCount = widget.isDailyRental ? _nightsCount : _monthsCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${widget.pricePerNight.toStringAsFixed(0)} × $unitCount $unitLabel',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '\$${_totalPrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Service fee',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '\$${(_totalPrice * 0.1).toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '\$${(_totalPrice * 1.1).toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Calendar button
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            isLoading: false,
            onPressed: () => _selectDateRange(context),
            label: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month, size: 20),
                const SizedBox(width: 8),
                Text(
                  'View Calendar',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
