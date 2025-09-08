import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/features/profile/providers/user_profile_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PaypalSettingsWidget extends StatelessWidget {
  final bool isEditing;

  const PaypalSettingsWidget({super.key, required this.isEditing});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, profileProvider, child) {
        final user = profileProvider.currentUser;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final isBusy = profileProvider.isLoading;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: user.isPaypalLinked == true
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: user.isPaypalLinked == true
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    user.isPaypalLinked == true
                        ? Icons.check_circle
                        : Icons.account_balance_wallet,
                    color: user.isPaypalLinked == true
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.isPaypalLinked == true
                              ? 'PayPal Linked'
                              : 'PayPal Not Linked',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: user.isPaypalLinked == true
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (user.isPaypalLinked == true &&
                            user.paypalUserIdentifier != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            user.paypalUserIdentifier!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                        if (user.isPaypalLinked != true) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Link your PayPal account for secure transactions',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isBusy
                      ? null
                      : user.isPaypalLinked == true
                          ? () => _showUnlinkDialog(context, profileProvider)
                          : () => _startLink(context, profileProvider),
                  icon: Icon(
                    user.isPaypalLinked == true ? Icons.link_off : Icons.link,
                    size: 18,
                  ),
                  label: Text(
                    isBusy
                        ? 'Please wait...'
                        : user.isPaypalLinked == true
                            ? 'Unlink PayPal Account'
                            : 'Link PayPal Account',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: user.isPaypalLinked == true
                        ? Theme.of(context).colorScheme.errorContainer
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: user.isPaypalLinked == true
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

  void _showUnlinkDialog(BuildContext context, UserProfileProvider profileProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Unlink PayPal Account'),
          content: const Text(
            'Are you sure you want to unlink your PayPal account?',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Unlink'),
              onPressed: () async {
                final success = await profileProvider.unlinkPaypal();
                if (success && dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PayPal account unlinked'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _startLink(BuildContext context, UserProfileProvider profileProvider) async {
    final approvalUrl = await profileProvider.startPayPalLinking();
    
    if (approvalUrl != null && context.mounted) {
      final uri = Uri.parse(approvalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open PayPal to complete linking.')),
          );
        }
      }
    } else if (context.mounted) {
      if (profileProvider.error != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(profileProvider.error!.message)),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to start PayPal linking.')),
          );
        }
      }
    }
  }
}
