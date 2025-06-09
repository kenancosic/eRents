import 'package:flutter/material.dart';
import '../../../models/booking.dart';
import '../../../repositories/booking_repository.dart';
import '../../../base/service_locator.dart';

/// Enhanced cancellation dialog for landlords with proper reason tracking
/// and refund calculation preview
class LandlordCancellationDialog extends StatefulWidget {
  final Booking booking;

  const LandlordCancellationDialog({super.key, required this.booking});

  @override
  State<LandlordCancellationDialog> createState() =>
      _LandlordCancellationDialogState();
}

class _LandlordCancellationDialogState
    extends State<LandlordCancellationDialog> {
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedReason;
  bool _isEmergency = false;
  bool _requestRefund = true;
  bool _isLoading = false;
  double? _estimatedRefund;

  final List<Map<String, String>> _cancellationReasons = [
    {
      'value': 'emergency',
      'label': 'Emergency Situation',
      'description': 'Urgent matters requiring immediate cancellation',
    },
    {
      'value': 'maintenance',
      'label': 'Maintenance Issues',
      'description': 'Property requires urgent repairs',
    },
    {
      'value': 'property damage',
      'label': 'Property Damage',
      'description': 'Damage preventing safe occupancy',
    },
    {
      'value': 'force majeure',
      'label': 'Force Majeure',
      'description': 'Natural disasters, government restrictions',
    },
    {
      'value': 'overbooking',
      'label': 'Overbooking',
      'description': 'Accidental double booking',
    },
    {
      'value': 'scheduling conflict',
      'label': 'Scheduling Conflict',
      'description': 'Unexpected scheduling issues',
    },
    {
      'value': 'health and safety concerns',
      'label': 'Health & Safety',
      'description': 'Safety concerns for guests',
    },
    {
      'value': 'legal issues',
      'label': 'Legal Issues',
      'description': 'Legal complications',
    },
  ];

  @override
  void initState() {
    super.initState();
    _calculateEstimatedRefund();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _calculateEstimatedRefund() async {
    try {
      final repository = getService<BookingRepository>();
      final refundAmount = await repository.calculateRefundAmount(
        widget.booking.bookingId,
        DateTime.now(),
      );
      setState(() {
        _estimatedRefund = refundAmount;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange, size: 24),
          const SizedBox(width: 8),
          const Text('Cancel Booking'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBookingInfo(),
              const SizedBox(height: 20),
              _buildReasonSelection(),
              const SizedBox(height: 16),
              _buildEmergencyToggle(),
              const SizedBox(height: 16),
              _buildAdditionalNotes(),
              const SizedBox(height: 16),
              _buildRefundSettings(),
              const SizedBox(height: 16),
              _buildRefundEstimate(),
              const SizedBox(height: 16),
              _buildWarningMessage(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Keep Booking'),
        ),
        ElevatedButton(
          onPressed:
              _isLoading || _selectedReason == null
                  ? null
                  : _handleCancellation,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Cancel Booking'),
        ),
      ],
    );
  }

  Widget _buildBookingInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.booking.propertyName ?? 'Unknown Property',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text('Booking #${widget.booking.bookingId}'),
          Text('Guest: ${widget.booking.userName ?? "Unknown"}'),
          Text('Check-in: ${widget.booking.formattedStartDate}'),
          Text('Total: ${widget.booking.formattedPrice}'),
        ],
      ),
    );
  }

  Widget _buildReasonSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cancellation Reason *',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedReason,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: InputBorder.none,
              hintText: 'Select a reason for cancellation',
            ),
            items:
                _cancellationReasons.map((reason) {
                  return DropdownMenuItem<String>(
                    value: reason['value'],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reason['label']!),
                        Text(
                          reason['description']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedReason = value;
                _isEmergency = [
                  'emergency',
                  'force majeure',
                  'health and safety concerns',
                ].contains(value);
              });
              _calculateEstimatedRefund();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyToggle() {
    return Row(
      children: [
        Checkbox(
          value: _isEmergency,
          onChanged: (value) {
            setState(() {
              _isEmergency = value ?? false;
            });
            _calculateEstimatedRefund();
          },
        ),
        const Text('This is an emergency cancellation'),
        Tooltip(
          message: 'Emergency cancellations may have different refund policies',
          child: Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Notes',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Provide additional details about the cancellation...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildRefundSettings() {
    return Row(
      children: [
        Checkbox(
          value: _requestRefund,
          onChanged: (value) {
            setState(() {
              _requestRefund = value ?? true;
            });
          },
        ),
        const Text('Process refund to guest'),
      ],
    );
  }

  Widget _buildRefundEstimate() {
    if (_estimatedRefund == null) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estimated Refund',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${_estimatedRefund!.toStringAsFixed(2)} BAM',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarningMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Landlord Cancellation Impact',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• Guest will be notified immediately\n'
                  '• This may affect your hosting rating\n'
                  '• Processing fees may apply to refunds\n'
                  '• Consider contacting guest before cancelling',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancellation() async {
    if (_selectedReason == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = getService<BookingRepository>();
      await repository.cancelBooking(
        widget.booking.bookingId,
        _selectedReason!,
        _requestRefund,
        additionalNotes:
            _notesController.text.isNotEmpty ? _notesController.text : null,
        isEmergency: _isEmergency,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking #${widget.booking.bookingId} cancelled successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
