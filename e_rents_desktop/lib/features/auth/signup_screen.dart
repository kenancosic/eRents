import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:e_rents_desktop/features/auth/state/signup_form_state.dart';
import 'package:flutter/material.dart';
import 'package:e_rents_desktop/widgets/custom_button.dart';
import 'package:e_rents_desktop/widgets/status_dialog.dart';
import 'package:e_rents_desktop/features/auth/widgets/auth_screen_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SignupFormState(context.read<AuthProvider>()),
      child: const SignupView(),
    );
  }
}

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signup(BuildContext context) async {
    final state = context.read<SignupFormState>();
    final success = await state.signup(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (success && mounted) {
      // Show success dialog
      StatusDialog.show(
        context: context,
        title: 'Registration Successful!',
        message:
            'Your account has been created successfully. You can now login with your credentials.',
        actionLabel: 'Go to Login',
        onActionPressed: () {
          context.go('/login');
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(formWidget: _buildSignupForm(context));
  }

  Widget _buildSignupForm(BuildContext context) {
    return Consumer<SignupFormState>(
      builder: (context, state, child) {
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
              enabled: !state.isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              enabled: !state.isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
              ),
              enabled: !state.isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              enabled: !state.isLoading,
            ),
            const SizedBox(height: 24),
            CustomButton(
              onPressed: () => _signup(context),
              label: 'Sign Up',
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
              child: const Text('Already have an account? Log in'),
            ),
          ],
        );
      },
    );
  }
}
