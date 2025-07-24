import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/models/lease_extension_request.dart';
import 'package:e_rents_mobile/feature/property_detail/providers/property_detail_provider.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/feature/profile/providers/profile_provider.dart';

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
  bool _isExtending = false;
  bool _isSubmittingExtension = false;
  String? _errorMessage;
  final Set<DateTime> _selectedExtensionDates = {};
  double _extensionPrice = 0.0;
  DateTime _currentDisplayMonth = DateTime.now();

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
      final propertyDetailProvider = context.read<PropertyDetailProvider>();
      // Load availability for a wider date range (12 months)
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      final endDate = DateTime.now().add(const Duration(days: 365));

      // Fetch availability from service (currently using mock data below)
      await propertyDetailProvider.getPropertyAvailability(
        widget.propertyId,
        startDate: startDate,
        endDate: endDate,
      );

      // Generate better mock availability data with more available days
      final Map<DateTime, bool> enhancedAvailability = {};

      for (int i = -30; i <= 365; i++) {
        final date = DateTime.now().add(Duration(days: i));
        final normalizedDate = DateTime(date.year, date.month, date.day);

        // Make most days available (80% availability) with some patterns
        // Avoid some weekends and make scattered unavailable days
        bool isAvailable = true;

        // Make some weekend days unavailable (not all)
        if (date.weekday == 6 || date.weekday == 7) {
          isAvailable = i % 3 != 0; // Every 3rd weekend day unavailable
        }

        // Make some random weekdays unavailable (maintenance, existing bookings)
        if (date.weekday <= 5) {
          isAvailable = i % 7 != 1; // Every 7th weekday unavailable
        }

        // Always make past dates unavailable
        if (date.isBefore(DateTime.now())) {
          isAvailable = false;
        }

        enhancedAvailability[normalizedDate] = isAvailable;
      }

      setState(() {
        _availability = enhancedAvailability;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load availability data';
        _isLoading = false;
      });
    }
  }

  void _calculateExtensionPrice() {
    _extensionPrice = _selectedExtensionDates.length * widget.booking.dailyRate;
  }

  void _toggleExtensionMode() {
    setState(() {
      _isExtending = !_isExtending;
      if (!_isExtending) {
        _selectedExtensionDates.clear();
        _extensionPrice = 0.0;
      }
    });
  }

  void _navigateMonth(int monthOffset) {
    setState(() {
      _currentDisplayMonth = DateTime(
        _currentDisplayMonth.year,
        _currentDisplayMonth.month + monthOffset,
        1,
      );
    });
  }

  void _toggleDateSelection(DateTime date) {
    if (!_isExtending) return;

    final bookingEnd =
        widget.booking.endDate ?? DateTime.now().add(const Duration(days: 365));
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedBookingEnd =
        DateTime(bookingEnd.year, bookingEnd.month, bookingEnd.day);

    // Only allow selection of dates after current booking end and available dates
    if (normalizedDate.isAfter(normalizedBookingEnd) &&
        (_availability[normalizedDate] ?? false)) {
      setState(() {
        if (_selectedExtensionDates.contains(normalizedDate)) {
          _selectedExtensionDates.remove(normalizedDate);
        } else {
          _selectedExtensionDates.add(normalizedDate);
        }
        _calculateExtensionPrice();
      });
    }
  }

  Future<void> _submitBookingExtension() async {
    if (_selectedExtensionDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select dates to extend your booking')),
      );
      return;
    }

    setState(() {
      _isSubmittingExtension = true;
    });

    try {
      // Sort dates to get the range
      final sortedDates = _selectedExtensionDates.toList()..sort();
      final endExtension = sortedDates.last;

      // In a real app, you would call an API to extend the booking
      final propertyDetailProvider = context.read<PropertyDetailProvider>();
      
      // Mock extension request - in reality this would be a separate endpoint
      final success = await propertyDetailProvider.requestLeaseExtension(
        LeaseExtensionRequest(
          bookingId: widget.bookingId,
          propertyId: widget.propertyId,
          tenantId: context.read<ProfileProvider>().currentUser?.userId ?? 1,
          newEndDate: endExtension,
          reason:
              'Booking extension for additional ${_selectedExtensionDates.length} days',
          dateRequested: DateTime.now(),
        ),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Booking extension request submitted! Additional ${_selectedExtensionDates.length} days for \$${_extensionPrice.toStringAsFixed(2)}',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _toggleExtensionMode();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Failed to submit extension request. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingExtension = false;
        });
      }
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
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Booking summary
                          _buildBookingInfoCard(),
                          const SizedBox(height: 24),

                          // Extension mode header
                          if (_isExtending) ...[
                            _buildExtensionHeader(),
                            const SizedBox(height: 16),
                          ],

                          // Calendar section
                          _buildCalendarSection(),
                          const SizedBox(height: 24),

                          // Availability legend
                          _buildAvailabilityLegend(),
                          const SizedBox(height: 24),

                          // Booking status
                          if (!_isExtending) _buildBookingStatusCard(),
                        ],
                      ),
                    ),

                    // Extension summary and submit button
                    if (_isExtending) _buildExtensionBottomSheet(),
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

  Widget _buildExtensionHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_box_outlined, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Extend Your Booking',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Select additional dates on the calendar below. Available dates are shown in green.',
            style: TextStyle(fontSize: 14),
          ),
          if (_selectedExtensionDates.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Selected: ${_selectedExtensionDates.length} additional days',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            runSpacing: 8,
            children: [
              Text(
                _isExtending
                    ? 'Select Additional Dates'
                    : 'Property Availability Calendar',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Extension toggle button moved here for better UX
              if (!_isExtending)
                CustomButton.compact(
                  label: 'Extend Booking',
                  icon: Icons.edit_calendar_outlined,
                  width: ButtonWidth.content,
                  isLoading: false,
                  onPressed: _toggleExtensionMode,
                )
              else
                CustomOutlinedButton.compact(
                  label: 'Cancel',
                  icon: Icons.close,
                  width: OutlinedButtonWidth.content,
                  isLoading: false,
                  onPressed: _toggleExtensionMode,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isExtending
                ? 'Tap on available dates (green) to add them to your booking extension'
                : 'View when the property is available for future bookings',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // Monthly calendar view with proper navigation
          _buildMonthlyCalendar(_currentDisplayMonth),
        ],
      ),
    );
  }

  Widget _buildMonthlyCalendar(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final firstDayOfWeek = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    return Column(
      children: [
        // Month header with navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => _navigateMonth(-1),
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous month',
            ),
            Text(
              DateFormat.yMMMM().format(month),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () => _navigateMonth(1),
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next month',
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
              return Expanded(
                child: _buildCalendarDay(date),
              );
            }),
          );
        }).where((row) {
          // Only show rows that have at least one valid day
          final children = row.children as List;
          return children
              .any((child) => child is Expanded && child.child is! SizedBox);
        }),
      ],
    );
  }

  Widget _buildCalendarDay(DateTime date) {
    final isToday = date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year;
    final isInBookingRange = _isDateInBookingRange(date);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final isAvailable = _availability[normalizedDate] ?? false;
    final isSelected = _selectedExtensionDates.contains(normalizedDate);
    final bookingEnd =
        widget.booking.endDate ?? DateTime.now().add(const Duration(days: 365));
    final isAfterBooking = normalizedDate
        .isAfter(DateTime(bookingEnd.year, bookingEnd.month, bookingEnd.day));

    Color? backgroundColor;
    Color? textColor;
    Border? border;

    if (isToday) {
      backgroundColor = Theme.of(context).primaryColor;
      textColor = Colors.white;
      border = Border.all(color: Colors.white, width: 2);
    } else if (isInBookingRange) {
      backgroundColor = Colors.blue.withValues(alpha: 0.3);
      textColor = Colors.blue[800];
    } else if (isSelected) {
      backgroundColor = Colors.orange;
      textColor = Colors.white;
    } else if (_isExtending && isAfterBooking && isAvailable) {
      backgroundColor = Colors.green.withValues(alpha: 0.3);
      textColor = Colors.green[800];
    } else if (!isAvailable) {
      backgroundColor = Colors.red.withValues(alpha: 0.2);
      textColor = Colors.red[700];
    } else if (isAvailable) {
      backgroundColor = Colors.green.withValues(alpha: 0.2);
      textColor = Colors.green[700];
    }

    return GestureDetector(
      onTap: () => _toggleDateSelection(date),
      child: Container(
        height: 40,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: border,
        ),
        child: Center(
          child: Text(
            date.day.toString(),
            style: TextStyle(
              color: textColor ?? Colors.black,
              fontWeight: isToday || isSelected || isInBookingRange
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
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
          if (_isExtending) ...[
            _buildLegendItem(Colors.orange, 'Selected for extension'),
            _buildLegendItem(
                Colors.green.withValues(alpha: 0.3), 'Available for extension'),
          ] else ...[
            _buildLegendItem(Colors.green.withValues(alpha: 0.2), 'Available'),
          ],
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

  Widget _buildExtensionBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedExtensionDates.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Extension Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_selectedExtensionDates.length} days',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${widget.booking.dailyRate.toStringAsFixed(0)} × ${_selectedExtensionDates.length} days',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        '\$${_extensionPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: CustomOutlinedButton(
                  label: 'Cancel',
                  width: OutlinedButtonWidth.expanded,
                  isLoading: false,
                  onPressed: _toggleExtensionMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  icon: Icons.edit_calendar_outlined,
                  isLoading: _isSubmittingExtension,
                  onPressed: _selectedExtensionDates.isNotEmpty &&
                          !_isSubmittingExtension
                      ? () => _submitBookingExtension()
                      : () {},
                  label: Text(
                    _isSubmittingExtension ? 'Submitting...' : 'Extend Booking',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
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
      case BookingStatus.upcoming:
        return 'Upcoming';
      case BookingStatus.active:
        return 'Active';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor() {
    switch (widget.booking.status) {
      case BookingStatus.upcoming:
        return Colors.blue;
      case BookingStatus.active:
        return Colors.green;
      case BookingStatus.completed:
        return Colors.grey;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.booking.status) {
      case BookingStatus.upcoming:
        return Icons.schedule;
      case BookingStatus.active:
        return Icons.check_circle;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusDescription() {
    switch (widget.booking.status) {
      case BookingStatus.upcoming:
        return 'Your booking is confirmed and starts on ${DateFormat.yMMMd().format(widget.booking.startDate)}.';
      case BookingStatus.active:
        return 'You are currently staying at this property. Your booking is active.';
      case BookingStatus.completed:
        return 'Your stay has been completed. Thank you for choosing our property!';
      case BookingStatus.cancelled:
        return 'This booking has been cancelled.';
    }
  }
}
