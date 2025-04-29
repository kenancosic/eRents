import 'package:e_rents_desktop/base/auth_base.dart';
import 'package:e_rents_desktop/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:e_rents_desktop/widgets/status_dialog.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? _errorMessage;
  bool _isEmailSent = false;

  void _resetPassword() {
    final email = _emailController.text;

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address.';
      });
      return;
    }

    // Here you would typically call your password reset service
    print('Reset password for email: $email');

    setState(() {
      _errorMessage = null;
      _isEmailSent = true;
    });

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

  @override
  Widget build(BuildContext context) {
    return AuthBaseScreen(
      title: 'Reset your password',
      formContent: _buildForgotPasswordForm(),
      backgroundImage: 'assets/images/apartment.jpg',
    );
  }

  Widget _buildForgotPasswordForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
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
          ),
          const SizedBox(height: 24),
          CustomButton(
            onPressed: _resetPassword,
            label: 'Send Reset Instructions',
            isLoading: false,
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          if (_isEmailSent)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Password reset instructions have been sent to your email.',
                style: TextStyle(color: Colors.green),
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
      ),
    );
  }
}
