import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/profile/providers/profile_provider.dart';
import 'package:e_rents_desktop/base/base_provider.dart'; // For ViewState
import 'package:go_router/go_router.dart'; // Import GoRouter

class PaypalSettingsWidget extends StatefulWidget {
  final bool isEditing; // To control button visibility/activity

  const PaypalSettingsWidget({super.key, required this.isEditing});

  @override
  State<PaypalSettingsWidget> createState() => _PaypalSettingsWidgetState();
}

class _PaypalSettingsWidgetState extends State<PaypalSettingsWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _paypalEmailController = TextEditingController();

  @override
  void dispose() {
    _paypalEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        final user = provider.currentUser;
        final bool isPaypalLinked = user?.isPaypalLinked ?? false;
        final String? paypalIdentifier = user?.paypalUserIdentifier;

        // If already linked, and we are viewing (not editing), show the identifier in the controller
        // Or, if we just linked, this will update too.
        if (isPaypalLinked &&
            paypalIdentifier != null &&
            _paypalEmailController.text.isEmpty) {
          // _paypalEmailController.text = paypalIdentifier; // Optionally prefill if needed for some UX
        }

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isPaypalLinked
                          ? Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withOpacity(0.3)
                          : Theme.of(
                            context,
                          ).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isPaypalLinked
                            ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3)
                            : Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPaypalLinked
                          ? Icons.check_circle
                          : Icons.account_balance_wallet,
                      color:
                          isPaypalLinked
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPaypalLinked
                                ? 'PayPal Linked'
                                : 'PayPal Not Linked',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color:
                                  isPaypalLinked
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (isPaypalLinked && paypalIdentifier != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              paypalIdentifier,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                          if (!isPaypalLinked) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Link your PayPal account for secure transactions',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (provider.state == ViewState.Busy)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),

              if (provider.state != ViewState.Busy && widget.isEditing) ...[
                const SizedBox(height: 16),

                // Email Input (only show if not linked)
                if (!isPaypalLinked) ...[
                  TextFormField(
                    controller: _paypalEmailController,
                    decoration: InputDecoration(
                      labelText: 'PayPal Email',
                      hintText: 'Enter your PayPal email address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      prefixIcon: const Icon(Icons.email, size: 20),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your PayPal email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (isPaypalLinked) {
                        // Unlink action
                        _showUnlinkDialog(context, provider);
                      } else {
                        // Link action
                        _linkPaypalAccount(provider);
                      }
                    },
                    icon: Icon(
                      isPaypalLinked ? Icons.link_off : Icons.link,
                      size: 18,
                    ),
                    label: Text(
                      isPaypalLinked
                          ? 'Unlink PayPal Account'
                          : 'Link PayPal Account',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor:
                          isPaypalLinked
                              ? Theme.of(context).colorScheme.errorContainer
                              : Theme.of(context).colorScheme.primary,
                      foregroundColor:
                          isPaypalLinked
                              ? Theme.of(context).colorScheme.onErrorContainer
                              : Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _linkPaypalAccount(ProfileProvider provider) {
    if (_formKey.currentState!.validate()) {
      provider.linkPaypalAccount(_paypalEmailController.text.trim());
      _paypalEmailController.clear();
    }
  }

  void _showUnlinkDialog(BuildContext context, ProfileProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Unlink PayPal Account'),
          content: const Text(
            'Are you sure you want to unlink your PayPal account? This will remove your payment method.',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => dialogContext.pop(),
            ),
            TextButton(
              onPressed: () {
                dialogContext.pop();
                provider.unlinkPaypalAccount();
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Unlink'),
            ),
          ],
        );
      },
    );
  }
}
