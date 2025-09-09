import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:e_rents_desktop/features/auth/widgets/auth_screen_layout.dart';
import 'package:e_rents_desktop/models/auth/register_request_model.dart';
import 'package:e_rents_desktop/models/enums/user_type.dart';
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
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  // Address fields required by backend
  final _cityController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _countryController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _signup(AuthProvider authProvider) async {
    if (_formKey.currentState?.validate() ?? false) {
      final request = RegisterRequestModel(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        username: _usernameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        dateOfBirth: DateTime.now(), // Default to today, should add date picker in future
        userType: UserType.tenant,
        city: _cityController.text,
        zipCode: _zipCodeController.text,
        country: _countryController.text,
      );
      final success = await authProvider.register(request);
      if (success && mounted) {
        // Navigate to the verification screen
        context.push('/verification?email=${_emailController.text}');
      } else {
        // Trigger re-validation to show server-side field errors inline
        _formKey.currentState?.validate();
      }
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
          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                validator: (value) {
                  final server = authProvider.getFieldError('firstName');
                  if (server != null) return server;
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'First name is required';
                  if (v.length > 100) return 'First name must not exceed 100 characters';
                  return null;
                },
                enabled: !authProvider.isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) {
                  final server = authProvider.getFieldError('lastName');
                  if (server != null) return server;
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Last name is required';
                  if (v.length > 100) return 'Last name must not exceed 100 characters';
                  return null;
                },
                enabled: !authProvider.isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) {
                  final server = authProvider.getFieldError('username');
                  if (server != null) return server;
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Username is required';
                  if (v.length < 3 || v.length > 50) {
                    return 'Username must be between 3 and 50 characters';
                  }
                  final re = RegExp(r'^[a-zA-Z0-9_]+$');
                  if (!re.hasMatch(v)) {
                    return 'Username can only contain letters, numbers, and underscores';
                  }
                  return null;
                },
                enabled: !authProvider.isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  final server = authProvider.getFieldError('email');
                  if (server != null) return server;
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Email is required';
                  final emailRe = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                  if (!emailRe.hasMatch(v)) return 'Invalid email format';
                  if (v.length > 100) return 'Email must not exceed 100 characters';
                  return null;
                },
                enabled: !authProvider.isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (value) {
                  final server = authProvider.getFieldError('phoneNumber');
                  if (server != null) return server;
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Phone number is required';
                  if (v.length > 20) return 'Phone number must not exceed 20 characters';
                  final phoneRe = RegExp(r'^\+?[1-9]\d{1,14}');
                  if (!phoneRe.hasMatch(v)) return 'Invalid phone number format';
                  return null;
                },
                enabled: !authProvider.isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (value) {
                  final server = authProvider.getFieldError('city');
                  if (server != null) return server;
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'City is required';
                  if (v.length > 100) return 'City must not exceed 100 characters';
                  return null;
                },
                enabled: !authProvider.isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _zipCodeController,
                decoration: const InputDecoration(labelText: 'Zip Code'),
                validator: (value) {
                  final server = authProvider.getFieldError('zipCode');
                  if (server != null) return server;
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Zip code is required';
                  if (v.length > 20) return 'Zip code must not exceed 20 characters';
                  return null;
                },
                enabled: !authProvider.isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(labelText: 'Country'),
                validator: (value) {
                  final server = authProvider.getFieldError('country');
                  if (server != null) return server;
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Country is required';
                  if (v.length > 100) return 'Country must not exceed 100 characters';
                  return null;
                },
                enabled: !authProvider.isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) {
                  final server = authProvider.getFieldError('password');
                  if (server != null) return server;
                  final v = value ?? '';
                  if (v.isEmpty) return 'Password is required';
                  if (v.length < 8 || v.length > 100) {
                    return 'Password must be between 8 and 100 characters';
                  }
                  final pwdRe = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]');
                  if (!pwdRe.hasMatch(v)) {
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
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                validator: (value) {
                  final server = authProvider.getFieldError('confirmPassword');
                  if (server != null) return server;
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
                    authProvider.error!,
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
