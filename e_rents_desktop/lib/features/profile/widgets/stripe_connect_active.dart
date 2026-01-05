// lib/features/profile/widgets/stripe_connect_active.dart

import 'package:flutter/material.dart';
import 'package:e_rents_desktop/features/profile/models/connect_account_status.dart';

/// Widget displayed when landlord's Stripe account is active and operational
class StripeConnectActive extends StatelessWidget {
  final ConnectAccountStatus status;
  final VoidCallback onViewDashboard;
  final VoidCallback onDisconnect;
  final bool isLoading;

  const StripeConnectActive({
    super.key,
    required this.status,
    required this.onViewDashboard,
    required this.onDisconnect,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stripe Account Active',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status.statusMessage ?? 'Ready to receive payments',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.green.shade200),
          const SizedBox(height: 16),
          _buildStatusRow(
            'Account ID',
            status.accountId ?? 'N/A',
            Colors.grey.shade700,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            'Payouts',
            status.payoutsEnabled ? 'Enabled ✓' : 'Disabled',
            status.payoutsEnabled ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            'Charges',
            status.chargesEnabled ? 'Enabled ✓' : 'Disabled',
            status.chargesEnabled ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onViewDashboard,
                  icon: const Icon(Icons.dashboard),
                  label: const Text('View Dashboard'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onDisconnect,
                  icon: const Icon(Icons.link_off),
                  label: const Text('Disconnect'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
