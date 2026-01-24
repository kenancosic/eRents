import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/features/property_detail/providers/property_rental_provider.dart';
import 'package:e_rents_mobile/core/utils/date_extensions.dart';

class ExtendBookingDialog extends StatefulWidget {
  final Booking booking;
  final VoidCallback? onExtended;
  /// If true, this is a monthly rental and only months selection is allowed
  final bool isMonthlyRental;

  const ExtendBookingDialog({
    super.key,
    required this.booking,
    this.onExtended,
    this.isMonthlyRental = true, // Monthly rentals use month-based extension by default
  });

  @override
  State<ExtendBookingDialog> createState() => _ExtendBookingDialogState();
}

class _ExtendBookingDialogState extends State<ExtendBookingDialog> {
  // For monthly rentals, default to months selection (not exact date)
  late bool _useExactDate;
  DateTime? _newEndDate;
  final TextEditingController _monthsCtrl = TextEditingController(text: '1');
  final TextEditingController _amountCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Monthly rentals should default to month selection, not exact date
    _useExactDate = !widget.isMonthlyRental;
  }

  @override
  void dispose() {
    _monthsCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isMonthlyRental ? 'Request Lease Extension' : 'Extend Booking'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // For monthly rentals, only show months selection (no exact date option)
          if (!widget.isMonthlyRental) ...[
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _useExactDate ? Icons.radio_button_checked : Icons.radio_button_off,
                color: _useExactDate ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
              title: const Text('Pick exact end date'),
              onTap: () => setState(() => _useExactDate = true),
            ),
            if (_useExactDate)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        _newEndDate != null
                            ? _formatDate(_newEndDate!)
                            : 'Select date',
                      ),
                      onPressed: () async {
                        final now = DateTime.now();
                        final initial = _newEndDate ?? (widget.booking.endDate ?? now);
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initial.isBefore(now) ? now : initial,
                          firstDate: now,
                          lastDate: DateTime(now.year + 5),
                        );
                        if (!mounted) return;
                        if (picked != null) {
                          setState(() => _newEndDate = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                !_useExactDate ? Icons.radio_button_checked : Icons.radio_button_off,
                color: !_useExactDate ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
              title: const Text('Extend by months'),
              onTap: () => setState(() => _useExactDate = false),
            ),
          ],
          // For monthly rentals OR when months option selected
          if (widget.isMonthlyRental || !_useExactDate) ...[
            if (widget.isMonthlyRental)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Select how many months to extend your lease:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _monthsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Number of months',
                      hintText: 'e.g. 3',
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'New monthly amount (optional)',
              prefixText: '',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: const Text('Extend'),
          onPressed: _isSubmitting ? null : _onSubmit,
        ),
      ],
    );
  }

  Future<void> _onSubmit() async {
    final provider = context.read<PropertyRentalProvider>();
    final bookingId = widget.booking.bookingId;

    DateTime? newEndDate;
    int? extendByMonths;
    double? newMonthlyAmount;

    if (_useExactDate) {
      if (_newEndDate == null) {
        _showSnack('Please select a new end date');
        return;
      }
      newEndDate = _newEndDate;
    } else {
      final months = int.tryParse(_monthsCtrl.text.trim());
      if (months == null || months <= 0) {
        _showSnack('Please enter a valid number of months');
        return;
      }
      extendByMonths = months;
    }

    if (_amountCtrl.text.trim().isNotEmpty) {
      final parsed = double.tryParse(_amountCtrl.text.trim());
      if (parsed == null || parsed <= 0) {
        _showSnack('Please enter a valid monthly amount');
        return;
      }
      newMonthlyAmount = parsed;
    }

    setState(() => _isSubmitting = true);
    final ok = await provider.extendBooking(
      bookingId: bookingId,
      newEndDate: newEndDate,
      extendByMonths: extendByMonths,
      newMonthlyAmount: newMonthlyAmount,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      widget.onExtended?.call();
      if (!mounted) return;
      Navigator.of(context).pop();
      // Show appropriate message based on rental type
      if (widget.isMonthlyRental) {
        _showSnack('Extension request submitted! Awaiting landlord approval.');
      } else {
        _showSnack('Booking extended successfully');
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  String _formatDate(DateTime d) => d.toApiDate();
}
