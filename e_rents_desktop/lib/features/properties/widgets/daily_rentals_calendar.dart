import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/models/booking.dart';
import 'package:e_rents_desktop/models/enums/booking_status.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/features/chat/providers/chat_provider.dart';
import 'package:e_rents_desktop/router.dart';

/// Calendar widget for daily rentals showing bookings with tenant information
class DailyRentalsCalendar extends StatefulWidget {
  final int propertyId;

  const DailyRentalsCalendar({
    super.key,
    required this.propertyId,
  });

  @override
  State<DailyRentalsCalendar> createState() => _DailyRentalsCalendarState();
}

class _DailyRentalsCalendarState extends State<DailyRentalsCalendar> {
  late DateTime _focusedMonth;
  DateTime? _selectedDate;
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bookings = await context.read<PropertyProvider>().fetchPropertyBookings(widget.propertyId);
      if (mounted) {
        setState(() {
          _bookings = bookings ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and legend
        Row(
          children: [
            const Icon(Icons.calendar_month, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            const Text(
              'Rental Calendar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            // Legend
            _buildLegendItem('Confirmed', Colors.green),
            const SizedBox(width: 12),
            _buildLegendItem('Pending', Colors.orange),
            const SizedBox(width: 12),
            _buildLegendItem('Completed', Colors.blue),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _loadBookings,
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isLoading)
          const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          _buildErrorState()
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar view
              Expanded(
                flex: 2,
                child: _buildCalendar(),
              ),
              const SizedBox(width: 16),
              // Selected date details panel
              Expanded(
                flex: 1,
                child: _buildDetailsPanel(),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildErrorState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text('Failed to load bookings: $_error')),
            TextButton(
              onPressed: _loadBookings,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                    });
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_focusedMonth),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Weekday headers
            Row(
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            // Calendar grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.2,
              ),
              itemCount: 42, // 6 weeks max
              itemBuilder: (context, index) {
                final dayNumber = index - firstWeekday + 1;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox();
                }

                final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
                final bookingsOnDate = _getBookingsForDate(date);
                final isSelected = _selectedDate != null &&
                    _selectedDate!.year == date.year &&
                    _selectedDate!.month == date.month &&
                    _selectedDate!.day == date.day;
                final isToday = DateTime.now().year == date.year &&
                    DateTime.now().month == date.month &&
                    DateTime.now().day == date.day;

                return _buildDayCell(date, dayNumber, bookingsOnDate, isSelected, isToday);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime date, int dayNumber, List<Booking> bookings, bool isSelected, bool isToday) {
    final hasBookings = bookings.isNotEmpty;
    final primaryColor = hasBookings ? _getBookingColor(bookings.first) : null;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.shade100
              : hasBookings
                  ? primaryColor?.withValues(alpha: 0.15)
                  : null,
          border: Border.all(
            color: isSelected
                ? Colors.blue
                : isToday
                    ? Colors.blue.shade300
                    : hasBookings
                        ? primaryColor ?? Colors.transparent
                        : Colors.transparent,
            width: isSelected || isToday ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayNumber.toString(),
              style: TextStyle(
                fontWeight: isToday || hasBookings ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue.shade800 : null,
              ),
            ),
            if (hasBookings) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < bookings.length && i < 3; i++)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: _getBookingColor(bookings[i]),
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (bookings.length > 3)
                    Text(
                      '+${bookings.length - 3}',
                      style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Booking> _getBookingsForDate(DateTime date) {
    return _bookings.where((booking) {
      final start = booking.startDate;
      final end = booking.endDate ?? booking.startDate;
      final dateOnly = DateTime(date.year, date.month, date.day);
      final startOnly = DateTime(start.year, start.month, start.day);
      final endOnly = DateTime(end.year, end.month, end.day);
      return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
    }).toList();
  }

  Color _getBookingColor(Booking booking) {
    switch (booking.status) {
      case BookingStatus.upcoming:
      case BookingStatus.active:
        return Colors.green;
      case BookingStatus.completed:
        return Colors.blue;
      case BookingStatus.cancelled:
        return Colors.grey;
      case BookingStatus.pending:
        return Colors.amber;
    }
  }

  Widget _buildDetailsPanel() {
    if (_selectedDate == null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'Select a date to view details',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bookingsOnDate = _getBookingsForDate(_selectedDate!);
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected date header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateFormat.format(_selectedDate!),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Bookings list
          if (bookingsOnDate.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_available, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'No bookings on this date',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Available for booking',
                      style: TextStyle(color: Colors.green.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bookingsOnDate.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _BookingTenantCard(
                  booking: bookingsOnDate[index],
                  onRefresh: _loadBookings,
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Card showing booking and tenant details
class _BookingTenantCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onRefresh;

  const _BookingTenantCard({
    required this.booking,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd');
    final statusColor = _getStatusColor(booking.status);
    final tenantName = booking.tenantName ?? booking.userName ?? 'Guest #${booking.userId}';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tenant info row
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  tenantName.isNotEmpty ? tenantName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenantName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (booking.userEmail != null)
                      Text(
                        booking.userEmail!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  booking.status.displayName,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Booking details
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  Icons.date_range,
                  '${dateFormat.format(booking.startDate)} - ${booking.endDate != null ? dateFormat.format(booking.endDate!) : 'TBD'}',
                ),
                const SizedBox(height: 6),
                _buildDetailRow(
                  Icons.nights_stay,
                  '${_calculateNights()} night${_calculateNights() == 1 ? '' : 's'}',
                ),
                const SizedBox(height: 6),
                _buildDetailRow(
                  Icons.attach_money,
                  booking.formattedTotalPrice,
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () => _openChat(context),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'More actions',
                onSelected: (action) => _handleAction(context, action),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: ListTile(
                      leading: Icon(Icons.visibility, size: 20),
                      title: Text('View Details'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  if (booking.status == BookingStatus.upcoming ||
                      booking.status == BookingStatus.active) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'cancel',
                      child: ListTile(
                        leading: Icon(Icons.cancel, color: Colors.red, size: 20),
                        title: Text('Cancel Booking'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateNights() {
    if (booking.endDate == null) return 1;
    return booking.endDate!.difference(booking.startDate).inDays;
  }

  Widget _buildDetailRow(IconData icon, String text, {bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
      case BookingStatus.active:
        return Colors.green;
      case BookingStatus.completed:
        return Colors.blue;
      case BookingStatus.cancelled:
        return Colors.grey;
      case BookingStatus.pending:
        return Colors.amber;
    }
  }

  Future<void> _openChat(BuildContext context) async {
    final chatProvider = context.read<ChatProvider>();
    if (booking.userId == null) return;
    final success = await chatProvider.ensureContact(booking.userId!);
    if (success && context.mounted) {
      chatProvider.selectContact(booking.userId!);
      context.go(AppRoutes.chat);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start chat with guest')),
      );
    }
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'view':
        _showBookingDetails(context);
        break;
      case 'cancel':
        _showCancelDialog(context);
        break;
    }
  }

  void _showBookingDetails(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final tenantName = booking.tenantName ?? booking.userName ?? 'Guest #${booking.userId}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.event, color: Colors.blue),
            const SizedBox(width: 8),
            Text('Booking #${booking.bookingId}'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Guest', tenantName),
              if (booking.userEmail != null) _buildInfoRow('Email', booking.userEmail!),
              _buildInfoRow('Check-in', dateFormat.format(booking.startDate)),
              _buildInfoRow('Check-out', booking.endDate != null ? dateFormat.format(booking.endDate!) : 'TBD'),
              _buildInfoRow('Nights', '${_calculateNights()}'),
              _buildInfoRow('Total', booking.formattedTotalPrice),
              _buildInfoRow('Status', booking.status.displayName),
              if (booking.paymentReference != null && booking.paymentReference!.isNotEmpty) ...[
                const Divider(),
                _buildInfoRow('Payment Ref', booking.paymentReference!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
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
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text('Cancel Booking'),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel booking #${booking.bookingId}?\n\n'
          'The guest will be notified and any payments will be refunded according to your cancellation policy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onRefresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking cancelled successfully'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }
}
