import 'package:flutter/material.dart';
import 'package:e_rents_desktop/widgets/custom_button.dart';
import 'package:e_rents_desktop/widgets/status_dialog.dart';
import 'package:e_rents_desktop/widgets/auth/auth_screen_layout.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _errorMessage;

  void _signup() {
    final name = _nameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    // Here you would typically call your authentication service
    print('Name: $name');
    print('Email: $email');
    print('Password: $password');

    setState(() {
      _errorMessage = null;
    });

    // Show success dialog
    StatusDialog.show(
      context: context,
      title: 'Registration Successful!',
      message:
          'Your account has been created successfully. You can now login with your credentials.',
      actionLabel: 'Go to Login',
      onActionPressed: () {
        context.pop(); // Return to login screen
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      formWidget: _buildSignupForm(),
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

  Widget _buildSignupForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Join Us',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 24),
        CustomButton(onPressed: _signup, label: 'Sign Up', isLoading: false),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            context.pop(); // Return to login screen
          },
          child: const Text('Already have an account? Log in'),
        ),
      ],
    );
  }
}
