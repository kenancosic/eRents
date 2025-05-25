import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/services/property_availability_service.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/feature/profile/user_bookings_provider.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:go_router/go_router.dart';

class BookingAvailabilityWidget extends StatefulWidget {
  final Property property;

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
  Map<DateTime, bool> _availability = {};
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _pricingDetails;

  @override
  void initState() {
    super.initState();
    _initializeDates();
    _loadAvailability();
  }

  void _initializeDates() {
    // Set appropriate default dates based on property type
    if (widget.property.rentalType == PropertyRentalType.daily) {
      _endDate = _startDate.add(const Duration(days: 7)); // 1 week default
    } else {
      _endDate = _startDate.add(const Duration(days: 30)); // 1 month default
    }
    _calculatePricing();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final availabilityService =
          PropertyAvailabilityService(context.read<ApiService>());

      final bookingsProvider = context.read<UserBookingsProvider>();
      final existingBookings = [
        ...bookingsProvider.upcomingBookings,
        ...bookingsProvider.completedBookings,
        ...bookingsProvider.cancelledBookings,
      ];

      final availability = await availabilityService.getPropertyAvailability(
        widget.property.propertyId,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 90)),
        existingBookings: existingBookings,
      );

      setState(() {
        _availability = availability;
        _isLoading = false;
      });

      _validateCurrentSelection();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load availability';
        _isLoading = false;
      });
    }
  }

  void _calculatePricing() {
    final availabilityService =
        PropertyAvailabilityService(context.read<ApiService>());

    final pricing = availabilityService.calculatePricing(
      property: widget.property,
      startDate: _startDate,
      endDate: _endDate,
      isDailyRental: widget.property.rentalType == PropertyRentalType.daily,
    );

    setState(() {
      _pricingDetails = pricing;
    });
  }

  void _validateCurrentSelection() {
    final availabilityService =
        PropertyAvailabilityService(context.read<ApiService>());

    final isAvailable = availabilityService.isDateRangeAvailable(
      _availability,
      _startDate,
      _endDate,
    );

    if (!isAvailable) {
      final nextAvailable = availabilityService.getNextAvailableDate(
        _availability,
        DateTime.now().add(const Duration(days: 1)),
      );

      if (nextAvailable != null) {
        setState(() {
          _startDate = nextAvailable;
          if (widget.property.rentalType == PropertyRentalType.daily) {
            _endDate = _startDate.add(const Duration(days: 7));
          } else {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        });
        _calculatePricing();
      }
    }
  }

  Future<void> _selectDates() async {
    if (widget.property.rentalType == PropertyRentalType.daily) {
      await _selectDailyDateRange();
    } else {
      await _selectMonthlyDateRange();
    }
  }

  Future<void> _selectDailyDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      final availabilityService =
          PropertyAvailabilityService(context.read<ApiService>());

      final isAvailable = availabilityService.isDateRangeAvailable(
        _availability,
        picked.start,
        picked.end,
      );

      if (isAvailable) {
        setState(() {
          _startDate = picked.start;
          _endDate = picked.end;
        });
        _calculatePricing();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Some dates in this range are not available'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _selectMonthlyDateRange() async {
    final DateTime? pickedStart = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

    if (pickedStart != null) {
      // For monthly rentals, set end date to at least minimum stay
      final minimumStay = widget.property.minimumStayDays ?? 30;
      final suggestedEnd = pickedStart.add(Duration(days: minimumStay));

      setState(() {
        _startDate = pickedStart;
        _endDate = suggestedEnd;
      });
      _calculatePricing();
    }
  }

  void _proceedToCheckout() {
    final isDailyRental =
        widget.property.rentalType == PropertyRentalType.daily;

    context.push('/checkout', extra: {
      'property': widget.property,
      'startDate': _startDate,
      'endDate': _endDate,
      'isDailyRental': isDailyRental,
      'totalPrice': _pricingDetails?['total'] ?? 0.0,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_errorMessage!),
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
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Book Your Stay',
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

        // Date selection
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
                      'Check-in',
                      _startDate,
                      Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateDisplay(
                      'Check-out',
                      _endDate,
                      Icons.event,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pricing summary
              if (_pricingDetails != null) _buildPricingSummary(),

              const SizedBox(height: 16),

              // Action buttons
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  CustomOutlinedButton(
                    label: 'Change Dates',
                    icon: Icons.edit_calendar,
                    onPressed: _selectDates,
                    isLoading: false,
                    width: OutlinedButtonWidth.flexible,
                    size: OutlinedButtonSize.compact,
                  ),
                  const SizedBox(width: 12),
                  CustomButton(
                    label: 'Book Now',
                    icon: Icons.check,
                    onPressed: _proceedToCheckout,
                    isLoading: false,
                    width: ButtonWidth.flexible,
                    size: ButtonSize.compact,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Additional info
        const SizedBox(height: 12),
        if (widget.property.minimumStayDays != null)
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
                '${date.day}/${date.month}/${date.year}',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${details['baseRate'].toStringAsFixed(0)} × ${details['unitCount']} ${details['unitLabel']}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '\$${details['subtotal'].toStringAsFixed(0)}',
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
                '\$${details['serviceFee'].toStringAsFixed(0)}',
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
                '\$${details['total'].toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
