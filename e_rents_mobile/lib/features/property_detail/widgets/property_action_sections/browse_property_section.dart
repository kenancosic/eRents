import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/features/property_detail/widgets/property_availability/booking_availability_widget.dart';

/// Section shown when a user is browsing a property (no existing booking)
/// Shows booking availability and allows new bookings
class BrowsePropertySection extends StatelessWidget {
  final Property property;

  const BrowsePropertySection({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider
        const Divider(color: Color(0xFFE0E0E0), height: 16),
        const SizedBox(height: 16),

        // Booking availability widget
        BookingAvailabilityWidget(property: property),
      ],
    );
  }
}
