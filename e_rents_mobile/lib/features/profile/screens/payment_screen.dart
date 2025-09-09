import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/features/profile/widgets/paypal_settings_widget.dart';
import 'package:e_rents_mobile/features/profile/providers/user_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ensure user data is loaded when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UserProfileProvider>().initUser();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      // On returning to the app (e.g., from PayPal), refresh user profile
      context.read<UserProfileProvider>().loadCurrentUser(forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBar = CustomAppBar(
      title: 'Payment Details',
      showBackButton: true,
    );

    return BaseScreen(
      appBar: appBar,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Your PayPal Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Manage your PayPal account for seamless payments.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24),
            PaypalSettingsWidget(isEditing: true),
          ],
        ),
      ),
    );
  }
}
