import 'dart:ui'; // For ImageFilter

import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/services/google_places_service.dart'; // Added for PlaceDetails
import 'package:e_rents_mobile/core/widgets/custom_input_field.dart';
import 'package:e_rents_mobile/core/base/app_error.dart';
import 'package:e_rents_mobile/core/widgets/elevated_text_button.dart';
import 'package:e_rents_mobile/core/widgets/next_step_button.dart';
import 'package:e_rents_mobile/core/widgets/places_autocomplete_field.dart'; // Added
import 'package:e_rents_mobile/features/auth/auth_provider.dart';
import 'package:e_rents_mobile/features/profile/providers/user_profile_provider.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
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

  // Validation patterns to align with backend RegisterRequestValidator
  final RegExp _usernamePattern = RegExp(r'^[a-zA-Z0-9_]+$');
  final RegExp _emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  // At least one lowercase, one uppercase, one digit, one special character, min length handled separately
  final RegExp _passwordComplexityPattern =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]');
  // E.164 optional phone, e.g. +1234567890
  final RegExp _phonePattern = RegExp(r'^\+?[1-9]\d{1,14}$');

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
  final ImagePicker _picker = ImagePicker();
  XFile? _profileImage;
  final _formKey = GlobalKey<FormState>();
  bool _showErrors = false;
  // Server-side validation errors keyed by backend field names (e.g. "Email", "Password")
  Map<String, String> _serverErrors = {};

  void _onFormChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // Listen to text changes to recompute step validity and enable Next
    _usernameController.addListener(_onFormChanged);
    _emailController.addListener(_onFormChanged);
    _passwordController.addListener(_onFormChanged);
    _confirmPasswordController.addListener(_onFormChanged);
    _cityController.addListener(_onFormChanged);
    _manualZipCodeController.addListener(_onFormChanged);
    _manualCountryController.addListener(_onFormChanged);
    _manualStateController.addListener(_onFormChanged);
    _phoneNumberController.addListener(_onFormChanged);
    _nameController.addListener(_onFormChanged);
    _lastNameController.addListener(_onFormChanged);
  }

  bool get _isStep1Valid {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final usernameValid = username.isNotEmpty && username.length >= 3 && username.length <= 50 && _usernamePattern.hasMatch(username);
    final emailValid = _emailPattern.hasMatch(email) && email.length <= 100;
    final passValid = password.length >= 8 && password.length <= 100 && _passwordComplexityPattern.hasMatch(password);
    final confirmValid = confirm.isNotEmpty && confirm == password;
    return usernameValid && emailValid && passValid && confirmValid;
  }

  // Wrapper to satisfy VoidCallback typing while allowing async body
  Future<void> _handleNextOrSubmit(AuthProvider provider) async {
    // Trigger validators
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _showErrors = true;
      });
      return;
    }
    if (_currentStep < 2) {
      _goToNextPage();
      return;
    }
    // Clear previous server errors before new attempt
    setState(() { _serverErrors = {}; });

    // Perform sign up
    if (_passwordController.text != _confirmPasswordController.text) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
      }
      return;
    }

    // Address validation (mandatory)
    final cityVal = (_selectedCityName ?? _cityController.text).trim();
    final hasCity = cityVal.isNotEmpty;
    if (!hasCity) {
      setState(() {
        _showErrors = true;
      });
      return;
    }
    if (cityVal.length > 100) {
      setState(() { _showErrors = true; });
      return;
    }

    final zip = _manualZipCodeController.text.trim();
    if (zip.isEmpty) {
      setState(() { _showErrors = true; });
      return;
    }
    if (zip.length > 20) {
      setState(() { _showErrors = true; });
      return;
    }

    final country = (_manualCountryController.text.trim().isNotEmpty)
        ? _manualCountryController.text.trim()
        : _fetchedCountry?.trim() ?? '';
    if (country.isEmpty) {
      setState(() { _showErrors = true; });
      return;
    }
    if (country.length > 100) {
      setState(() { _showErrors = true; });
      return;
    }

    final success = await provider.register({
      'username': _usernameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'confirmPassword': _confirmPasswordController.text,
      'city': _selectedCityName ?? _cityController.text,
      'streetName': null,
      'streetNumber': null,
      'zipCode': zip,
      'country': country,
      'state': _manualStateController.text.isNotEmpty ? _manualStateController.text : null,
      'dateOfBirth': _selectedDateOfBirth?.toIso8601String(),
      'phoneNumber': _phoneNumberController.text,
      'name': _nameController.text,
      'lastName': _lastNameController.text,
      if (_profileImage != null) 'profileImagePath': _profileImage!.path,
    });

    if (!mounted) return;
    if (success) {
      // Option A: Upload profile image post-registration (if selected)
      if (_profileImage != null) {
        try {
          await context.read<UserProfileProvider>().uploadProfileImage(File(_profileImage!.path));
        } catch (e) {
          // Non-fatal: show feedback but continue navigation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile image upload failed: $e')),
          );
        }
      }
      context.go('/');
    } else {
      // Try to surface server-side validation errors if present
      final err = provider.error;
      if (err is ValidationError && err.fieldErrors != null && err.fieldErrors!.isNotEmpty) {
        final mapped = <String, String>{};
        err.fieldErrors!.forEach((key, list) {
          if (list.isNotEmpty) mapped[key] = list.join('. ');
        });
        setState(() {
          _serverErrors = mapped;
          _showErrors = true; // trigger autovalidation to show errors under fields
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage.isNotEmpty ? provider.errorMessage : 'Registration failed')),
      );
    }
  }

  bool get _isStep2Valid {
    // Names are optional per backend; step 2 is always passable
    return true;
  }

  bool get _isStep3Valid {
    final hasCity = (_selectedCityName != null && _selectedCityName!.trim().isNotEmpty) ||
        _cityController.text.trim().isNotEmpty;
    final zip = _manualZipCodeController.text.trim();
    final country = (_manualCountryController.text.trim().isNotEmpty)
        ? _manualCountryController.text.trim()
        : _fetchedCountry?.trim() ?? '';
    final zipValid = zip.isNotEmpty && zip.length <= 20;
    final countryValid = country.isNotEmpty && country.length <= 100;
    return hasCity && zipValid && countryValid;
  }

  bool _isDobValid() {
    if (_selectedDateOfBirth == null) return true; // optional
    final threshold = DateTime(DateTime.now().year - 13, DateTime.now().month, DateTime.now().day);
    // User must be at least 13 years old
    return _selectedDateOfBirth!.isBefore(threshold);
  }

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
        _showErrors = false; // reset for next step
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
        _showErrors = false;
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
                        child: Form(
                          key: _formKey,
                          autovalidateMode: _showErrors ? AutovalidateMode.always : AutovalidateMode.onUserInteraction,
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
                                          validator: (v) {
                                            final server = _serverErrors['Username'];
                                            if (server != null && server.isNotEmpty) return server;
                                            final val = v?.trim() ?? '';
                                            if (val.isEmpty) return 'Username is required';
                                            if (val.length < 3 || val.length > 50) {
                                              return 'Username must be between 3 and 50 characters';
                                            }
                                            if (!_usernamePattern.hasMatch(val)) {
                                              return 'Username can only contain letters, numbers, and underscores';
                                            }
                                            return null;
                                          },
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
                                          validator: (v) {
                                            final server = _serverErrors['Email'];
                                            if (server != null && server.isNotEmpty) return server;
                                            final val = v?.trim() ?? '';
                                            if (val.isEmpty) return 'Email is required';
                                            if (!_emailPattern.hasMatch(val)) return 'Invalid email format';
                                            if (val.length > 100) return 'Email must not exceed 100 characters';
                                            return null;
                                          },
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
                                          validator: (v) {
                                            final server = _serverErrors['Password'];
                                            if (server != null && server.isNotEmpty) return server;
                                            final val = v ?? '';
                                            if (val.isEmpty) return 'Password is required';
                                            if (val.length < 8 || val.length > 100) {
                                              return 'Password must be between 8 and 100 characters';
                                            }
                                            if (!_passwordComplexityPattern.hasMatch(val)) {
                                              return 'Password must contain lower, upper, digit and special character';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 6),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Password must include at least one lowercase letter, one uppercase letter, one digit, and one special character (@, \$, !, %, *, ?, &).',
                                            style: TextStyle(fontSize: 11, color: Colors.white70),
                                          ),
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
                                          validator: (v) {
                                            final server = _serverErrors['ConfirmPassword'];
                                            if (server != null && server.isNotEmpty) return server;
                                            final val = v ?? '';
                                            if (val.isEmpty) return 'Password confirmation is required';
                                            return val == _passwordController.text ? null : 'Passwords do not match';
                                          },
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
                                          validator: (v) {
                                            final server = _serverErrors['FirstName'];
                                            if (server != null && server.isNotEmpty) return server;
                                            final val = v?.trim() ?? '';
                                            if (val.isEmpty) return null; // optional
                                            if (val.length > 100) return 'First name must not exceed 100 characters';
                                            return null;
                                          },
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
                                          validator: (v) {
                                            final server = _serverErrors['LastName'];
                                            if (server != null && server.isNotEmpty) return server;
                                            final val = v?.trim() ?? '';
                                            if (val.isEmpty) return null; // optional
                                            if (val.length > 100) return 'Last name must not exceed 100 characters';
                                            return null;
                                          },
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
                                          validator: (v) {
                                            final server = _serverErrors['PhoneNumber'];
                                            if (server != null && server.isNotEmpty) return server;
                                            final val = v?.trim() ?? '';
                                            if (val.isEmpty) return null; // optional
                                            if (val.length > 20) return 'Phone number must not exceed 20 characters';
                                            if (!_phonePattern.hasMatch(val)) return 'Invalid phone number format';
                                            return null;
                                          },
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
                                              validator: (_) {
                                                final server = _serverErrors['DateOfBirth'];
                                                if (server != null && server.isNotEmpty) return server;
                                                return _isDobValid() ? null : 'User must be at least 13 years old';
                                              },
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

                                                debugPrint(
                                                    'Selected City (from controller): ${_cityController.text}');
                                                debugPrint(
                                                    'Selected City Name (parsed): $_selectedCityName');
                                                debugPrint(
                                                    'Fetched Zip Code: $_fetchedZipCode');
                                                debugPrint(
                                                    'Fetched Country: $_fetchedCountry');
                                                debugPrint(
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
                                        if (_showErrors)
                                          Builder(
                                            builder: (context) {
                                              final cityVal = (_selectedCityName ?? _cityController.text).trim();
                                              if (cityVal.isEmpty) {
                                                return const Padding(
                                                  padding: EdgeInsets.only(top: 4.0, left: 4.0),
                                                  child: Text('City is required', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                                );
                                              }
                                              if (cityVal.length > 100) {
                                                return const Padding(
                                                  padding: EdgeInsets.only(top: 4.0, left: 4.0),
                                                  child: Text('City must not exceed 100 characters', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                                );
                                              }
                                              final server = _serverErrors['City'];
                                              if (server != null && server.isNotEmpty) {
                                                return Padding(
                                                  padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                                                  child: Text(server, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                                                );
                                              }
                                              return const SizedBox.shrink();
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
                                                validator: (v) {
                                                  final server = _serverErrors['ZipCode'];
                                                  if (server != null && server.isNotEmpty) return server;
                                                  final val = v?.trim() ?? '';
                                                  if (val.isEmpty) return 'Zip code is required';
                                                  if (val.length > 20) return 'Zip code must not exceed 20 characters';
                                                  return null;
                                                },
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
                                                  validator: (v) => null,
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
                                                  validator: (v) {
                                                    final server = _serverErrors['Country'];
                                                    if (server != null && server.isNotEmpty) return server;
                                                    final val = v?.trim() ?? '';
                                                    if (val.isEmpty) return 'Country is required';
                                                    if (val.length > 100) return 'Country must not exceed 100 characters';
                                                    return null;
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        const SizedBox(height: 16),
                                        // Profile image (optional) - pick on Step 3 with gallery or camera
                                        Text(
                                          'Profile Image (optional)',
                                          style: const TextStyle(fontSize: 14, color: Colors.white),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 28,
                                              backgroundImage: _profileImage == null
                                                  ? const AssetImage('assets/images/user-image.png') as ImageProvider
                                                  : FileImage(File(_profileImage!.path)),
                                            ),
                                            const SizedBox(width: 12),
                                            Wrap(
                                              spacing: 8,
                                              children: [
                                                ElevatedTextButton.icon(
                                                  text: _profileImage == null ? 'Upload' : 'Change',
                                                  icon: Icons.upload,
                                                  isCompact: true,
                                                  onPressed: () async {
                                                    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                                                    if (picked != null) {
                                                      setState(() {
                                                        _profileImage = picked;
                                                      });
                                                    }
                                                  },
                                                ),
                                                ElevatedTextButton.icon(
                                                  text: 'Take Photo',
                                                  icon: Icons.photo_camera,
                                                  isCompact: true,
                                                  onPressed: () async {
                                                    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                                                    if (picked != null) {
                                                      setState(() {
                                                        _profileImage = picked;
                                                      });
                                                    }
                                                  },
                                                ),
                                              ],
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
                                      final isValid = _currentStep == 0
                                          ? _isStep1Valid
                                          : _currentStep == 1
                                              ? _isStep2Valid
                                              : _isStep3Valid;
                                      return NextStepButton(
                                        label: _currentStep == 2 ? "Sign Up" : "Next",
                                        isLoading: provider.isLoading,
                                        onPressed: () {
                                          if (!isValid) {
                                            setState(() { _showErrors = true; });
                                            return;
                                          }
                                          _handleNextOrSubmit(provider);
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
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
