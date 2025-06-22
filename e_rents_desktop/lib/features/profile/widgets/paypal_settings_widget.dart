import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/profile/state/paypal_settings_form_state.dart';
import 'package:go_router/go_router.dart';

class PaypalSettingsWidget extends StatelessWidget {
  final bool isEditing;

  const PaypalSettingsWidget({super.key, required this.isEditing});

  @override
  Widget build(BuildContext context) {
    return Consumer<PaypalSettingsFormState>(
      builder: (context, state, child) {
        return Form(
          key: state.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      state.isPaypalLinked
                          ? Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withOpacity(0.3)
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        state.isPaypalLinked
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
                      state.isPaypalLinked
                          ? Icons.check_circle
                          : Icons.account_balance_wallet,
                      color:
                          state.isPaypalLinked
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
                            state.isPaypalLinked
                                ? 'PayPal Linked'
                                : 'PayPal Not Linked',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color:
                                  state.isPaypalLinked
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (state.isPaypalLinked &&
                              state.paypalIdentifier != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              state.paypalIdentifier!,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                          if (!state.isPaypalLinked) ...[
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
              if (state.isLinking || state.isUnlinking)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (!state.isLinking && !state.isUnlinking && isEditing) ...[
                const SizedBox(height: 16),
                if (!state.isPaypalLinked) ...[
                  TextFormField(
                    controller: state.paypalEmailController,
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (state.isPaypalLinked) {
                        _showUnlinkDialog(context, state);
                      } else {
                        state.linkPaypalAccount();
                      }
                    },
                    icon: Icon(
                      state.isPaypalLinked ? Icons.link_off : Icons.link,
                      size: 18,
                    ),
                    label: Text(
                      state.isPaypalLinked
                          ? 'Unlink PayPal Account'
                          : 'Link PayPal Account',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor:
                          state.isPaypalLinked
                              ? Theme.of(context).colorScheme.errorContainer
                              : Theme.of(context).colorScheme.primary,
                      foregroundColor:
                          state.isPaypalLinked
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

  void _showUnlinkDialog(BuildContext context, PaypalSettingsFormState state) {
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
                state.unlinkPaypalAccount();
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
