import 'dart:ui'; // Import this for ImageFilter


import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_input_field.dart';
import 'package:e_rents_mobile/core/widgets/elevated_text_button.dart';
import 'package:e_rents_mobile/features/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  LoginScreen({super.key});

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
                    Colors.white.withAlpha((255 * 0.4).round()),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha((255 * 0.3).round()),
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 300),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Welcome to eRents",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SvgPicture.asset(
                                      'assets/images/HouseLogo.svg',
                                      height: 28,
                                      width: 35,
                                      colorFilter: const ColorFilter.mode(
                                          Colors.white, BlendMode.srcIn),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Please enter your login credentials.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Email or Username',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.white)),
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
                                    fontSize: 14, color: Colors.white),
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
                                if (val.length < 6) return 'Password must be at least 6 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            ElevatedTextButton(
                              text: 'Forgot Password?',
                              backgroundColor: Colors.black.withAlpha(100),
                              isCompact: true,
                              textColor: const Color(0xFF7065F0),
                              onPressed: () {
                                context.go('/forgot_password');
                              },
                            ),
                            const SizedBox(height: 15),
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
                                    final success = await provider.login(identifier, password);
                                    if (context.mounted) {
                                        if (success) {
                                            context.go('/');
                                        } else if (provider.hasError) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                                content: Text(provider.errorMessage)),
                                            );
                                        }
                                    }
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account?",
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedTextButton(
                                  text: 'Sign up for free',
                                  isCompact: true,
                                  backgroundColor: Colors.black.withAlpha(100),
                                  textColor: const Color(0xFF7065F0),
                                  onPressed: () {
                                    context.go('/signup');
                                  },
                                ),
                              ],
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
