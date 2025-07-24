import 'package:e_rents_mobile/feature/property_detail/providers/property_detail_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:go_router/go_router.dart';

class CancelStayDialog extends StatefulWidget {
  final Booking booking;
  final VoidCallback onCancellationConfirmed;

  const CancelStayDialog({
    super.key,
    required this.booking,
    required this.onCancellationConfirmed,
  });

  @override
  State<CancelStayDialog> createState() => _CancelStayDialogState();
}

class _CancelStayDialogState extends State<CancelStayDialog> {
  final _reasonController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasAcceptedTerms = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _processCancellation() async {
    if (!_validateForm()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final propertyDetailProvider = context.read<PropertyDetailProvider>();
      final success = await propertyDetailProvider.cancelBooking(
        widget.booking.bookingId,
        _reasonController.text.trim(),
      );

      if (mounted) {
        if (success) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onCancellationConfirmed();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel booking. Please try again.'),
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
          _isSubmitting = false;
        });
      }
    }
  }

  bool _validateForm() {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please provide a reason for cancellation')),
      );
      return false;
    }

    if (_confirmationController.text.trim().toLowerCase() != 'cancel') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type "CANCEL" to confirm')),
      );
      return false;
    }

    if (!_hasAcceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the cancellation terms')),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red[600],
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Cancel Stay',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Warning message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ Important Warning',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You are about to cancel your stay. Please review the following:',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Booking details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Property', widget.booking.propertyName),
                    _buildDetailRow('Check-in',
                        DateFormat.yMMMd().format(widget.booking.startDate)),
                    _buildDetailRow(
                        'Check-out',
                        widget.booking.endDate != null
                            ? DateFormat.yMMMd().format(widget.booking.endDate!)
                            : 'Indefinite'),
                    _buildDetailRow('Total Paid',
                        '\$${widget.booking.totalPrice.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Cancellation policy
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cancellation Policy',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• No refunds will be issued for cancelled bookings\n'
                      '• This action cannot be undone\n'
                      '• You will lose access to the property immediately\n'
                      '• Any additional fees or deposits will not be refunded\n'
                      '• You are responsible for removing all personal belongings',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Reason for cancellation
              const Text(
                'Reason for Cancellation *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  hintText: 'Please explain why you want to cancel...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Confirmation field
              const Text(
                'Type "CANCEL" to confirm *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmationController,
                decoration: const InputDecoration(
                  hintText: 'Type CANCEL here',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),

              // Terms checkbox
              CheckboxListTile(
                value: _hasAcceptedTerms,
                onChanged: (value) {
                  setState(() {
                    _hasAcceptedTerms = value ?? false;
                  });
                },
                title: const Text(
                  'I understand that this cancellation is permanent and no refunds will be issued',
                  style: TextStyle(fontSize: 14),
                ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: CustomOutlinedButton(
                      label: 'Keep Booking',
                      isLoading: false,
                      width: OutlinedButtonWidth.expanded,
                      onPressed: _isSubmitting ? () {} : () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      label: _isSubmitting ? 'Cancelling...' : 'Cancel Stay',
                      isLoading: _isSubmitting,
                      width: ButtonWidth.expanded,
                      backgroundColor: Colors.red,
                      onPressed: _isSubmitting ? () {} : _processCancellation,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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
}
