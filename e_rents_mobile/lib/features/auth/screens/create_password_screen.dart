import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_input_field.dart';
import 'package:e_rents_mobile/features/auth/auth_provider.dart';
import 'package:e_rents_mobile/core/utils/theme.dart';
import 'package:e_rents_mobile/features/auth/widgets/auth_screen_layout.dart';
import 'package:e_rents_mobile/features/auth/widgets/auth_form_container.dart';
import 'package:e_rents_mobile/features/auth/widgets/auth_header.dart';
import 'package:flutter/material.dart';
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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your password has been successfully created. You can now login with your new credentials.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to login after a short delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              context.go('/login');
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      child: _buildCreatePasswordForm(context),
    );
  }

  Widget _buildCreatePasswordForm(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            AuthFormContainer(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(
                      title: 'Create New Password',
                      subtitle: 'Please create a new password for your account.',
                      showLogo: false,
                    ),
                    const SizedBox(height: 24),
                  
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'New Password',
                        style: TextStyle(
                          fontSize: 14,
                          color: authLabelColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    CustomInputField(
                      controller: _passwordController,
                      hintText: 'Enter new password',
                      obscureText: _obscurePassword,
                      hasSuffixIcon: true,
                      suffixIcon: _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        if (!RegExp(
                                r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]')
                            .hasMatch(value)) {
                          return 'Password must contain lowercase, uppercase, digit, and special character';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Confirm Password',
                        style: TextStyle(
                          fontSize: 14,
                          color: authLabelColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    CustomInputField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm new password',
                      obscureText: _obscureConfirmPassword,
                      hasSuffixIcon: true,
                      suffixIcon: _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      label: 'Create Password',
                      isLoading: authProvider.isLoading,
                      onPressed: () async {
                        await _createPassword(authProvider);
                      },
                    ),
                    if (authProvider.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          authProvider.errorMessage,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
