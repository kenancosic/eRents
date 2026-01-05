// lib/features/profile/widgets/stripe_connect_not_linked.dart

import 'package:flutter/material.dart';

/// Widget displayed when landlord's Stripe account is not connected
class StripeConnectNotLinked extends StatelessWidget {
  final VoidCallback onConnect;
  final bool isLoading;

  const StripeConnectNotLinked({
    super.key,
    required this.onConnect,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, color: Colors.orange.shade700, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connect Your Bank Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Receive rental payments directly to your bank',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.orange.shade200),
          const SizedBox(height: 16),
          const Text(
            'To receive payments from tenants, you need to connect your bank account via Stripe.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          _buildBenefit(Icons.check_circle, 'Secure identity verification'),
          const SizedBox(height: 6),
          _buildBenefit(Icons.check_circle, 'Automatic payouts'),
          const SizedBox(height: 6),
          _buildBenefit(Icons.check_circle, 'Real-time payment tracking'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onConnect,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.link),
              label: Text(isLoading ? 'Connecting...' : 'Connect Stripe Account'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 16),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
