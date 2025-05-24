import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:e_rents_mobile/feature/profile/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isAddingNew = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _addPayPalAccount() async {
    if (_formKey.currentState!.validate()) {
      final userProvider = context.read<UserProvider>();

      final paymentData = {
        'type': 'paypal',
        'email': _emailController.text,
        'isDefault': true
      };

      final success = await userProvider.addPaymentMethod(paymentData);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PayPal account added successfully')),
        );
        setState(() {
          _isAddingNew = false;
          _emailController.clear();
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  userProvider.errorMessage ?? 'Failed to add PayPal account')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBar = CustomAppBar(
      title: 'Payment Details',
      showBackButton: true,
      // No actions, avatar, or search for this screen
    );

    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final isLoading = userProvider.state == ViewState.busy;
        final paymentMethods = userProvider.paymentMethods ?? [];

        return BaseScreen(
          // appBarConfig: const BaseScreenAppBarConfig( // Removed
          //   titleText: 'Payment Details',
          //   mainContentType: AppBarMainContentType.title,
          //   showBackButton: true,
          // ),
          appBar: appBar, // Pass the constructed app bar
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Payment Methods',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Display existing payment methods
                      if (paymentMethods.isEmpty && !_isAddingNew)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32.0),
                            child: Text('No payment methods added yet'),
                          ),
                        )
                      else
                        ...paymentMethods
                            .map((method) => _buildPaymentMethodCard(method)),

                      const SizedBox(height: 16),

                      // Form to add new payment method
                      if (_isAddingNew)
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Add PayPal Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'PayPal Email',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your PayPal email';
                                  } else if (!value.contains('@')) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomButton(
                                      label: 'Save',
                                      isLoading: isLoading,
                                      width: ButtonWidth.expanded,
                                      onPressed:
                                          isLoading ? () {} : _addPayPalAccount,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: CustomOutlinedButton(
                                      label: 'Cancel',
                                      isLoading: false,
                                      width: OutlinedButtonWidth.expanded,
                                      onPressed: () {
                                        setState(() {
                                          _isAddingNew = false;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      else
                        Center(
                          child: CustomButton(
                            label: 'Add PayPal Account',
                            icon: Icons.add,
                            isLoading: false,
                            onPressed: () {
                              setState(() {
                                _isAddingNew = true;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withAlpha((255 * 0.1).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.paypal,
            color: Colors.blueAccent,
          ),
        ),
        title: Text(
          method['type']?.toString().toUpperCase() ?? 'PayPal',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(method['email'] ?? ''),
        trailing: method['isDefault'] == true
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Default',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              )
            : const SizedBox(),
      ),
    );
  }
}
