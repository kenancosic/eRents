import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/feature/profile/providers/payment_methods_provider.dart';
import 'package:e_rents_mobile/feature/profile/providers/user_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    // Optionally, load payment methods when the screen initializes
    // context.read<PaymentMethodsProvider>().loadPaymentMethods();
  }

  Future<void> _linkPayPalAccount() async {
    final provider = context.read<PaymentMethodsProvider>();
    final approvalUrl = await provider.startPayPalLinking();

    if (approvalUrl != null && mounted) {
      final uri = Uri.parse(approvalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open PayPal to complete linking.')),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error?.message ?? 'Failed to start PayPal linking.'),
        ),
      );
    }
  }

  Future<void> _unlinkPayPalAccount() async {
    final provider = context.read<PaymentMethodsProvider>();
    final success = await provider.unlinkPaypal();

    if (success && mounted) {
      // Refresh user data to reflect the change
      await context.read<UserProfileProvider>().initUser();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PayPal account unlinked successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error?.message ?? 'Failed to unlink PayPal account.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBar = CustomAppBar(
      title: 'Payment Details',
      showBackButton: true,
    );

    return Consumer2<PaymentMethodsProvider, UserProfileProvider>(
      builder: (context, paymentProvider, userProvider, _) {
        return BaseScreen(
          appBar: appBar,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your PayPal Account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage your PayPal account for seamless payments.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                _buildPayPalStatusCard(paymentProvider, userProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPayPalStatusCard(
      PaymentMethodsProvider paymentProvider, UserProfileProvider userProvider) {
    final isLinked = userProvider.user?.isPaypalLinked ?? false;
    final isLoading = paymentProvider.isUpdatingPaypal;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.paypal, color: Colors.blueAccent, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PayPal',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isLinked ? 'Account Linked' : 'No Account Linked',
                        style: TextStyle(
                          color: isLinked ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (isLinked)
              CustomButton(
                label: 'Unlink PayPal Account',
                isLoading: isLoading,
                onPressed: isLoading ? () {} : _unlinkPayPalAccount,
                width: ButtonWidth.expanded,
                backgroundColor: Colors.red,
              )
            else
              CustomButton(
                label: 'Link PayPal Account',
                isLoading: isLoading,
                onPressed: isLoading ? () {} : _linkPayPalAccount,
                width: ButtonWidth.expanded,
              ),
          ],
        ),
      ),
    );
  }
}
