import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/services/lease_service.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/base/base_screen.dart';

class ManageBookingScreen extends StatefulWidget {
  final int propertyId;
  final int bookingId;
  final Booking booking;

  const ManageBookingScreen({
    super.key,
    required this.propertyId,
    required this.bookingId,
    required this.booking,
  });

  @override
  State<ManageBookingScreen> createState() => _ManageBookingScreenState();
}

class _ManageBookingScreenState extends State<ManageBookingScreen> {
  Map<DateTime, bool> _availability = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPropertyAvailability();
  }

  Future<void> _loadPropertyAvailability() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final leaseService = LeaseService(context.read<ApiService>());
      final availability = await leaseService.getPropertyAvailability(
        widget.propertyId,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 180)),
      );

      setState(() {
        _availability = availability;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load availability data';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      appBar: CustomAppBar(
        title: 'Manage Booking',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPropertyAvailability,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Booking summary
                    _buildBookingInfoCard(),
                    const SizedBox(height: 24),

                    // Calendar view
                    _buildCalendarSection(),
                    const SizedBox(height: 24),

                    // Availability legend
                    _buildAvailabilityLegend(),
                    const SizedBox(height: 24),

                    // Booking status
                    _buildBookingStatusCard(),
                  ],
                ),
    );
  }

  Widget _buildBookingInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_available,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Booking Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Property', widget.booking.propertyName),
          _buildInfoRow(
              'Check-in', DateFormat.yMMMd().format(widget.booking.startDate)),
          _buildInfoRow(
              'Check-out',
              widget.booking.endDate != null
                  ? DateFormat.yMMMd().format(widget.booking.endDate!)
                  : 'Indefinite'),
          _buildInfoRow('Duration', _calculateDuration()),
          _buildInfoRow('Total Price',
              '\$${widget.booking.totalPrice.toStringAsFixed(2)}'),
          _buildInfoRow('Status', _getStatusText(widget.booking.status)),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Property Availability Calendar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'View when the property is available for future bookings',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        _buildMonthlyCalendar(),
      ],
    );
  }

  Widget _buildMonthlyCalendar() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Month header
          Text(
            DateFormat.yMMMM().format(currentMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Calendar grid
          _buildCalendarGrid(currentMonth),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final firstDayOfWeek = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    return Column(
      children: [
        // Weekday headers
        Row(
          children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),

        // Calendar days
        ...List.generate(6, (weekIndex) {
          return Row(
            children: List.generate(7, (dayIndex) {
              final dayNumber = weekIndex * 7 + dayIndex - firstDayOfWeek + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(child: SizedBox(height: 40));
              }

              final date = DateTime(month.year, month.month, dayNumber);
              final isToday = date.day == DateTime.now().day &&
                  date.month == DateTime.now().month &&
                  date.year == DateTime.now().year;
              final isBookingDate = _isDateInBookingRange(date);
              final isAvailable =
                  _availability[DateTime(date.year, date.month, date.day)] ??
                      true;

              return Expanded(
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isToday
                        ? Theme.of(context).primaryColor
                        : isBookingDate
                            ? Colors.blue.withValues(alpha: 0.3)
                            : isAvailable
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      dayNumber.toString(),
                      style: TextStyle(
                        color: isToday
                            ? Colors.white
                            : isBookingDate
                                ? Colors.blue[800]
                                : Colors.black,
                        fontWeight: isToday || isBookingDate
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        })
            .where((row) =>
                // Only show rows that have at least one valid day
                (row.children as List).any((child) =>
                    child is Expanded &&
                    child.child is Container &&
                    (child.child as Container).child != null))
            .toList(),
      ],
    );
  }

  Widget _buildAvailabilityLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildLegendItem(Theme.of(context).primaryColor, 'Today'),
          _buildLegendItem(
              Colors.blue.withValues(alpha: 0.3), 'Your booking period'),
          _buildLegendItem(Colors.green.withValues(alpha: 0.2), 'Available'),
          _buildLegendItem(Colors.red.withValues(alpha: 0.2), 'Unavailable'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildBookingStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor().withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getStatusIcon(), color: _getStatusColor()),
              const SizedBox(width: 8),
              Text(
                'Booking Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getStatusDescription(),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isDateInBookingRange(DateTime date) {
    final startDate = DateTime(
      widget.booking.startDate.year,
      widget.booking.startDate.month,
      widget.booking.startDate.day,
    );

    if (widget.booking.endDate == null) {
      return date.isAfter(startDate) || date.isAtSameMomentAs(startDate);
    }

    final endDate = DateTime(
      widget.booking.endDate!.year,
      widget.booking.endDate!.month,
      widget.booking.endDate!.day,
    );

    return (date.isAfter(startDate) || date.isAtSameMomentAs(startDate)) &&
        (date.isBefore(endDate) || date.isAtSameMomentAs(endDate));
  }

  String _calculateDuration() {
    if (widget.booking.endDate == null) {
      final daysSinceStart =
          DateTime.now().difference(widget.booking.startDate).inDays;
      return '$daysSinceStart days (ongoing)';
    }

    final duration =
        widget.booking.endDate!.difference(widget.booking.startDate).inDays;
    return '$duration days';
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.Upcoming:
        return 'Upcoming';
      case BookingStatus.Active:
        return 'Active';
      case BookingStatus.Completed:
        return 'Completed';
      case BookingStatus.Cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor() {
    switch (widget.booking.status) {
      case BookingStatus.Upcoming:
        return Colors.blue;
      case BookingStatus.Active:
        return Colors.green;
      case BookingStatus.Completed:
        return Colors.grey;
      case BookingStatus.Cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.booking.status) {
      case BookingStatus.Upcoming:
        return Icons.schedule;
      case BookingStatus.Active:
        return Icons.check_circle;
      case BookingStatus.Completed:
        return Icons.done_all;
      case BookingStatus.Cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusDescription() {
    switch (widget.booking.status) {
      case BookingStatus.Upcoming:
        return 'Your booking is confirmed and starts on ${DateFormat.yMMMd().format(widget.booking.startDate)}.';
      case BookingStatus.Active:
        return 'You are currently staying at this property. Your booking is active.';
      case BookingStatus.Completed:
        return 'Your stay has been completed. Thank you for choosing our property!';
      case BookingStatus.Cancelled:
        return 'This booking has been cancelled.';
    }
  }
}
