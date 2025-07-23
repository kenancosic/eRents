import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:e_rents_desktop/features/auth/widgets/auth_screen_layout.dart';
import 'package:e_rents_desktop/models/auth/register_request_model.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup(AuthProvider authProvider) async {
    if (_formKey.currentState?.validate() ?? false) {
      final request = RegisterRequestModel(
        name: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        password: _passwordController.text,
        confirmPassword: _passwordController.text,
        dateOfBirth: DateTime.now(),
        role: UserType.tenant.name,
      );
      await authProvider.register(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      formWidget: _buildSignupForm(context),
    );
  }

  Widget _buildSignupForm(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Join Us',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) =>
                    value!.isEmpty ? 'First name is required' : null,
                enabled: !authProvider.isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Last name is required' : null,
                enabled: !authProvider.isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value!.isEmpty ? 'Email is required' : null,
                enabled: !authProvider.isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (value) =>
                    value!.isEmpty ? 'Phone number is required' : null,
                enabled: !authProvider.isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) =>
                    value!.isEmpty ? 'Password is required' : null,
                enabled: !authProvider.isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                validator: (value) {
                  if (value!.isEmpty) return 'Please confirm your password';
                  if (value != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
                enabled: !authProvider.isLoading,
              ),
              const SizedBox(height: 24),
              CustomButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () async {
                        await _signup(authProvider);
                      },
                label: 'Sign Up',
                isLoading: authProvider.isLoading,
              ),
              if (authProvider.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    authProvider.error!.message,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Already have an account? Log in'),
              ),
            ],
          ),
        );
      },
    );
  }
}
