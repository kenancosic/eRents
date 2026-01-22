import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:e_rents_mobile/core/models/property_detail.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';

/// Section shown when user has an active short-term booking
/// Shows current stay details and extension options
class ActiveBookingSection extends StatelessWidget {
  final PropertyDetail property;
  final Booking booking;

  const ActiveBookingSection({
    super.key,
    required this.property,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final daysRemaining =
        booking.endDate?.difference(DateTime.now()).inDays ?? 0;
    final isEndingSoon = daysRemaining <= 3 && daysRemaining > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider
        const Divider(color: Color(0xFFE0E0E0), height: 16),
        const SizedBox(height: 16),

        // Current stay info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withValues(alpha: 0.1),
                Colors.purple.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.purple.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.purple[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Your Current Stay',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                  'Check-in', DateFormat.yMMMd().format(booking.startDate)),
              if (booking.endDate != null) ...[
                _buildInfoRow(
                    'Check-out', DateFormat.yMMMd().format(booking.endDate!)),
                _buildInfoRow('Days Remaining', '$daysRemaining days'),
                if (isEndingSoon)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule,
                            color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your stay is ending soon! Consider extending if you\'d like to stay longer.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              _buildInfoRow(
                  'Total Paid', '\$${booking.totalPrice.toStringAsFixed(2)}'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Primary actions for active booking
        Column(
          children: [
            // Extend stay button
            if (booking.endDate != null)
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: 'Extend Your Stay',
                  icon: Icons.add_box,
                  onPressed: () => _extendStay(context),
                  isLoading: false,
                  width: ButtonWidth.expanded,
                ),
              ),
            if (booking.endDate != null) const SizedBox(height: 12),

            // Secondary actions row
            Row(
              children: [
                Expanded(
                  child: CustomOutlinedButton(
                    label: 'Contact Host',
                    icon: Icons.message,
                    onPressed: () => _contactHost(context),
                    isLoading: false,
                    width: OutlinedButtonWidth.expanded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomOutlinedButton(
                    label: 'Report Issue',
                    icon: Icons.report_problem,
                    onPressed: () => _reportIssue(context),
                    isLoading: false,
                    width: OutlinedButtonWidth.expanded,
                  ),
                ),
              ],
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
            width: 120,
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

  void _extendStay(BuildContext context) {
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
    // Use go() to switch to Chat tab properly instead of pushing onto current stack
    context.go('/chat');
  }

  void _reportIssue(BuildContext context) {
    context.push(
      '/property/${property.propertyId}/report-issue',
      extra: {
        'propertyId': property.propertyId,
        'bookingId': booking.bookingId,
      },
    );
  }
}
