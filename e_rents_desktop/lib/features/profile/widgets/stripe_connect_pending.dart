// lib/features/profile/widgets/stripe_connect_pending.dart

import 'package:flutter/material.dart';
import 'package:e_rents_desktop/features/profile/models/connect_account_status.dart';

/// Widget displayed when landlord's Stripe account setup is incomplete
class StripeConnectPending extends StatelessWidget {
  final ConnectAccountStatus status;
  final VoidCallback onCompleteSetup;
  final bool isLoading;

  const StripeConnectPending({
    super.key,
    required this.status,
    required this.onCompleteSetup,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pending, color: Colors.amber.shade700, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Setup Incomplete',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please complete your account setup to receive payments',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (status.currentlyDue != null && status.currentlyDue!.isNotEmpty) ...[
            Text(
              'Required information:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade900,
              ),
            ),
            const SizedBox(height: 8),
            ...status.currentlyDue!.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.chevron_right, size: 16),
                    const SizedBox(width: 4),
                    Text(_formatRequirement(item)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onCompleteSetup,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Icon(Icons.arrow_forward),
              label: Text(isLoading ? 'Loading...' : 'Complete Setup'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRequirement(String requirement) {
    // Convert snake_case to Title Case
    return requirement
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}
