import 'package:e_rents_mobile/core/models/property_detail.dart';
import 'package:e_rents_mobile/core/utils/date_extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/core/enums/property_enums.dart';
import 'package:e_rents_mobile/features/property_detail/providers/property_availability_provider.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/features/profile/providers/user_profile_provider.dart';
import 'package:e_rents_mobile/features/property_detail/providers/property_rental_provider.dart';
import 'package:e_rents_mobile/features/property_detail/widgets/property_availability/availability_calendar_widget.dart';

class BookingAvailabilityWidget extends StatefulWidget {
  final PropertyDetail property;

  const BookingAvailabilityWidget({
    super.key,
    required this.property,
  });

  @override
  State<BookingAvailabilityWidget> createState() =>
      _BookingAvailabilityWidgetState();
}

class _BookingAvailabilityWidgetState extends State<BookingAvailabilityWidget> {
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 8));
  bool _isLoading = true;
  String? _loadError; // API/network errors
  String? _validationError; // Date selection validation errors
  Map<String, dynamic>? _pricingDetails;
  int _months = 1; // For monthly leases
  bool _showCalendar = true; // Toggle for calendar visibility
  // Normalized day -> availability flag (UTC date-only)
  final Map<DateTime, bool> _availabilityMap = <DateTime, bool>{};

  @override
  void initState() {
    super.initState();
    _initializeDates();
    // Defer provider-driven state changes until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Persist initial selection in shared provider AFTER first frame to avoid notify during build
      try {
        context
            .read<PropertyRentalProvider>()
            .setBookingDateRange(_startDate, _endDate);
      } catch (_) {}
      _loadAvailability();
    });
  }

  void _setMonths(int months) {
    final minimumStayDays = widget.property.minimumStayDays ?? 30;
    final minMonths = (minimumStayDays / 30).ceil();
    final clamped = months < minMonths ? minMonths : months;
    setState(() {
      _months = clamped;
      _endDate = _startDate.add(Duration(days: 30 * _months));
    });
    // Persist selection in shared provider so footer checkout uses it
    try {
      // ignore: use_build_context_synchronously
      context.read<PropertyRentalProvider>().setBookingDateRange(_startDate, _endDate);
    } catch (_) {}
    _calculatePricing();
    _validateCurrentSelection();
  }

  void _initializeDates() {
    // Set appropriate default dates based on property type
    if (widget.property.rentalType == PropertyRentalType.daily) {
      _endDate = _startDate.add(const Duration(days: 7)); // 1 week default
    } else {
      // Monthly: default months respects minimumStayDays if provided
      final minimumStayDays = widget.property.minimumStayDays ?? 30;
      final minMonths = (minimumStayDays / 30).ceil();
      _months = _months < minMonths ? minMonths : _months;
      _endDate = _startDate.add(Duration(days: 30 * _months));
    }
    _calculatePricing();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _validationError = null;
    });

    try {
      final availabilityProvider = context.read<PropertyDetailAvailabilityProvider>();
      
      // Fetch availability data for the property
      await availabilityProvider.fetchAvailabilityData(
        widget.property.propertyId,
        DateTime.now(),
        DateTime.now().add(const Duration(days: 90)),
      );

      // Convert availability data to normalized map for quick per-day checks
      // Normalize keys to UTC 00:00 to avoid timezone mismatches
      for (var availability in availabilityProvider.availabilityData) {
        // Create entries for each day in the range
        DateTime currentDate = availability.startDate;
        while (currentDate.isBefore(availability.endDate) || currentDate.isAtSameMomentAs(availability.endDate)) {
          final normalized = DateTime.utc(currentDate.year, currentDate.month, currentDate.day);
          _availabilityMap[normalized] = availability.isAvailable;
          currentDate = currentDate.add(const Duration(days: 1));
        }
      }

      setState(() {
        _isLoading = false;
      });

      // Auto-select the first available date range if current selection has conflicts
      _autoSelectAvailableDates();
      _validateCurrentSelection();
    } catch (e) {
      setState(() {
        _loadError = 'Failed to load availability';
        _isLoading = false;
      });
    }
  }

  Future<void> _calculatePricing() async {
    // Fixed pricing rules:
    // - Daily rental: total = nights * (dailyRate ?? price)
    // - Monthly rental: total = monthly price (property.price)
    try {
      final isDaily = widget.property.rentalType == PropertyRentalType.daily;
      Map<String, dynamic> pricing;

      if (isDaily) {
        final nights = _endDate.difference(_startDate).inDays;
        final unitPrice = (widget.property.dailyRate ?? widget.property.price);
        final total = (nights > 0 ? nights : 0) * unitPrice;
        pricing = {
          'unitCount': nights,
          'unitLabel': 'days',
          'total': total,
          'isMonthly': false,
        };
      } else {
        // Monthly: no upfront payment; tenant sends a request for landlord approval
        pricing = {
          'unitCount': _months,
          'unitLabel': _months == 1 ? 'month' : 'months',
          'total': widget.property.price, // display monthly price for information
          'isMonthly': true,
        };
      }

      setState(() {
        _pricingDetails = pricing;
      });
    } catch (e) {
      debugPrint('Error calculating pricing: $e');
      setState(() {
        _pricingDetails = null;
      });
    }
  }

  void _validateCurrentSelection() {
    // Validate only for daily rentals; monthly flow is request-based and validated server-side
    if (widget.property.rentalType != PropertyRentalType.daily) {
      setState(() {
        _validationError = null;
      });
      return;
    }

    // Normalize selected range to date-only and check each day is available
    final DateTime start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final DateTime end = DateTime(_endDate.year, _endDate.month, _endDate.day);
    bool ok = true;
    DateTime? firstBlocked;
    DateTime cursor = start;
    while (!cursor.isAfter(end.subtract(const Duration(days: 1)))) {
      final key = DateTime.utc(cursor.year, cursor.month, cursor.day);
      final isAvailable = _availabilityMap[key];
      if (isAvailable == false) {
        ok = false;
        firstBlocked = cursor;
        break;
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    setState(() {
      if (ok) {
        _validationError = null;
      } else {
        final fb = firstBlocked!;
        _validationError = 'Selected dates include an unavailable day on ${fb.day}/${fb.month}/${fb.year}. Please pick different dates.';
      }
    });

    // Sync validation state with provider so footer can disable checkout button
    try {
      context.read<PropertyRentalProvider>().setAvailabilityConflict(!ok);
    } catch (_) {}
  }

  /// Check if a specific date is available based on the availability map
  bool _isDateAvailable(DateTime date) {
    final normalized = DateTime.utc(date.year, date.month, date.day);
    // If we have data for this date, use it; otherwise assume available
    final available = _availabilityMap[normalized];
    return available ?? true;
  }

  /// Auto-select the first available dates if current selection has conflicts
  void _autoSelectAvailableDates() {
    if (widget.property.rentalType == PropertyRentalType.daily) {
      // For daily rentals, find first available range
      final durationDays = _endDate.difference(_startDate).inDays;
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final availableRange = _findFirstAvailableDateRange(tomorrow, durationDays > 0 ? durationDays : 7);
      
      if (availableRange.start != _startDate || availableRange.end != _endDate) {
        setState(() {
          _startDate = availableRange.start;
          _endDate = availableRange.end;
        });
        _calculatePricing();
        // Update provider with new dates
        try {
          context.read<PropertyRentalProvider>().setBookingDateRange(_startDate, _endDate);
        } catch (_) {}
      }
    } else {
      // For monthly rentals, find first available start date
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final availableStart = _findFirstAvailableDate(tomorrow);
      
      if (availableStart != _startDate) {
        setState(() {
          _startDate = availableStart;
          _endDate = availableStart.add(Duration(days: 30 * _months));
        });
        _calculatePricing();
        // Update provider with new dates
        try {
          context.read<PropertyRentalProvider>().setBookingDateRange(_startDate, _endDate);
        } catch (_) {}
      }
    }
  }

  /// Find the first available date starting from a given date
  DateTime _findFirstAvailableDate(DateTime from) {
    DateTime current = from;
    final maxDate = DateTime.now().add(const Duration(days: 365));
    while (current.isBefore(maxDate)) {
      if (_isDateAvailable(current)) {
        return current;
      }
      current = current.add(const Duration(days: 1));
    }
    return from; // Fallback to original if no available date found
  }

  /// Find the first available date range of given duration starting from a date
  DateTimeRange _findFirstAvailableDateRange(DateTime from, int durationDays) {
    DateTime current = from;
    final maxDate = DateTime.now().add(Duration(days: 365 - durationDays));
    
    while (current.isBefore(maxDate)) {
      bool rangeAvailable = true;
      for (int i = 0; i < durationDays; i++) {
        if (!_isDateAvailable(current.add(Duration(days: i)))) {
          rangeAvailable = false;
          // Skip to the day after the unavailable date
          current = current.add(Duration(days: i + 1));
          break;
        }
      }
      if (rangeAvailable) {
        return DateTimeRange(
          start: current,
          end: current.add(Duration(days: durationDays)),
        );
      }
    }
    // Fallback to original range if no available range found
    return DateTimeRange(start: from, end: from.add(Duration(days: durationDays)));
  }

  @override
  Widget build(BuildContext context) {
    // Determine if current user is the owner for UI disabling
    final userProvider = context.read<UserProfileProvider>();
    final currentUserId = userProvider.currentUser?.userId;
    final bool isOwner = currentUserId != null && currentUserId == widget.property.ownerId;
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show load error with retry option (API/network failure)
    if (_loadError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_loadError!),
            const SizedBox(height: 16),
            CustomButton.compact(
              label: 'Retry',
              onPressed: _loadAvailability,
              isLoading: false,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isOwner)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber[700], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'As the owner, you cannot book or apply for your own property.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.property.rentalType == PropertyRentalType.daily
                  ? 'Book Your Stay'
                  : 'Apply for Lease',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.property.rentalType == PropertyRentalType.daily
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                widget.property.rentalType == PropertyRentalType.daily
                    ? 'Daily Rental'
                    : 'Monthly Lease',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.property.rentalType == PropertyRentalType.daily
                      ? Colors.blue[700]
                      : Colors.green[700],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Calendar toggle button
        InkWell(
          onTap: () {
            setState(() {
              _showCalendar = !_showCalendar;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _showCalendar ? Icons.calendar_month : Icons.calendar_today,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _showCalendar ? 'Hide Availability Calendar' : 'View Availability Calendar',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showCalendar ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),

        // Availability Calendar (expandable)
        if (_showCalendar) ...[
          const SizedBox(height: 16),
          Consumer<PropertyDetailAvailabilityProvider>(
            builder: (context, availabilityProvider, child) {
              return AvailabilityCalendarWidget(
                availabilityData: availabilityProvider.availabilityData,
                rentalType: widget.property.rentalType,
                selectedStartDate: _startDate,
                selectedEndDate: _endDate,
                minimumStayDays: widget.property.minimumStayDays,
                isSelectable: !isOwner,
                onDateRangeSelected: (start, end) {
                  setState(() {
                    _startDate = start;
                    _endDate = end;
                    if (widget.property.rentalType == PropertyRentalType.monthly) {
                      _months = (end.difference(start).inDays / 30).ceil();
                    }
                  });
                  try {
                    context.read<PropertyRentalProvider>().setBookingDateRange(start, end);
                  } catch (_) {}
                  _calculatePricing();
                  _validateCurrentSelection();
                },
              );
            },
          ),
        ],

        const SizedBox(height: 16),

        // Date selection summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Date display
              Row(
                children: [
                  Expanded(
                    child: _buildDateDisplay(
                      widget.property.rentalType == PropertyRentalType.daily
                          ? 'Check-in'
                          : 'Lease Start',
                      _startDate,
                      Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateDisplay(
                      widget.property.rentalType == PropertyRentalType.daily
                          ? 'Check-out'
                          : 'Initial Period End',
                      _endDate,
                      Icons.event,
                    ),
                  ),
                ],
              ),
              // Pricing summary
              if (_pricingDetails != null) _buildPricingSummary(),

              const SizedBox(height: 16),

              // Months selector for monthly leases
              if (widget.property.rentalType == PropertyRentalType.monthly)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Text(
                        'Lease Length',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              if (_months > 1) _setMonths(_months - 1);
                            },
                            tooltip: 'Decrease months',
                          ),
                          Text('$_months month${_months == 1 ? '' : 's'}'),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _setMonths(_months + 1),
                            tooltip: 'Increase months',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Note: Date selection is handled via the calendar above
            ],
          ),
        ),

        // Inline validation error (dates not available)
        if (_validationError != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _validationError!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red[700],
                        ),
                  ),
                ),
              ],
            ),
          ),

        // Additional info and minimum stay requirements
        const SizedBox(height: 12),
        if (widget.property.rentalType == PropertyRentalType.monthly)
          _buildMinimumStayInfo()
        else if (widget.property.minimumStayDays != null)
          Text(
            'Minimum stay: ${widget.property.minimumStayDays} days',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
      ],
    );
  }

  Widget _buildDateDisplay(String label, DateTime date, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                date.toDisplayDate(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSummary() {
  final details = _pricingDetails!;

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
    ),
    child: Column(
      children: [
        if (details.containsKey('unitCount') && details.containsKey('unitLabel'))
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${details['unitCount']} ${details['unitLabel']}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              details['isMonthly'] == true ? 'Monthly Price' : 'Total Price',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              '\$${details['total'].toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
          ],
        ),
        if (details['isMonthly'] == true) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'No upfront payment. Send a request to the landlord for approval.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
        ],
      ],
    ),
  );
}

  Widget _buildMinimumStayInfo() {
    final minimumStayDays = widget.property.minimumStayDays ?? 30;
    final minimumStayMonths = (minimumStayDays / 30).ceil();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Lease Requirements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.amber[600], size: 16),
              const SizedBox(width: 8),
              Text(
                'Minimum lease period: ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                minimumStayMonths == 1
                    ? '1 month ($minimumStayDays days)'
                    : '$minimumStayMonths months ($minimumStayDays days)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[700],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.extension, color: Colors.amber[600], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  children: [
                    Text(
                      'After minimum period: ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      'Month-to-month or extend',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Note: The dates shown represent your initial lease commitment period. You can extend or go month-to-month after the minimum period.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}
