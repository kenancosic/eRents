import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:e_rents_mobile/core/models/lease_extension_request.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/services/lease_service.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/feature/profile/providers/user_detail_provider.dart';

class ManageLeaseScreen extends StatefulWidget {
  final int propertyId;
  final int bookingId;
  final Booking booking;

  const ManageLeaseScreen({
    super.key,
    required this.propertyId,
    required this.bookingId,
    required this.booking,
  });

  @override
  State<ManageLeaseScreen> createState() => _ManageLeaseScreenState();
}

class _ManageLeaseScreenState extends State<ManageLeaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  bool _isSubmitting = false;
  bool _isIndefiniteExtension = true;
  DateTime? _newEndDate;
  DateTime? _newMinimumStayEndDate;

  @override
  void initState() {
    super.initState();
    // Set default minimum stay extension to 90 days from current minimum stay end date
    if (widget.booking.minimumStayEndDate != null) {
      _newMinimumStayEndDate =
          widget.booking.minimumStayEndDate!.add(const Duration(days: 90));
    } else {
      _newMinimumStayEndDate = DateTime.now().add(const Duration(days: 90));
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isEndDate) async {
    final DateTime initialDate = isEndDate
        ? (_newEndDate ?? DateTime.now().add(const Duration(days: 30)))
        : (_newMinimumStayEndDate ??
            DateTime.now().add(const Duration(days: 30)));

    final DateTime firstDate = DateTime.now();
    final DateTime lastDate = DateTime.now().add(const Duration(days: 365 * 2));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
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
      setState(() {
        if (isEndDate) {
          _newEndDate = picked;
        } else {
          _newMinimumStayEndDate = picked;
        }
      });
    }
  }

  Future<void> _submitExtensionRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = LeaseExtensionRequest(
        bookingId: widget.bookingId,
        propertyId: widget.propertyId,
        tenantId: context.read<UserDetailProvider>().item?.userId ?? 1,
        newEndDate: _isIndefiniteExtension ? null : _newEndDate,
        newMinimumStayEndDate: _newMinimumStayEndDate,
        reason: _reasonController.text.trim(),
        dateRequested: DateTime.now(),
      );

      final leaseService = LeaseService(context.read<ApiService>());
      final success = await leaseService.requestLeaseExtension(request);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Lease extension request submitted successfully! Your landlord will review it shortly.'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit request. Please try again.'),
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

  void _showPreviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Preview'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPreviewRow('Extension Type',
                  _isIndefiniteExtension ? 'Indefinite' : 'Fixed-term'),
              if (!_isIndefiniteExtension && _newEndDate != null)
                _buildPreviewRow(
                    'New End Date', DateFormat.yMMMd().format(_newEndDate!)),
              if (_newMinimumStayEndDate != null)
                _buildPreviewRow('Minimum Stay Until',
                    DateFormat.yMMMd().format(_newMinimumStayEndDate!)),
              _buildPreviewRow('Reason', _reasonController.text.trim()),
            ],
          ),
        ),
        actions: [
          CustomOutlinedButton.compact(
            label: 'Edit',
            isLoading: false,
            onPressed: () => Navigator.of(context).pop(),
          ),
          CustomButton.compact(
            label: 'Looks Good',
            isLoading: false,
            onPressed: () {
              Navigator.of(context).pop();
              _submitExtensionRequest();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
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
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      appBar: CustomAppBar(
        title: 'Manage Lease',
        showBackButton: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Current lease info
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
                    'Current Lease Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Start Date',
                      DateFormat.yMMMd().format(widget.booking.startDate)),
                  _buildInfoRow(
                      'Current End Date',
                      widget.booking.endDate != null
                          ? DateFormat.yMMMd().format(widget.booking.endDate!)
                          : 'Indefinite (no end date)'),
                  if (widget.booking.minimumStayEndDate != null)
                    _buildInfoRow(
                        'Minimum Stay Until',
                        DateFormat.yMMMd()
                            .format(widget.booking.minimumStayEndDate!)),
                  _buildInfoRow('Monthly Rent',
                      '\$${widget.booking.totalPrice.toStringAsFixed(0)}'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Extension type selection
            const Text(
              'Extension Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            RadioListTile<bool>(
              title: const Text('Indefinite Extension (No end date)'),
              subtitle:
                  const Text('Continue living here without a fixed end date'),
              value: true,
              groupValue: _isIndefiniteExtension,
              onChanged: (value) {
                setState(() {
                  _isIndefiniteExtension = value!;
                  if (_isIndefiniteExtension) {
                    _newEndDate = null;
                  }
                });
              },
            ),
            RadioListTile<bool>(
              title: const Text('Fixed-term Extension'),
              subtitle: const Text('Extend to a specific date'),
              value: false,
              groupValue: _isIndefiniteExtension,
              onChanged: (value) {
                setState(() {
                  _isIndefiniteExtension = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // New end date (if fixed-term)
            if (!_isIndefiniteExtension) ...[
              const Text(
                'New End Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(context, true),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        _newEndDate != null
                            ? DateFormat.yMMMd().format(_newEndDate!)
                            : 'Select new end date',
                        style: TextStyle(
                          color:
                              _newEndDate != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // New minimum stay date
            const Text(
              'New Minimum Stay Until',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectDate(context, false),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text(
                      _newMinimumStayEndDate != null
                          ? DateFormat.yMMMd().format(_newMinimumStayEndDate!)
                          : 'Select minimum stay date',
                      style: TextStyle(
                        color: _newMinimumStayEndDate != null
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This is the minimum period you commit to staying (typically 90 days).',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            // Reason field
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Extension *',
                hintText:
                    'Please explain why you would like to extend your lease...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please provide a reason for the extension';
                }
                if (value.trim().length < 20) {
                  return 'Please provide more details (at least 20 characters)';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Important notes
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Important Notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Your landlord will review this request and respond within 7 business days\n'
                    '• Current rent amount and terms will remain the same unless otherwise negotiated\n'
                    '• You can withdraw this request at any time before it\'s approved\n'
                    '• If approved, the new lease terms will take effect immediately',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: CustomOutlinedButton(
                    label: 'Preview Request',
                    icon: Icons.preview,
                    isLoading: false,
                    width: OutlinedButtonWidth.expanded,
                    onPressed: _showPreviewDialog,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    icon: Icons.send,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? () {} : _submitExtensionRequest,
                    width: ButtonWidth.expanded,
                    label: Text(
                      _isSubmitting ? 'Submitting...' : 'Submit Request',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
}
