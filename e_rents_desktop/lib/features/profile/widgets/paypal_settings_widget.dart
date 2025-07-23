import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/profile/providers/profile_provider.dart';

class PaypalSettingsWidget extends StatelessWidget {
  final bool isEditing;

  const PaypalSettingsWidget({super.key, required this.isEditing});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final user = profileProvider.currentUser;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    user.isPaypalLinked
                        ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.3)
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      user.isPaypalLinked
                          ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3)
                          : Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    user.isPaypalLinked
                        ? Icons.check_circle
                        : Icons.account_balance_wallet,
                    color:
                        user.isPaypalLinked
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.isPaypalLinked
                              ? 'PayPal Linked'
                              : 'PayPal Not Linked',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color:
                                user.isPaypalLinked
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (user.isPaypalLinked &&
                            user.paypalUserIdentifier != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            user.paypalUserIdentifier!,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                        if (!user.isPaypalLinked) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Link your PayPal account for secure transactions',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isEditing) ...[
              const SizedBox(height: 16),
              if (!user.isPaypalLinked) ...[
                const Text(
                  'PayPal account linking functionality will be available soon.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: user.isPaypalLinked ? () => _showUnlinkDialog(context) : null,
                  icon: Icon(
                    user.isPaypalLinked ? Icons.link_off : Icons.link,
                    size: 18,
                  ),
                  label: Text(
                    user.isPaypalLinked
                        ? 'Unlink PayPal Account'
                        : 'Link PayPal Account (Coming Soon)',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor:
                        user.isPaypalLinked
                            ? Theme.of(context).colorScheme.errorContainer
                            : Theme.of(context).colorScheme.primary,
                    foregroundColor:
                        user.isPaypalLinked
                            ? Theme.of(context).colorScheme.onErrorContainer
                            : Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showUnlinkDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Unlink PayPal Account'),
          content: const Text(
            'PayPal unlinking functionality will be available soon.',
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }
}
