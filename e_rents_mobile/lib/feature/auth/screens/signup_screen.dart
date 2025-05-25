import 'dart:ui'; // For ImageFilter
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/services/google_places_service.dart'; // Added for PlaceDetails
import 'package:e_rents_mobile/core/widgets/custom_input_field.dart';
import 'package:e_rents_mobile/core/widgets/elevated_text_button.dart';
import 'package:e_rents_mobile/core/widgets/next_step_button.dart';
import 'package:e_rents_mobile/core/widgets/places_autocomplete_field.dart'; // Added
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:e_rents_mobile/feature/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

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
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  DateTime? _selectedDateOfBirth;

  // Controllers for manual address parts (Zip, State, Country)
  final TextEditingController _manualZipCodeController =
      TextEditingController();
  final TextEditingController _manualStateController = TextEditingController();
  final TextEditingController _manualCountryController =
      TextEditingController();

  // State variables to store parsed address components from Google Places
  String? _fetchedStreetName;
  String? _fetchedStreetNumber;
  String? _fetchedZipCode;
  String? _fetchedCountry;
  String? _fetchedState;
  String? _selectedCityName;

  // Flag to control visibility of additional address fields
  bool _cityHasBeenSelected = false;

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
    _cityController.dispose();
    _phoneNumberController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    // Dispose new controllers
    _manualZipCodeController.dispose();
    _manualStateController.dispose();
    _manualCountryController.dispose();
    super.dispose();
  }

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
          // Gradient overlay
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
          // Form content with blurred, semi-transparent card
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
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
                                      "Create Your Account ",
                                      style: TextStyle(
                                        fontSize: 24, // Reduced font size
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SvgPicture.asset(
                                      'assets/images/HouseLogo.svg',
                                      height: 28, // Reduced height
                                      width: 35,
                                      colorFilter: const ColorFilter.mode(
                                          Colors.white, BlendMode.srcIn),
                                    ),
                                  ],
                                ),
                              ),
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
                                              controller: TextEditingController(
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
                                        // "Where are you currently residing ?" Label MOVED HERE
                                        const Padding(
                                          padding: EdgeInsets.only(bottom: 8.0),
                                          child: Text(
                                            'Where are you currently residing ?',
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const Text(
                                          'City',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white),
                                        ),
                                        PlacesAutocompleteField(
                                          controller: _cityController,
                                          hintText: 'Search and select city',
                                          searchType:
                                              '(cities)', // Restrict to cities
                                          onPlaceSelected:
                                              (PlaceDetails? placeDetails) {
                                            if (placeDetails != null) {
                                              setState(() {
                                                _cityHasBeenSelected =
                                                    true; // Show additional fields

                                                _selectedCityName = placeDetails
                                                        .getAddressComponent(
                                                            'locality') ??
                                                    placeDetails
                                                        .getAddressComponent(
                                                            'administrative_area_level_3') ??
                                                    placeDetails
                                                        .getAddressComponent(
                                                            'postal_town');

                                                _fetchedStreetName =
                                                    placeDetails
                                                        .getAddressComponent(
                                                            'route');
                                                _fetchedStreetNumber =
                                                    placeDetails
                                                        .getAddressComponent(
                                                            'street_number');
                                                _fetchedZipCode = placeDetails
                                                    .getAddressComponent(
                                                        'postal_code');
                                                _fetchedCountry = placeDetails
                                                    .getAddressComponent(
                                                        'country');
                                                _fetchedState = placeDetails
                                                    .getAddressComponent(
                                                        'administrative_area_level_1');

                                                // Pre-fill manual fields
                                                _manualZipCodeController.text =
                                                    _fetchedZipCode ?? '';
                                                _manualStateController.text =
                                                    _fetchedState ?? '';
                                                _manualCountryController.text =
                                                    _fetchedCountry ?? '';

                                                print(
                                                    'Selected City (from controller): ${_cityController.text}');
                                                print(
                                                    'Selected City Name (parsed): $_selectedCityName');
                                                print(
                                                    'Fetched Zip Code: $_fetchedZipCode');
                                                print(
                                                    'Fetched Country: $_fetchedCountry');
                                                print(
                                                    'Fetched State: $_fetchedState');
                                              });
                                            } else {
                                              // Handle case where no details are found or user clears selection
                                              setState(() {
                                                _cityHasBeenSelected =
                                                    false; // Hide additional fields
                                                _selectedCityName = null;
                                                _fetchedStreetName = null;
                                                _fetchedStreetNumber = null;
                                                _fetchedZipCode = null;
                                                _fetchedCountry = null;
                                                _fetchedState = null;
                                                // Clear manual fields
                                                _manualZipCodeController
                                                    .clear();
                                                _manualStateController.clear();
                                                _manualCountryController
                                                    .clear();
                                              });
                                            }
                                          },
                                        ),
                                        const SizedBox(height: 15), // Spacing

                                        // Zip Code Field
                                        if (_cityHasBeenSelected)
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Zip Code',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white),
                                              ),
                                              CustomInputField(
                                                controller:
                                                    _manualZipCodeController,
                                                hintText: 'Enter zip code',
                                                keyboardType:
                                                    TextInputType.number,
                                              ),
                                              const SizedBox(height: 10),
                                            ],
                                          ),

                                        // State Field
                                        if (_cityHasBeenSelected)
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'State/Region',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white),
                                              ),
                                              AbsorbPointer(
                                                absorbing:
                                                    _manualStateController
                                                        .text.isNotEmpty,
                                                child: CustomInputField(
                                                  controller:
                                                      _manualStateController,
                                                  hintText:
                                                      'Enter state or region',
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                            ],
                                          ),

                                        // Country Field
                                        if (_cityHasBeenSelected)
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Country',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white),
                                              ),
                                              AbsorbPointer(
                                                absorbing:
                                                    _manualCountryController
                                                        .text.isNotEmpty,
                                                child: CustomInputField(
                                                  controller:
                                                      _manualCountryController,
                                                  hintText: 'Enter country',
                                                ),
                                              ),
                                            ],
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
                                      if (provider.state == ViewState.busy) {
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

                                            // Validate Required Zip Code if city is selected
                                            if (_cityHasBeenSelected &&
                                                _manualZipCodeController
                                                    .text.isEmpty) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Zip code is required when a city is selected')),
                                              );
                                              return;
                                            }

                                            bool success =
                                                await provider.register({
                                              'username':
                                                  _usernameController.text,
                                              'email': _emailController.text,
                                              'password':
                                                  _passwordController.text,
                                              'confirmPassword':
                                                  _confirmPasswordController
                                                      .text,
                                              'city': _selectedCityName ??
                                                  _cityController.text,
                                              'streetName': null,
                                              'streetNumber': null,
                                              'zipCode':
                                                  _manualZipCodeController
                                                          .text.isNotEmpty
                                                      ? _manualZipCodeController
                                                          .text
                                                      : null,
                                              'country':
                                                  _manualCountryController
                                                          .text.isNotEmpty
                                                      ? _manualCountryController
                                                          .text
                                                      : null,
                                              'state': _manualStateController
                                                      .text.isNotEmpty
                                                  ? _manualStateController.text
                                                  : null,
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
                            ElevatedTextButton(
                              text: 'Back to Login',
                              isCompact: true,
                              backgroundColor: Colors.black.withAlpha(100),
                              textColor: const Color(0xFF7065F0),
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
        ],
      ),
    );
  }
}
