// lib/feature/property_detail/widgets/property_availability/property_availability_section.dart
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/feature/property_detail/widgets/property_availability/property_date_picker.dart';

class PropertyAvailabilitySection extends StatefulWidget {
  final Property property;

  const PropertyAvailabilitySection({
    super.key,
    required this.property,
  });

  @override
  State<PropertyAvailabilitySection> createState() => _PropertyAvailabilitySectionState();
}

class _PropertyAvailabilitySectionState extends State<PropertyAvailabilitySection> {
  bool _isDailyRental = true; // Toggle between daily and monthly rental

  @override
  Widget build(BuildContext context) {
    // Mock availability data - in a real app, this would come from your backend
    final Map<DateTime, bool> availability = {
      for (var i = 0; i < 60; i++)
        DateTime.now().add(Duration(days: i)):
            i % 7 != 5 && i % 7 != 6, // Weekends unavailable
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Availability',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            // Rental type toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggleButton(
                    context, 
                    'Daily', 
                    _isDailyRental, 
                    () => setState(() => _isDailyRental = true)
                  ),
                  _buildToggleButton(
                    context, 
                    'Monthly', 
                    !_isDailyRental, 
                    () => setState(() => _isDailyRental = false)
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Date range display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildDateSelector(
                      context,
                      _isDailyRental ? 'Check-in' : 'Start month',
                      DateTime.now().add(const Duration(days: 1)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateSelector(
                      context,
                      _isDailyRental ? 'Check-out' : 'End month',
                      DateTime.now().add(Duration(days: _isDailyRental ? 5 : 30)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PropertyDatePicker(
                initialStartDate: DateTime.now().add(const Duration(days: 1)),
                initialEndDate: DateTime.now().add(Duration(days: _isDailyRental ? 5 : 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                availability: availability,
                onDateRangeSelected: (start, end) {
                  // Handle date selection
                  print('Selected: $start to $end');
                },
                onInvalidSelection: (start, end) {
                  // Handle invalid selection
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Some dates in this range are not available'),
                    ),
                  );
                },
                pricePerNight: widget.property.price,
                isDailyRental: _isDailyRental,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(BuildContext context, String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade700,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context, String label, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                _isDailyRental 
                  ? '${date.day}/${date.month}/${date.year}'
                  : '${_getMonthName(date.month)} ${date.year}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}