import 'package:e_rents_mobile/core/services/google_places_service.dart';
import 'package:e_rents_mobile/core/widgets/custom_input_field.dart';
import 'package:e_rents_mobile/core/base/app_error.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/places_autocomplete_field.dart';
import 'package:e_rents_mobile/core/utils/theme.dart';
import 'package:e_rents_mobile/features/auth/auth_provider.dart';
import 'package:e_rents_mobile/features/auth/widgets/auth_screen_layout.dart';
import 'package:e_rents_mobile/features/auth/widgets/auth_form_container.dart';
import 'package:e_rents_mobile/features/auth/widgets/auth_header.dart';
import 'package:e_rents_mobile/features/profile/providers/user_profile_provider.dart';
import 'package:flutter/material.dart';
import 'dart:io';
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

  // Validation patterns
  final RegExp _usernamePattern = RegExp(r'^[a-zA-Z0-9_]+$');
  final RegExp _emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  final RegExp _passwordComplexityPattern =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]');
  final RegExp _phonePattern = RegExp(r'^\+?[1-9]\d{1,14}$');

  // Address controllers
  final TextEditingController _manualZipCodeController =
      TextEditingController();
  final TextEditingController _manualStateController = TextEditingController();
  final TextEditingController _manualCountryController =
      TextEditingController();

  // Address state
  String? _fetchedZipCode;
  String? _fetchedCountry;
  String? _fetchedState;
  String? _selectedCityName;
  bool _cityHasBeenSelected = false;

  final ImagePicker _picker = ImagePicker();
  XFile? _profileImage;
  final _formKey = GlobalKey<FormState>();
  bool _showErrors = false;
  Map<String, String> _serverErrors = {};

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cityController.dispose();
    _phoneNumberController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _manualZipCodeController.dispose();
    _manualStateController.dispose();
    _manualCountryController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp(AuthProvider provider) async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _showErrors = true;
      });
      return;
    }

    setState(() {
      _serverErrors = {};
    });

    if (_passwordController.text != _confirmPasswordController.text) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
      }
      return;
    }

    // Address validation
    final cityVal = (_selectedCityName ?? _cityController.text).trim();
    final zip = _manualZipCodeController.text.trim();
    final country = (_manualCountryController.text.trim().isNotEmpty)
        ? _manualCountryController.text.trim()
        : _fetchedCountry?.trim() ?? '';

    if (cityVal.isEmpty || zip.isEmpty || country.isEmpty) {
      setState(() {
        _showErrors = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please complete all required address fields')),
      );
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
      'state': _manualStateController.text.isNotEmpty
          ? _manualStateController.text
          : null,
      'dateOfBirth': _selectedDateOfBirth != null 
          ? '${_selectedDateOfBirth!.year.toString().padLeft(4, '0')}-${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}-${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}'
          : null,
      'phoneNumber': _phoneNumberController.text,
      'firstName': _nameController.text,
      'lastName': _lastNameController.text,
      if (_profileImage != null) 'profileImagePath': _profileImage!.path,
    });

    if (!mounted) return;
    if (success) {
      // Auto-login after successful registration to get auth token
      final loginSuccess = await provider.login(
        _emailController.text,
        _passwordController.text,
      );
      
      if (!mounted) return;
      
      if (loginSuccess && _profileImage != null) {
        try {
          // Now we have a valid auth token, upload the profile image
          await context
              .read<UserProfileProvider>()
              .uploadProfileImage(File(_profileImage!.path));
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Profile image upload failed: $e')),
            );
          }
        }
      }
      if (!mounted) return;
      context.go('/');
    } else {
      final err = provider.error;
      if (err is ValidationError &&
          err.fieldErrors != null &&
          err.fieldErrors!.isNotEmpty) {
        final mapped = <String, String>{};
        err.fieldErrors!.forEach((key, list) {
          if (list.isNotEmpty) mapped[key] = list.join('. ');
        });
        setState(() {
          _serverErrors = mapped;
          _showErrors = true;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(provider.errorMessage.isNotEmpty
                ? provider.errorMessage
                : 'Registration failed')),
      );
    }
  }

  bool _isDobValid() {
    if (_selectedDateOfBirth == null) return true;
    final threshold = DateTime(
        DateTime.now().year - 13, DateTime.now().month, DateTime.now().day);
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

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 40.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          AuthFormContainer(
            child: Form(
              key: _formKey,
              autovalidateMode: _showErrors
                  ? AutovalidateMode.always
                  : AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AuthHeader(
                    title: 'Create Your Account',
                    subtitle: 'Please fill in the details to sign up.',
                  ),
                  const SizedBox(height: 20),

                  // Account Information Section
                  const Text(
                    'Account Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: authLabelColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Username',
                    style: TextStyle(
                      fontSize: 14,
                      color: authLabelColor,
                      fontWeight: FontWeight.w500,
                    ),
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
                      color: authLabelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  CustomInputField(
                    controller: _emailController,
                    hintText: 'hi@example.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      final server = _serverErrors['Email'];
                      if (server != null && server.isNotEmpty) return server;
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) return 'Email is required';
                      if (!_emailPattern.hasMatch(val)) {
                        return 'Invalid email format';
                      }
                      if (val.length > 100) {
                        return 'Email must not exceed 100 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 14,
                      color: authLabelColor,
                      fontWeight: FontWeight.w500,
                    ),
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
                  const SizedBox(height: 4),
                  Text(
                    'Must include lowercase, uppercase, digit, and special character (@, \$, !, %, *, ?, &)',
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Confirm Password',
                    style: TextStyle(
                      fontSize: 14,
                      color: authLabelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  CustomInputField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm password',
                    obscureText: true,
                    hasSuffixIcon: true,
                    validator: (v) {
                      final server = _serverErrors['ConfirmPassword'];
                      if (server != null && server.isNotEmpty) return server;
                      final val = v ?? '';
                      if (val.isEmpty) {
                        return 'Password confirmation is required';
                      }
                      return val == _passwordController.text
                          ? null
                          : 'Passwords do not match';
                    },
                  ),
                  const SizedBox(height: 15),

                  // Personal Information Section
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 15),
                  const Text(
                    'Personal Information (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: authLabelColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'First Name',
                    style: TextStyle(
                      fontSize: 14,
                      color: authLabelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  CustomInputField(
                    controller: _nameController,
                    hintText: 'Enter first name',
                    validator: (v) {
                      final server = _serverErrors['FirstName'];
                      if (server != null && server.isNotEmpty) return server;
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) return null;
                      if (val.length > 100) {
                        return 'First name must not exceed 100 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Last Name',
                    style: TextStyle(
                      fontSize: 14,
                      color: authLabelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  CustomInputField(
                    controller: _lastNameController,
                    hintText: 'Enter last name',
                    validator: (v) {
                      final server = _serverErrors['LastName'];
                      if (server != null && server.isNotEmpty) return server;
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) return null;
                      if (val.length > 100) {
                        return 'Last name must not exceed 100 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Phone Number',
                    style: TextStyle(
                      fontSize: 14,
                      color: authLabelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  CustomInputField(
                    controller: _phoneNumberController,
                    hintText: 'Enter phone number',
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      final server = _serverErrors['PhoneNumber'];
                      if (server != null && server.isNotEmpty) return server;
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) return null;
                      if (val.length > 20) {
                        return 'Phone number must not exceed 20 characters';
                      }
                      if (!_phonePattern.hasMatch(val)) {
                        return 'Invalid phone number format';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Date of Birth',
                    style: TextStyle(
                      fontSize: 14,
                      color: authLabelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: CustomInputField(
                        controller: TextEditingController(
                            text: _selectedDateOfBirth == null
                                ? ''
                                : '${_selectedDateOfBirth!.toLocal()}'
                                    .split(' ')[0]),
                        hintText: 'Select date of birth',
                        suffixIcon: Icons.calendar_today,
                        validator: (_) {
                          final server = _serverErrors['DateOfBirth'];
                          if (server != null && server.isNotEmpty) {
                            return server;
                          }
                          return _isDobValid()
                              ? null
                              : 'User must be at least 13 years old';
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Address Information Section
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 15),
                  const Text(
                    'Address Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: authLabelColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'City',
                    style: TextStyle(
                      fontSize: 14,
                      color: authLabelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  PlacesAutocompleteField(
                    controller: _cityController,
                    hintText: 'Search and select city',
                    searchType: '(cities)',
                    onPlaceSelected: (PlaceDetails? placeDetails) {
                      if (placeDetails != null) {
                        setState(() {
                          _cityHasBeenSelected = true;
                          _selectedCityName =
                              placeDetails.getAddressComponent('locality') ??
                                  placeDetails.getAddressComponent(
                                      'administrative_area_level_3') ??
                                  placeDetails
                                      .getAddressComponent('postal_town');

                          _fetchedZipCode =
                              placeDetails.getAddressComponent('postal_code');
                          _fetchedCountry =
                              placeDetails.getAddressComponent('country');
                          _fetchedState = placeDetails
                              .getAddressComponent('administrative_area_level_1');

                          _manualZipCodeController.text = _fetchedZipCode ?? '';
                          _manualStateController.text = _fetchedState ?? '';
                          _manualCountryController.text = _fetchedCountry ?? '';
                        });
                      } else {
                        setState(() {
                          _cityHasBeenSelected = false;
                          _selectedCityName = null;
                          _fetchedZipCode = null;
                          _fetchedCountry = null;
                          _fetchedState = null;
                          _manualZipCodeController.clear();
                          _manualStateController.clear();
                          _manualCountryController.clear();
                        });
                      }
                    },
                  ),
                  if (_showErrors)
                    Builder(
                      builder: (context) {
                        final cityVal =
                            (_selectedCityName ?? _cityController.text).trim();
                        if (cityVal.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 4.0, left: 4.0),
                            child: Text('City is required',
                                style: TextStyle(
                                    color: Colors.redAccent, fontSize: 12)),
                          );
                        }
                        final server = _serverErrors['City'];
                        if (server != null && server.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                            child: Text(server,
                                style: const TextStyle(
                                    color: Colors.redAccent, fontSize: 12)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  const SizedBox(height: 10),

                  if (_cityHasBeenSelected) ...[
                    const Text(
                      'Zip Code',
                      style: TextStyle(
                        fontSize: 14,
                        color: authLabelColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    CustomInputField(
                      controller: _manualZipCodeController,
                      hintText: 'Enter zip code',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final server = _serverErrors['ZipCode'];
                        if (server != null && server.isNotEmpty) return server;
                        final val = v?.trim() ?? '';
                        if (val.isEmpty) return 'Zip code is required';
                        if (val.length > 20) {
                          return 'Zip code must not exceed 20 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'State/Region',
                      style: TextStyle(
                        fontSize: 14,
                        color: authLabelColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    CustomInputField(
                      controller: _manualStateController,
                      hintText: 'Enter state or region',
                      validator: (v) => null,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Country',
                      style: TextStyle(
                        fontSize: 14,
                        color: authLabelColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    CustomInputField(
                      controller: _manualCountryController,
                      hintText: 'Enter country',
                      validator: (v) {
                        final server = _serverErrors['Country'];
                        if (server != null && server.isNotEmpty) return server;
                        final val = v?.trim() ?? '';
                        if (val.isEmpty) return 'Country is required';
                        if (val.length > 100) {
                          return 'Country must not exceed 100 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                  ],

                  // Profile Image Section
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 15),
                  const Text(
                    'Profile Image (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      color: authLabelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: _profileImage == null
                            ? const AssetImage('assets/images/user-image.png')
                                as ImageProvider
                            : FileImage(File(_profileImage!.path)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await _picker.pickImage(
                                    source: ImageSource.gallery, imageQuality: 80);
                                if (picked != null) {
                                  setState(() {
                                    _profileImage = picked;
                                  });
                                }
                              },
                              icon: const Icon(Icons.upload, size: 18),
                              label: Text(
                                _profileImage == null ? 'Upload' : 'Change',
                                style: const TextStyle(fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await _picker.pickImage(
                                    source: ImageSource.camera, imageQuality: 80);
                                if (picked != null) {
                                  setState(() {
                                    _profileImage = picked;
                                  });
                                }
                              },
                              icon: const Icon(Icons.photo_camera, size: 18),
                              label: const Text(
                                'Take Photo',
                                style: TextStyle(fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  Consumer<AuthProvider>(
                    builder: (context, provider, child) {
                      return CustomButton(
                        label: "Sign Up",
                        isLoading: provider.isLoading,
                        onPressed: () => _handleSignUp(provider),
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
                        'Back to Login',
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
