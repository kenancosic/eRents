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
                  // Blurred, semi-transparent card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                        15.0), // Reduced the border radius
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width *
                            0.85, // Set fixed width
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 20.0), // Reduced padding
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize
                              .min, // Set mainAxisSize to minimize height
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  "Welcome to eRents",
                                  style: TextStyle(
                                    fontSize: 24, // Reduced font size
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                                SvgPicture.asset(
                                  'assets/images/HouseLogo.svg',
                                  height: 28, // Reduced height
                                  width: 35,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8), // Reduced spacing
                            const Text(
                              "Please enter your login credentials.",
                              style: TextStyle(
                                fontSize: 14, // Reduced font size
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20), // Reduced spacing
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Email',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white), // Reduced font size
                              ),
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
                                    fontSize: 14,
                                    color: Colors.white), // Reduced font size
                              ),
                            ),
                            CustomInputField(
                              controller: _passwordController,
                              hintText: 'Enter password',
                              obscureText: true,
                              hasSuffixIcon: true,
                              suffixIcon: Icons.visibility_off,
                            ),
                            const SizedBox(height: 15), // Reduced spacing
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
                                    fontSize: 14, // Reduced font size
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15), // Reduced spacing
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
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
