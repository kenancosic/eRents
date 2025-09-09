import 'dart:ui'; // Import this for ImageFilter


import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_input_field.dart';
import 'package:e_rents_mobile/features/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      showAppBar: false,
      useSlidingDrawer: false,
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // Prevents background resizing
      body: Stack(
        children: [
          // Background image covering the entire screen
          Positioned.fill(
            child: Image.asset(
              'assets/images/appartment.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient overlay (optional)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Form content with blurred, semi-transparent card
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 80.0, // Space to avoid overlapping the logo
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
              ),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  // Blurred, semi-transparent card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "Forgot Password",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Please enter your email to reset your password.",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Email',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
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
                                if (!emailRe.hasMatch(val)) return 'Please enter a valid email address';
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
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Password reset email sent.')),
                                      );
                                      // Navigate to verification screen
                                      context.push('/verification?email=${_emailController.text.trim()}');
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                provider.errorMessage.isNotEmpty
                                                    ? provider.errorMessage
                                                    : 'Failed to send email')),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            CustomOutlinedButton.compact(
                              label: 'Back to login',
                              isLoading: false,
                              width: OutlinedButtonWidth.content,
                              textColor: const Color(0xFF7065F0),
                              borderColor: const Color(0xFF7065F0),
                              onPressed: () {
                                context.go('/login');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }
}
