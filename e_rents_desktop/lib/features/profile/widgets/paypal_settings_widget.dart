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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'PayPal Account',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (provider.state == ViewState.Busy &&
                    (provider.items.isEmpty ||
                        provider.items.first.id ==
                            user?.id)) // Heuristic to check if this specific action is busy
                  const Center(child: CircularProgressIndicator()),
                if (provider.state != ViewState.Busy) ...[
                  // Display PayPal Email Input if in edit mode and not linked
                  if (widget.isEditing && !isPaypalLinked) ...[
                    TextFormField(
                      controller: _paypalEmailController,
                      decoration: const InputDecoration(
                        labelText: 'PayPal Email',
                        hintText: 'Enter your PayPal email address',
                        border: OutlineInputBorder(),
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

                  // Status and Action Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isPaypalLinked
                              ? 'Status: Linked (${paypalIdentifier ?? 'N/A'})'
                              : 'Status: Not Linked',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (widget.isEditing)
                        ElevatedButton(
                          onPressed: () {
                            if (isPaypalLinked) {
                              // Unlink action (dialog)
                              showDialog(
                                context: context,
                                builder: (BuildContext dialogContext) {
                                  return AlertDialog(
                                    title: const Text('Unlink PayPal Account?'),
                                    content: const Text(
                                      'Are you sure you want to unlink your PayPal account?',
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        child: const Text('Cancel'),
                                        onPressed: () {
                                          dialogContext.pop();
                                        },
                                      ),
                                      TextButton(
                                        child: const Text('Unlink'),
                                        onPressed: () {
                                          dialogContext.pop();
                                          provider.unlinkPaypalAccount();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else {
                              // Link action
                              if (_formKey.currentState!.validate()) {
                                provider.linkPaypalAccount(
                                  _paypalEmailController.text.trim(),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isPaypalLinked
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.primary,
                          ),
                          child: Text(
                            isPaypalLinked
                                ? 'Unlink PayPal'
                                : 'Link PayPal Account',
                            style: TextStyle(
                              color:
                                  isPaypalLinked
                                      ? Theme.of(context).colorScheme.onError
                                      : Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (widget.isEditing) // Explanatory text based on link status
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        isPaypalLinked
                            ? 'Your PayPal account (${paypalIdentifier ?? '-'}) is linked.'
                            : 'Link your PayPal account to easily handle transactions.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
