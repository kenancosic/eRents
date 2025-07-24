import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:e_rents_mobile/feature/profile/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isAddingNew = false;
  Map<String, dynamic>? _editingMethod;
  final Map<String, TextEditingController> _editControllers = {};

  @override
  void dispose() {
    _emailController.dispose();
    for (var controller in _editControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _addPayPalAccount() async {
    if (_formKey.currentState!.validate()) {
      final profileProvider = context.read<ProfileProvider>();

      final paymentData = {
        'type': 'paypal',
        'email': _emailController.text,
        'isDefault': true
      };

      final success = await profileProvider.addPaymentMethod(paymentData);

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
                  profileProvider.error ?? 'Failed to add PayPal account')),
        );
      }
    }
  }

  Future<void> _updatePayPalAccount(Map<String, dynamic> method) async {
    final methodId = method['id']?.toString() ?? '';
    final controller = _editControllers[methodId];

    if (controller != null && controller.text.isNotEmpty) {
      // Mock update for now since updatePaymentMethod doesn't exist
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('PayPal account updated successfully (Mock)')),
      );
      setState(() {
        _editingMethod = null;
      });
    }
  }

  Future<void> _deletePayPalAccount(Map<String, dynamic> method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete PayPal Account'),
        content: Text('Are you sure you want to remove ${method['email']}?'),
        actions: [
          CustomOutlinedButton.compact(
            label: 'Cancel',
            isLoading: false,
            onPressed: () => context.pop(false),
          ),
          CustomButton.compact(
            label: 'Delete',
            isLoading: false,
            onPressed: () => context.pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Mock delete for now since deletePaymentMethod doesn't exist
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('PayPal account removed successfully (Mock)')),
      );
    }
  }

  void _startEditing(Map<String, dynamic> method) {
    setState(() {
      _editingMethod = method;
      final methodId = method['id']?.toString() ?? '';
      _editControllers[methodId] =
          TextEditingController(text: method['email'] ?? '');
    });
  }

  void _cancelEditing() {
    setState(() {
      if (_editingMethod != null) {
        final methodId = _editingMethod!['id']?.toString() ?? '';
        _editControllers[methodId]?.dispose();
        _editControllers.remove(methodId);
      }
      _editingMethod = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appBar = CustomAppBar(
      title: 'Payment Details',
      showBackButton: true,
    );

    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        final isLoading = profileProvider.isLoading;
        final paymentMethods = profileProvider.paymentMethods;

        return BaseScreen(
          appBar: appBar,
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your PayPal Accounts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Manage your PayPal accounts for seamless payments',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Display existing payment methods
                      if (paymentMethods.isEmpty && !_isAddingNew)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32.0),
                            child: Text('No PayPal accounts added yet'),
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
                                'Add New PayPal Account',
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
                                          _emailController.clear();
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
    final methodId = method['id']?.toString() ?? '';
    final isEditing =
        _editingMethod != null && _editingMethod!['id'] == method['id'];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'PayPal',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (method['isDefault'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    Colors.green.withAlpha((255 * 0.1).round()),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Default',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (isEditing)
                        TextFormField(
                          controller: _editControllers[methodId],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        )
                      else
                        Text(
                          method['email'] ?? '',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isEditing)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _startEditing(method);
                          break;
                        case 'delete':
                          _deletePayPalAccount(method);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (isEditing) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomButton.compact(
                      label: 'Save',
                      isLoading: false,
                      onPressed: () => _updatePayPalAccount(method),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomOutlinedButton.compact(
                      label: 'Cancel',
                      isLoading: false,
                      onPressed: _cancelEditing,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
