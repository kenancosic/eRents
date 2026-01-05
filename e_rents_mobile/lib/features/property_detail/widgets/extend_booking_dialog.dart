import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/features/property_detail/providers/property_rental_provider.dart';
import 'package:e_rents_mobile/core/utils/date_extensions.dart';

class ExtendBookingDialog extends StatefulWidget {
  final Booking booking;
  final VoidCallback? onExtended;

  const ExtendBookingDialog({super.key, required this.booking, this.onExtended});

  @override
  State<ExtendBookingDialog> createState() => _ExtendBookingDialogState();
}

class _ExtendBookingDialogState extends State<ExtendBookingDialog> {
  bool _useExactDate = true;
  DateTime? _newEndDate;
  final TextEditingController _monthsCtrl = TextEditingController(text: '1');
  final TextEditingController _amountCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _monthsCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Extend Booking'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          if (!_useExactDate)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _monthsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Months',
                      hintText: 'e.g. 3',
                    ),
                  ),
                ),
              ],
            ),
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
      _showSnack('Booking extended successfully');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  String _formatDate(DateTime d) => d.toApiDate();
}
