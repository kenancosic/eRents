// lib/features/checkout/widgets/trust_signals.dart

import 'package:flutter/material.dart';

/// Widget that displays security and trust signals for payment processing
class TrustSignals extends StatelessWidget {
  const TrustSignals({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_user,
            color: Colors.green.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secured by Stripe',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your payment information is encrypted and secure',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Extended trust signals with more security features
class TrustSignalsDetailed extends StatelessWidget {
  const TrustSignalsDetailed({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user,
                color: Colors.green.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Secure Payment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSecurityItem(
            icon: Icons.lock,
            label: '256-bit encryption',
            color: Colors.green.shade700,
          ),
          const SizedBox(height: 8),
          _buildSecurityItem(
            icon: Icons.shield,
            label: 'PCI DSS compliant',
            color: Colors.green.shade700,
          ),
          const SizedBox(height: 8),
          _buildSecurityItem(
            icon: Icons.verified,
            label: '3D Secure authentication',
            color: Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}
