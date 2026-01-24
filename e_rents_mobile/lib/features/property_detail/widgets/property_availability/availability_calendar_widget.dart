import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:e_rents_mobile/core/models/availability.dart';
import 'package:e_rents_mobile/core/enums/property_enums.dart';

/// A visual calendar widget that displays property availability
/// with color-coded dates for easy booking decisions.
class AvailabilityCalendarWidget extends StatefulWidget {
  final List<Availability> availabilityData;
  final PropertyRentalType rentalType;
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
  final Function(DateTime start, DateTime end)? onDateRangeSelected;
  /// For monthly rentals: callback when only start date is selected
  final Function(DateTime startDate)? onStartDateSelected;
  final bool isSelectable;
  final int? minimumStayDays;

  const AvailabilityCalendarWidget({
    super.key,
    required this.availabilityData,
    required this.rentalType,
    this.selectedStartDate,
    this.selectedEndDate,
    this.onDateRangeSelected,
    this.onStartDateSelected,
    this.isSelectable = true,
    this.minimumStayDays,
  });

  @override
  State<AvailabilityCalendarWidget> createState() =>
      _AvailabilityCalendarWidgetState();
}

class _AvailabilityCalendarWidgetState
    extends State<AvailabilityCalendarWidget> {
  late DateTime _focusedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Normalized day -> availability status
  final Map<DateTime, AvailabilityStatus> _availabilityMap = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.selectedStartDate ?? DateTime.now();
    _rangeStart = widget.selectedStartDate;
    _rangeEnd = widget.selectedEndDate;
    _buildAvailabilityMap();
  }

  @override
  void didUpdateWidget(AvailabilityCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availabilityData != widget.availabilityData) {
      _buildAvailabilityMap();
    }
    if (oldWidget.selectedStartDate != widget.selectedStartDate ||
        oldWidget.selectedEndDate != widget.selectedEndDate) {
      _rangeStart = widget.selectedStartDate;
      _rangeEnd = widget.selectedEndDate;
    }
  }

  void _buildAvailabilityMap() {
    _availabilityMap.clear();
    for (var availability in widget.availabilityData) {
      DateTime currentDate = availability.startDate;
      while (currentDate.isBefore(availability.endDate) ||
          currentDate.isAtSameMomentAs(availability.endDate)) {
        final normalized =
            DateTime.utc(currentDate.year, currentDate.month, currentDate.day);
        _availabilityMap[normalized] = availability.isAvailable
            ? AvailabilityStatus.available
            : AvailabilityStatus.booked;
        currentDate = currentDate.add(const Duration(days: 1));
      }
    }
  }

  AvailabilityStatus _getStatusForDay(DateTime day) {
    final normalized = DateTime.utc(day.year, day.month, day.day);
    final today = DateTime.now();
    final normalizedToday = DateTime.utc(today.year, today.month, today.day);

    // Past dates are unavailable
    if (normalized.isBefore(normalizedToday)) {
      return AvailabilityStatus.past;
    }

    // Today is unavailable for booking (need at least 1 day advance)
    if (normalized.isAtSameMomentAs(normalizedToday)) {
      return AvailabilityStatus.past;
    }

    return _availabilityMap[normalized] ?? AvailabilityStatus.available;
  }

  bool _isDaySelectable(DateTime day) {
    if (!widget.isSelectable) return false;
    final status = _getStatusForDay(day);
    return status == AvailabilityStatus.available;
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _rangeStart = start;
      _rangeEnd = end;
      _focusedDay = focusedDay;
    });

    if (start != null && end != null && widget.onDateRangeSelected != null) {
      // Validate the entire range is available
      bool rangeValid = true;
      DateTime cursor = start;
      while (!cursor.isAfter(end)) {
        if (_getStatusForDay(cursor) != AvailabilityStatus.available) {
          rangeValid = false;
          break;
        }
        cursor = cursor.add(const Duration(days: 1));
      }

      if (rangeValid) {
        widget.onDateRangeSelected!(start, end);
      } else {
        // Show error for invalid range
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected range includes unavailable dates'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!widget.isSelectable) return;

    final status = _getStatusForDay(selectedDay);
    if (status != AvailabilityStatus.available) return;

    // For monthly rentals: single date selection only
    if (widget.rentalType == PropertyRentalType.monthly) {
      setState(() {
        _rangeStart = selectedDay;
        _rangeEnd = null; // Monthly doesn't use range end from calendar
        _focusedDay = focusedDay;
      });
      // Callback with just the start date
      widget.onStartDateSelected?.call(selectedDay);
      return;
    }

    // For daily rentals: range selection
    setState(() {
      if (_rangeStart == null || _rangeEnd != null) {
        // Start new selection
        _rangeStart = selectedDay;
        _rangeEnd = null;
      } else {
        // Complete the range
        if (selectedDay.isBefore(_rangeStart!)) {
          _rangeEnd = _rangeStart;
          _rangeStart = selectedDay;
        } else {
          _rangeEnd = selectedDay;
        }

        // Validate and callback
        if (_rangeStart != null &&
            _rangeEnd != null &&
            widget.onDateRangeSelected != null) {
          bool rangeValid = true;
          DateTime cursor = _rangeStart!;
          while (!cursor.isAfter(_rangeEnd!)) {
            if (_getStatusForDay(cursor) != AvailabilityStatus.available) {
              rangeValid = false;
              break;
            }
            cursor = cursor.add(const Duration(days: 1));
          }

          if (rangeValid) {
            widget.onDateRangeSelected!(_rangeStart!, _rangeEnd!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selected range includes unavailable dates'),
                backgroundColor: Colors.red,
              ),
            );
            // Reset selection
            _rangeStart = null;
            _rangeEnd = null;
          }
        }
      }
      _focusedDay = focusedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        _buildLegend(),
        const SizedBox(height: 12),

        // Calendar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            rangeStartDay: _rangeStart,
            rangeEndDay: widget.rentalType == PropertyRentalType.monthly ? null : _rangeEnd,
            rangeSelectionMode: widget.isSelectable && widget.rentalType == PropertyRentalType.daily
                ? RangeSelectionMode.toggledOn
                : RangeSelectionMode.disabled,
            enabledDayPredicate: _isDaySelectable,
            onDaySelected: _onDaySelected,
            onRangeSelected: _onRangeSelected,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) =>
                  _buildDayCell(day, false, false),
              todayBuilder: (context, day, focusedDay) =>
                  _buildDayCell(day, true, false),
              disabledBuilder: (context, day, focusedDay) =>
                  _buildDayCell(day, false, true),
              outsideBuilder: (context, day, focusedDay) =>
                  _buildDayCell(day, false, false, isOutside: true),
              rangeStartBuilder: (context, day, focusedDay) =>
                  _buildSelectedDayCell(day, isStart: true),
              rangeEndBuilder: (context, day, focusedDay) =>
                  _buildSelectedDayCell(day, isEnd: true),
              withinRangeBuilder: (context, day, focusedDay) =>
                  _buildWithinRangeCell(day),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).primaryColor),
                borderRadius: BorderRadius.circular(8),
              ),
              formatButtonTextStyle: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 12,
              ),
              titleCentered: true,
              titleTextStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(color: Colors.black87),
            ),
          ),
        ),

        // Selection info
        if (_rangeStart != null) ...[
          const SizedBox(height: 12),
          _buildSelectionInfo(),
        ],

        // Minimum stay info
        if (widget.minimumStayDays != null) ...[
          const SizedBox(height: 8),
          Text(
            'Minimum stay: ${widget.minimumStayDays} ${widget.rentalType == PropertyRentalType.daily ? 'days' : 'days (${(widget.minimumStayDays! / 30).ceil()} month${(widget.minimumStayDays! / 30).ceil() > 1 ? 's' : ''})'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem(Colors.green, 'Available'),
        _buildLegendItem(Colors.red, 'Booked'),
        _buildLegendItem(Colors.grey, 'Past/Unavailable'),
        if (_rangeStart != null)
          _buildLegendItem(Theme.of(context).primaryColor, 'Selected'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildDayCell(DateTime day, bool isToday, bool isDisabled,
      {bool isOutside = false}) {
    final status = _getStatusForDay(day);

    Color backgroundColor;
    Color textColor;
    Color borderColor;

    switch (status) {
      case AvailabilityStatus.available:
        backgroundColor = Colors.green.withValues(alpha: 0.15);
        textColor = Colors.green[800]!;
        borderColor = Colors.green.withValues(alpha: 0.5);
        break;
      case AvailabilityStatus.booked:
        backgroundColor = Colors.red.withValues(alpha: 0.15);
        textColor = Colors.red[800]!;
        borderColor = Colors.red.withValues(alpha: 0.5);
        break;
      case AvailabilityStatus.past:
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        borderColor = Colors.grey.withValues(alpha: 0.3);
        break;
    }

    if (isOutside) {
      backgroundColor = Colors.transparent;
      textColor = Colors.grey.withValues(alpha: 0.5);
      borderColor = Colors.transparent;
    }

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDayCell(DateTime day,
      {bool isStart = false, bool isEnd = false}) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (isStart || isEnd)
              Text(
                isStart ? 'IN' : 'OUT',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithinRangeCell(DateTime day) {
    final status = _getStatusForDay(day);
    final isConflict = status != AvailabilityStatus.available;

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isConflict
            ? Colors.red.withValues(alpha: 0.3)
            : Theme.of(context).primaryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: isConflict
            ? Border.all(color: Colors.red, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: isConflict
                ? Colors.red[800]
                : Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionInfo() {
    final nights = _rangeEnd != null
        ? _rangeEnd!.difference(_rangeStart!).inDays
        : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.date_range,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _rangeEnd != null
                      ? '${_formatDate(_rangeStart!)} → ${_formatDate(_rangeEnd!)}'
                      : 'Select end date',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (_rangeEnd != null)
                  Text(
                    widget.rentalType == PropertyRentalType.daily
                        ? '$nights night${nights != 1 ? 's' : ''}'
                        : '${(nights / 30).ceil()} month${(nights / 30).ceil() != 1 ? 's' : ''} ($nights days)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
              ],
            ),
          ),
          if (_rangeStart != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                setState(() {
                  _rangeStart = null;
                  _rangeEnd = null;
                });
              },
              tooltip: 'Clear selection',
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

enum AvailabilityStatus {
  available,
  booked,
  past,
}
