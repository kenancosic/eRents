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
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 800;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background image (always present, but may be obscured by form on narrow screens)
          Positioned.fill(
            child: Image.asset(
              'assets/images/apartment.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Content layout - either Row (wide) or Column (narrow)
          if (isWideScreen)
            _buildWideLayout(context, screenSize)
          else
            _buildNarrowLayout(context),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, Size screenSize) {
    return Row(
      children: [
        // Form column - takes 40% of screen width
        Expanded(
          flex: 4,
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/polygon.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: _buildForgotPasswordForm(),
              ),
            ),
          ),
        ),

        // Side content column - takes 60% of screen width
        Expanded(
          flex: 6,
          child: SizedBox(
            height: double.infinity,
            child: _buildDefaultSideContent(context),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildForgotPasswordForm(),
          ),
        ),
      ),
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

  Widget _buildForgotPasswordForm() {
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
    );
  }
}
