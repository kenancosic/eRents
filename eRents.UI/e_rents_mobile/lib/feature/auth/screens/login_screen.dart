import 'dart:ui'; // Import this for ImageFilter

import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_input_field.dart';
import 'package:e_rents_mobile/feature/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Sign In',
      showAppBar: false,
      showBottomNavBar: false,
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
                    Colors.white.withOpacity(0.4),
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
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                  maxWidth: 300),
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
                                      color: Colors.white,
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
                              child: Text('Email',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.white)),
                            ),
                            CustomInputField(
                              controller: _emailController,
                              hintText: 'hi@example.com',
                              keyboardType: TextInputType.emailAddress,
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
                            ),
                            const SizedBox(height: 15),
                            Align(
                              alignment: Alignment.center,
                              child: TextButton(
                                onPressed: () {
                                  context.go('/forgot_password');
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Color(0xFF7065F0),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Consumer<AuthProvider>(
                              builder: (context, provider, child) {
                                if (provider.state == ViewState.Busy) {
                                  return const CircularProgressIndicator();
                                }
                                return CustomButton(
                                  label: "Login",
                                  isLoading: provider.state == ViewState.Busy,
                                  onPressed: () async {
                                    context.go('/');
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              alignment: WrapAlignment.spaceAround,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  "Don't have an account?",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.go('/signup');
                                  },
                                  child: const Text(
                                    'Sign up for free',
                                    style: TextStyle(
                                      color: Color(0xFF7065F0),
                                      fontSize: 14,
                                    ),
                                  ),
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
        ],
      ),
    );
  }
}
