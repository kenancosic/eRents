import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/core/models/property_detail.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:e_rents_mobile/features/property_detail/widgets/cancel_stay_dialog.dart';
import 'package:e_rents_mobile/features/property_detail/providers/property_rental_provider.dart';

/// Section shown when user has a pending monthly lease application
/// awaiting landlord approval
class PendingApprovalSection extends StatelessWidget {
  final PropertyDetail property;
  final Booking booking;

  const PendingApprovalSection({
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

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.withValues(alpha: 0.15),
                Colors.orange.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with pending icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.hourglass_top_rounded,
                      color: Colors.orange[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lease Application Pending',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Awaiting landlord approval',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Application details
              _buildInfoRow(
                'Requested Start',
                DateFormat.yMMMd().format(booking.startDate),
              ),
              if (booking.endDate != null)
                _buildInfoRow(
                  'Requested End',
                  DateFormat.yMMMd().format(booking.endDate!),
                )
              else
                _buildInfoRow('Lease Type', 'Open-ended'),
              if (booking.totalPrice > 0)
                _buildInfoRow(
                  'Monthly Rent',
                  '\$${booking.totalPrice.toStringAsFixed(2)}/mo',
                ),
              _buildInfoRow(
                'Submitted',
                _formatSubmissionDate(booking.bookingDate),
              ),

              const SizedBox(height: 16),

              // Info message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'The property owner is reviewing your application. '
                        'You\'ll be notified once a decision is made. '
                        'No payment is required until approved.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Action buttons
        Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            CustomOutlinedButton(
              label: 'Contact Landlord',
              icon: Icons.chat_outlined,
              onPressed: () => _navigateToChat(context),
              isLoading: false,
              width: OutlinedButtonWidth.flexible,
              size: OutlinedButtonSize.compact,
            ),
            CustomOutlinedButton(
              label: 'Withdraw Application',
              icon: Icons.cancel_outlined,
              onPressed: () => _showCancelDialog(context),
              isLoading: false,
              width: OutlinedButtonWidth.flexible,
              size: OutlinedButtonSize.compact,
              textColor: Colors.red[600] ?? Colors.red,
              borderColor: Colors.red[300] ?? Colors.red,
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
            width: 130,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
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

  String _formatSubmissionDate(DateTime? date) {
    if (date == null) return 'Recently';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }
    return DateFormat.yMMMd().format(date);
  }

  void _navigateToChat(BuildContext context) {
    // Navigate to chat with the property owner
    context.push('/chat', extra: {
      'recipientId': property.ownerId,
      'propertyId': property.propertyId,
    });
  }

  void _showCancelDialog(BuildContext context) {
    // Capture the router before showing dialog to avoid context issues
    final router = GoRouter.of(context);
    final provider = context.read<PropertyRentalProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => CancelStayDialog(
        booking: booking,
        onCancellationConfirmed: () {
          // Refresh the bookings to get updated data
          provider.getBookingDetails(booking.bookingId);

          // Navigate back to home screen
          router.go('/');
        },
      ),
    );
  }
}
