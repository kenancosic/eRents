import 'package:e_rents_desktop/features/auth/state/forgot_password_form_state.dart';
import 'package:e_rents_desktop/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:e_rents_desktop/widgets/status_dialog.dart';
import 'package:e_rents_desktop/widgets/auth/auth_screen_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ForgotPasswordFormState(),
      child: const ForgotPasswordView(),
    );
  }
}

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _resetPassword(BuildContext context) async {
    final state = context.read<ForgotPasswordFormState>();
    await state.resetPassword(_emailController.text);

    if (state.isEmailSent && mounted) {
      // Show success dialog
      StatusDialog.show(
        context: context,
        title: 'Reset Instructions Sent!',
        message:
            'We\'ve sent password reset instructions to your email address. Please check your inbox.',
        actionLabel: 'Back to Login',
        onActionPressed: () {
          context.pop(); // Go back after dialog action
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      formWidget: _buildForgotPasswordForm(context),
      customSideContent: _buildDefaultSideContent(context),
    );
  }

  Widget _buildDefaultSideContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.apartment, size: 120, color: Colors.black54),
          const SizedBox(height: 24),
          Text(
            'eRents Property Management',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Manage your properties with ease',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordForm(BuildContext context) {
    return Consumer<ForgotPasswordFormState>(
      builder: (context, state, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Forgot Password',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Enter your email address and we\'ll send you instructions to reset your password.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              enabled: !state.isLoading,
            ),
            const SizedBox(height: 24),
            CustomButton(
              onPressed: () => _resetPassword(context),
              label: 'Send Reset Instructions',
              isLoading: state.isLoading,
            ),
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                context.pop(); // Return to login screen
              },
              child: const Text('Back to Login'),
            ),
          ],
        );
      },
    );
  }
}
