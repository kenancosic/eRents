import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/core/models/property_detail.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:e_rents_mobile/features/property_detail/widgets/extend_booking_dialog.dart';
import 'package:e_rents_mobile/features/property_detail/providers/property_rental_provider.dart';

/// Section shown when user has an active lease (currently residing)
/// Shows lease management options for long-term tenants
class ActiveLeaseSection extends StatelessWidget {
  final PropertyDetail property;
  final Booking booking;

  const ActiveLeaseSection({
    super.key,
    required this.property,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final isMinimumStayApproaching = _isMinimumStayApproaching();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider
        const Divider(color: Color(0xFFE0E0E0), height: 16),
        const SizedBox(height: 16),

        // Active lease info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withValues(alpha: 0.1),
                Colors.green.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.home, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Your Current Residence',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                  'Move-in Date', DateFormat.yMMMd().format(booking.startDate)),
              if (booking.endDate != null)
                _buildInfoRow(
                    'Lease Ends', DateFormat.yMMMd().format(booking.endDate!))
              else
                _buildInfoRow('Lease Type', 'Open-ended (no fixed end date)'),
              _buildInfoRow(
                  'Monthly Rent', '\$${booking.totalPrice.toStringAsFixed(0)}'),
              if (booking.minimumStayEndDate != null) ...[
                _buildInfoRow('Minimum Stay Until',
                    DateFormat.yMMMd().format(booking.minimumStayEndDate!)),
                if (isMinimumStayApproaching)
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
                        Icon(Icons.warning_amber,
                            color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your minimum stay period is ending soon. Consider requesting an extension.',
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
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Primary actions for active lease
        Column(
          children: [
            // Report maintenance issues
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                label: 'Report Maintenance Issue',
                icon: Icons.build,
                onPressed: () => _reportMaintenanceIssue(context),
                isLoading: false,
                width: ButtonWidth.expanded,
              ),
            ),
            const SizedBox(height: 12),

            // Secondary actions row
            Row(
              children: [
                // Extension request - only for subscription-based bookings with end date
                if (_canRequestExtension())
                  Expanded(
                    child: CustomOutlinedButton(
                      label: 'Request Lease Extension',
                      icon: Icons.add_alarm,
                      onPressed: () => _requestLeaseExtension(context),
                      isLoading: false,
                      width: OutlinedButtonWidth.expanded,
                    ),
                  ),
                if (_canRequestExtension())
                  const SizedBox(width: 12),

                // Contact landlord
                Expanded(
                  child: CustomOutlinedButton(
                    label: 'Contact Landlord',
                    icon: Icons.message,
                    onPressed: () => _contactLandlord(context),
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

  /// Check if the booking is eligible for extension requests.
  /// Only subscription-based bookings with an end date can request extensions.
  bool _canRequestExtension() {
    // Must be a subscription-based monthly booking
    if (!booking.isSubscription) {
      return false;
    }
    // Must have an end date to extend (open-ended leases don't need extension)
    if (booking.endDate == null) {
      return false;
    }
    return true;
  }

  bool _isMinimumStayApproaching() {
    if (booking.minimumStayEndDate == null) return false;

    final now = DateTime.now();
    final daysUntilEnd = booking.minimumStayEndDate!.difference(now).inDays;

    // Show warning if minimum stay ends within 30 days
    return daysUntilEnd <= 30 && daysUntilEnd >= 0;
  }

  void _reportMaintenanceIssue(BuildContext context) {
    context.push(
      '/property/${property.propertyId}/report-issue',
      extra: {
        'propertyId': property.propertyId,
        'bookingId': booking.bookingId,
      },
    );
  }

  void _requestLeaseExtension(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => ExtendBookingDialog(
        booking: booking,
        onExtended: () {
          // Refresh booking details after extension request
          context.read<PropertyRentalProvider>().getBookingDetails(booking.bookingId);
        },
      ),
    );
  }

  void _contactLandlord(BuildContext context) {
    // Use go() to switch to Chat tab properly instead of pushing onto current stack
    context.go('/chat');
  }
}
