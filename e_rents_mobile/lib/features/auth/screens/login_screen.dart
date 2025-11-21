import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_input_field.dart';
import 'package:e_rents_mobile/features/auth/auth_provider.dart';
import 'package:e_rents_mobile/core/utils/theme.dart';
import 'package:e_rents_mobile/features/auth/widgets/auth_screen_layout.dart';
import 'package:e_rents_mobile/features/auth/widgets/auth_form_container.dart';
import 'package:e_rents_mobile/features/auth/widgets/auth_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  LoginScreen({super.key});

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
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AuthHeader(
                    title: 'Welcome to eRents',
                    subtitle: 'Please enter your login credentials.',
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Email or Username',
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
                      if (val.isEmpty) {
                        return 'Email or username is required';
                      }
                      if (val.contains('@')) {
                        final emailRe = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                        if (!emailRe.hasMatch(val)) {
                          return 'Please enter a valid email address';
                        }
                      } else {
                        if (val.length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 14,
                        color: authLabelColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  CustomInputField(
                    controller: _passwordController,
                    hintText: 'Enter password',
                    obscureText: true,
                    hasSuffixIcon: true,
                    suffixIcon: Icons.visibility_off,
                    validator: (v) {
                      final val = v ?? '';
                      if (val.isEmpty) return 'Password is required';
                      if (val.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        context.go('/forgot_password');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Consumer<AuthProvider>(
                    builder: (context, provider, child) {
                      return CustomButton(
                        label: "Login",
                        isLoading: provider.isLoading,
                        onPressed: () async {
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          final identifier = _emailController.text.trim();
                          final password = _passwordController.text.trim();
                          final success =
                              await provider.login(identifier, password);
                          if (context.mounted) {
                            if (success) {
                              context.go('/');
                            } else if (provider.hasError) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(provider.errorMessage)),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(
                          color: textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.go('/signup');
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Sign up for free',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
