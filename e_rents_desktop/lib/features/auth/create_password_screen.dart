import 'package:e_rents_desktop/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:e_rents_desktop/widgets/status_dialog.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:e_rents_desktop/features/auth/widgets/auth_screen_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CreatePasswordScreen extends StatefulWidget {
  final String email;
  final String code;

  const CreatePasswordScreen({super.key, required this.email, required this.code});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createPassword(AuthProvider authProvider) async {
    if (_formKey.currentState?.validate() ?? false) {
      // Reset the password with the AuthProvider
      final success = await authProvider.resetPassword(widget.email, widget.code, _passwordController.text);
      if (success && mounted) {
        // Show success message and navigate to login
        StatusDialog.show(
          context: context,
          title: 'Password Created!',
          message:
              'Your password has been successfully created. You can now login with your new credentials.',
          actionLabel: 'Go to Login',
          onActionPressed: () => context.go('/login'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      formWidget: _buildCreatePasswordForm(context),
    );
  }

  Widget _buildCreatePasswordForm(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create New Password',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Please create a new password for your account.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock),
                  helperText: 'Min 8 chars with upper, lower, digit & special (@\$!%*?&)',
                  helperMaxLines: 2,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 8 || value.length > 100) {
                    return 'Password must be between 8 and 100 characters';
                  }
                  final pwdRe = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])');
                  if (!pwdRe.hasMatch(value)) {
                    return 'Password must contain lower, upper, digit and special character';
                  }
                  return null;
                },
                enabled: !authProvider.isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                enabled: !authProvider.isLoading,
              ),
              const SizedBox(height: 24),
              CustomButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () async {
                        await _createPassword(authProvider);
                      },
                label: 'Create Password',
                isLoading: authProvider.isLoading,
              ),
              if (authProvider.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    authProvider.error!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        );
      },
    );
  }
}