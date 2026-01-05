// lib/features/checkout/widgets/payment_error_card.dart

import 'package:flutter/material.dart';

/// Card component to display payment errors with actionable guidance
class PaymentErrorCard extends StatelessWidget {
  final String message;
  final String? errorCode;
  final VoidCallback? onRetry;
  final VoidCallback? onChangeCard;
  final VoidCallback? onContactBank;

  const PaymentErrorCard({
    super.key,
    required this.message,
    this.errorCode,
    this.onRetry,
    this.onChangeCard,
    this.onContactBank,
  });

  /// Factory for card declined error
  factory PaymentErrorCard.cardDeclined({
    Key? key,
    required VoidCallback onRetry,
  }) {
    return PaymentErrorCard(
      key: key,
      message: 'Your card was declined. Try another card or contact your bank.',
      errorCode: 'card_declined',
      onRetry: onRetry,
    );
  }

  /// Factory for insufficient funds error
  factory PaymentErrorCard.insufficientFunds({
    Key? key,
    required VoidCallback onChangeCard,
  }) {
    return PaymentErrorCard(
      key: key,
      message: 'Insufficient funds. Please use a different card.',
      errorCode: 'insufficient_funds',
      onChangeCard: onChangeCard,
    );
  }

  /// Factory for expired card error
  factory PaymentErrorCard.expiredCard({
    Key? key,
    required VoidCallback onChangeCard,
  }) {
    return PaymentErrorCard(
      key: key,
      message: 'Your card has expired. Please use a different card.',
      errorCode: 'expired_card',
      onChangeCard: onChangeCard,
    );
  }

  /// Factory for network error
  factory PaymentErrorCard.networkError({
    Key? key,
    required VoidCallback onRetry,
  }) {
    return PaymentErrorCard(
      key: key,
      message: 'Connection lost. Please check your internet and try again.',
      errorCode: 'network_error',
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade700,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Payment Failed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          // Error message
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // Common reasons
          if (_shouldShowCommonReasons()) ...[
            const Text(
              'Common reasons:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildCommonReasons(),
            const SizedBox(height: 16),
          ],
          // Action buttons
          Row(
            children: [
              if (onRetry != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRetry,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Try Again'),
                  ),
                ),
              if (onChangeCard != null) ...[
                if (onRetry != null) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onChangeCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Change Card'),
                  ),
                ),
              ],
              if (onContactBank != null) ...[
                if (onRetry != null || onChangeCard != null)
                  const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onContactBank,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Contact Bank'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  bool _shouldShowCommonReasons() {
    return errorCode == 'card_declined';
  }

  List<Widget> _buildCommonReasons() {
    return [
      _buildReasonItem('Insufficient funds'),
      _buildReasonItem('Incorrect card details'),
      _buildReasonItem('Card expired'),
    ];
  }

  Widget _buildReasonItem(String reason) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 6,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            reason,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
