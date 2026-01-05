// lib/features/checkout/widgets/payment_loading_modal.dart

import 'package:flutter/material.dart';

/// Modal shown during payment processing states
class PaymentLoadingModal extends StatelessWidget {
  final String message;
  final String? subtitle;

  const PaymentLoadingModal({
    super.key,
    required this.message,
    this.subtitle,
  });

  /// Show creating payment intent state
  static void showCreatingIntent(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PaymentLoadingModal(
        message: 'Preparing secure payment...',
      ),
    );
  }

  /// Show confirming payment state
  static void showConfirming(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PaymentLoadingModal(
        message: 'Confirming payment...',
        subtitle: 'Please wait',
      ),
    );
  }

  /// Show processing state
  static void showProcessing(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PaymentLoadingModal(
        message: 'Processing payment...',
        subtitle: 'This may take a few seconds',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated spinner
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7265F0)),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            // Main message
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            // Optional subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
