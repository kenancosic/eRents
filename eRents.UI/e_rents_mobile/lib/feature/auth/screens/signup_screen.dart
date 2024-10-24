import 'dart:ui'; // For ImageFilter
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_input_field.dart';
import 'package:e_rents_mobile/core/widgets/next_step_button.dart';
import 'package:e_rents_mobile/feature/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class SignUpScreen extends StatefulWidget {
  SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controllers for form fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  DateTime? _selectedDateOfBirth;

  // For PageView
  final PageController _pageController = PageController();
  int _currentStep = 0;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  void _goToNextPage() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousPage() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Sign Up',
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
          // Gradient overlay
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Create Your Account",
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
                              "Please fill in the details to sign up.",
                              style: TextStyle(
                                fontSize: 14, // Reduced font size
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20), // Reduced spacing
                            // PageView
                            SizedBox(
                              height: 400.0,
                              child: PageView(
                                controller: _pageController,
                                physics: const NeverScrollableScrollPhysics(),
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentStep = index;
                                  });
                                },
                                children: [
                                  // Step 1: Account Information
                                  SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Step 1 of 3',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white70),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Username',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white),
                                        ),
                                        CustomInputField(
                                          controller: _usernameController,
                                          hintText: 'Enter username',
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Email',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white),
                                        ),
                                        CustomInputField(
                                          controller: _emailController,
                                          hintText: 'hi@example.com',
                                          keyboardType:
                                              TextInputType.emailAddress,
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Password',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white),
                                        ),
                                        CustomInputField(
                                          controller: _passwordController,
                                          hintText: 'Enter password',
                                          obscureText: true,
                                          hasSuffixIcon: true,
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Confirm Password',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white),
                                        ),
                                        CustomInputField(
                                          controller:
                                              _confirmPasswordController,
                                          hintText: 'Confirm password',
                                          obscureText: true,
                                          hasSuffixIcon: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Step 2: Personal Information
                                  SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Step 2 of 3',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white70),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'First Name',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white),
                                        ),
                                        CustomInputField(
                                          controller: _nameController,
                                          hintText: 'Enter first name',
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Last Name',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white),
                                        ),
                                        CustomInputField(
                                          controller: _lastNameController,
                                          hintText: 'Enter last name',
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Phone Number',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white),
                                        ),
                                        CustomInputField(
                                          controller: _phoneNumberController,
                                          hintText: 'Enter phone number',
                                          keyboardType: TextInputType.phone,
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Date of Birth',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white),
                                        ),
                                        GestureDetector(
                                          onTap: () => _selectDate(context),
                                          child: AbsorbPointer(
                                            child: CustomInputField(
                                              controller:
                                                  TextEditingController(
                                                      text: _selectedDateOfBirth ==
                                                              null
                                                          ? ''
                                                          : '${_selectedDateOfBirth!.toLocal()}'
                                                              .split(' ')[0]),
                                              hintText: 'Select date of birth',
                                              suffixIcon: Icons.calendar_today,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Step 3: Address Information
                                  SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Step 3 of 3',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white70),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Address',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white),
                                        ),
                                        CustomInputField(
                                          controller: _addressController,
                                          hintText: 'Enter address',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20), // Reduced spacing
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (_currentStep != 0)
                                  Expanded(
                                    child: NextStepButton(
                                      label: "Back",
                                      onPressed: _goToPreviousPage,
                                    ),
                                  ),
                                if (_currentStep != 0)
                                  const SizedBox(width: 10),
                                Expanded(
                                  child: Consumer<AuthProvider>(
                                    builder: (context, provider, child) {
                                      if (provider.state == ViewState.Busy) {
                                        return const CircularProgressIndicator();
                                      }
                                      return NextStepButton(
                                        label: _currentStep == 2
                                            ? "Sign Up"
                                            : "Next",
                                        onPressed: () async {
                                          if (_currentStep < 2) {
                                            // Optionally add validation before going to next step
                                            _goToNextPage();
                                          } else {
                                            // Perform sign up
                                            if (_passwordController.text !=
                                                _confirmPasswordController
                                                    .text) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Passwords do not match')),
                                              );
                                              return;
                                            }

                                            bool success = await provider
                                                .register({
                                              'username':
                                                  _usernameController.text,
                                              'email': _emailController.text,
                                              'password':
                                                  _passwordController.text,
                                              'confirmPassword':
                                                  _confirmPasswordController
                                                      .text,
                                              'address':
                                                  _addressController.text,
                                              'dateOfBirth':
                                                  _selectedDateOfBirth
                                                      ?.toIso8601String(),
                                              'phoneNumber':
                                                  _phoneNumberController.text,
                                              'name': _nameController.text,
                                              'lastName':
                                                  _lastNameController.text,
                                            });

                                            if (!mounted) return;

                                            if (success) {
                                              context.go('/');
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(provider
                                                          .errorMessage ??
                                                      'Registration failed'),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                context.go('/login');
                              },
                              child: const Text(
                                'Back to Login',
                                style: TextStyle(
                                  color: Color(0xFF7065F0),
                                  fontSize: 14, // Reduced font size
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
            ),
          ),
        ],
      ),
    );
  }
}
