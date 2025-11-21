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

class ForgotPasswordScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          AuthFormContainer(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const AuthHeader(
                    title: 'Forgot Password',
                    subtitle: 'Please enter your email to reset your password.',
                    showLogo: false,
                  ),
                  const SizedBox(height: 30),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 14,
                        color: authLabelColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  CustomInputField(
                    controller: _emailController,
                    hintText: 'hi@example.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) return 'Email is required';
                      final emailRe = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!emailRe.hasMatch(val)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Consumer<AuthProvider>(
                    builder: (context, provider, child) {
                      return CustomButton(
                        label: "Submit",
                        isLoading: provider.isLoading,
                        onPressed: () async {
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          bool success = await provider
                              .forgotPassword(_emailController.text.trim());
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Password reset email sent.')),
                            );
                            // Navigate to verification screen
                            context.push(
                                '/verification?email=${_emailController.text.trim()}');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(provider.errorMessage.isNotEmpty
                                      ? provider.errorMessage
                                      : 'Failed to send email')),
                            );
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        context.go('/login');
                      },
                      child: const Text(
                        'Back to login',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
