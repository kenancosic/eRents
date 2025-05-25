import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';

/// Section shown when user has an upcoming booking
/// Shows booking details and management options
class UpcomingBookingSection extends StatelessWidget {
  final Property property;
  final Booking booking;

  const UpcomingBookingSection({
    super.key,
    required this.property,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider
        const Divider(color: Color(0xFFE0E0E0), height: 16),
        const SizedBox(height: 16),

        // Upcoming booking info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withValues(alpha: 0.1),
                Colors.blue.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event_available, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Your Upcoming Stay',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                  'Check-in', DateFormat.yMMMd().format(booking.startDate)),
              if (booking.endDate != null)
                _buildInfoRow(
                    'Check-out', DateFormat.yMMMd().format(booking.endDate!))
              else
                _buildInfoRow('Stay Type', 'Open-ended lease'),
              _buildInfoRow(
                  'Total Price', '\$${booking.totalPrice.toStringAsFixed(2)}'),
              if (booking.minimumStayEndDate != null)
                _buildInfoRow('Minimum Stay Until',
                    DateFormat.yMMMd().format(booking.minimumStayEndDate!)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: CustomOutlinedButton(
                label: 'Manage Booking',
                icon: Icons.edit_calendar,
                onPressed: () => _navigateToManageBooking(context),
                isLoading: false,
                width: OutlinedButtonWidth.expanded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                label: 'Contact Host',
                icon: Icons.message,
                onPressed: () => _contactHost(context),
                isLoading: false,
                width: ButtonWidth.expanded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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

  void _navigateToManageBooking(BuildContext context) {
    context.push(
      '/property/${property.propertyId}/manage-booking',
      extra: {
        'propertyId': property.propertyId,
        'bookingId': booking.bookingId,
        'booking': booking,
      },
    );
  }

  void _contactHost(BuildContext context) {
    // Navigate to chat with property owner
    context.push('/chat', extra: {
      'name': 'Property Owner', // This could come from property owner data
      'imageUrl': 'assets/images/user-image.png',
    });
  }
}
