import 'package:e_rents_mobile/core/models/property_detail.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/core/enums/property_enums.dart';
import 'package:e_rents_mobile/features/property_detail/providers/property_availability_provider.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_mobile/features/profile/providers/user_profile_provider.dart';

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
  String? _errorMessage;
  Map<String, dynamic>? _pricingDetails;
  int _months = 1; // For monthly leases

  @override
  void initState() {
    super.initState();
    _initializeDates();
    // Defer provider-driven state changes until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
    _calculatePricing();
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
      _errorMessage = null;
    });

    try {
      final availabilityProvider = context.read<PropertyDetailAvailabilityProvider>();
      
      // Fetch availability data for the property
      await availabilityProvider.fetchAvailabilityData(
        widget.property.propertyId,
        DateTime.now(),
        DateTime.now().add(const Duration(days: 90)),
      );

      // Convert availability data to map format for UI usage
      // Since Availability has startDate and endDate, we need to create entries for each day
      final availabilityMap = <DateTime, bool>{};
      for (var availability in availabilityProvider.availabilityData) {
        // Create entries for each day in the range
        DateTime currentDate = availability.startDate;
        while (currentDate.isBefore(availability.endDate) || currentDate.isAtSameMomentAs(availability.endDate)) {
          availabilityMap[currentDate] = availability.isAvailable;
          currentDate = currentDate.add(const Duration(days: 1));
        }
      }

      setState(() {
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
        };
      } else {
        // Monthly: charge a single monthly amount up-front via checkout
        pricing = {
          'unitCount': _months,
          'unitLabel': _months == 1 ? 'month' : 'months',
          'total': widget.property.price * _months,
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
    // We'll need to implement our own availability checking logic
    // For now, we'll skip this validation as the specialized provider handles
    // availability checking differently
    
    // TODO: Implement proper date range availability validation
    // This would require checking the availability data we fetched
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

    if (picked != null && mounted) {
      // For now, we'll assume the dates are available and let the backend validate
      // A more robust implementation would check the availability data we fetched
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _calculatePricing();
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
      // For monthly rentals, compute end date based on selected months (respect minimum stay)
      final minimumStayDays = widget.property.minimumStayDays ?? 30;
      final minMonths = (minimumStayDays / 30).ceil();
      if (_months < minMonths) {
        _months = minMonths;
      }
      setState(() {
        _startDate = pickedStart;
        _endDate = pickedStart.add(Duration(days: 30 * _months));
      });
      _calculatePricing();
    }
  }

  void _proceedToCheckout() {
    // Guard: owners cannot proceed to checkout on their own properties
    final userProvider = context.read<UserProfileProvider>();
    final currentUserId = userProvider.currentUser?.userId;
    final bool isOwner = currentUserId != null && currentUserId == widget.property.ownerId;
    if (isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Owners cannot book their own properties.')),
      );
      return;
    }
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
                    label:
                        widget.property.rentalType == PropertyRentalType.daily
                            ? 'Change Dates'
                            : 'Change Start Date',
                    icon: Icons.edit_calendar,
                    onPressed: isOwner ? () {} : () => _selectDates(),
                    isLoading: false,
                    width: OutlinedButtonWidth.flexible,
                    size: OutlinedButtonSize.compact,
                  ),
                  const SizedBox(width: 12),
                  CustomButton(
                    label:
                        widget.property.rentalType == PropertyRentalType.daily
                            ? 'Book Now'
                            : 'Apply for Lease',
                    icon: widget.property.rentalType == PropertyRentalType.daily
                        ? Icons.check
                        : Icons.home_work,
                    onPressed: isOwner ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Owners cannot perform this action on their own property.')),
                      );
                    } : _proceedToCheckout,
                    isLoading: false,
                    width: ButtonWidth.flexible,
                    size: ButtonSize.compact,
                  ),
                ],
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
              'Total Price',
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
