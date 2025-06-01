import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/profile/providers/profile_provider.dart';

import 'package:e_rents_desktop/widgets/inputs/google_address_input.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PersonalInfoFormWidget extends StatefulWidget {
  final bool isEditing;
  final GlobalKey<FormState> formKey;

  const PersonalInfoFormWidget({
    Key? key,
    required this.isEditing,
    required this.formKey,
  }) : super(key: key);

  @override
  State<PersonalInfoFormWidget> createState() => _PersonalInfoFormWidgetState();
}

class _PersonalInfoFormWidgetState extends State<PersonalInfoFormWidget> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  late String _googleApiKey = 'YOUR_API_KEY_NOT_FOUND';

  @override
  void initState() {
    super.initState();
    _loadGoogleApiKey();
    _loadUserData();

    // Add listeners to update user data when controllers change
    _firstNameController.addListener(_updateUserData);
    _lastNameController.addListener(_updateUserData);
    _phoneController.addListener(_updateUserData);
    _addressController.addListener(_updateUserData);
  }

  Future<void> _loadGoogleApiKey() async {
    if (dotenv.isInitialized) {
      setState(() {
        _googleApiKey =
            dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'YOUR_API_KEY_NOT_FOUND';
      });
    }
    if (_googleApiKey == 'YOUR_API_KEY_NOT_FOUND') {
      print(
        "Warning: GOOGLE_MAPS_API_KEY not found. Ensure it is set in your lib/.env file and that dotenv.load(fileName: \"lib/.env\") was called.",
      );
    }
  }

  @override
  void dispose() {
    // Remove listeners before disposing
    _firstNameController.removeListener(_updateUserData);
    _lastNameController.removeListener(_updateUserData);
    _phoneController.removeListener(_updateUserData);
    _addressController.removeListener(_updateUserData);

    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    if (!mounted) return;
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final user = profileProvider.currentUser;

    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      _addressController.text = user.addressDetail?.streetLine1 ?? '';
    }
  }

  void _updateUserData() {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    profileProvider.updateUserPersonalInfo(
      _firstNameController.text,
      _lastNameController.text,
      _phoneController.text.isEmpty ? null : _phoneController.text,
    );

    // Update address if using fallback text field
    if (_addressController.text.isNotEmpty) {
      profileProvider.updateUserAddressFromString(_addressController.text);
    }
  }

  // Method to manually trigger data update (useful for when saving)
  void commitChanges() {
    _updateUserData();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final currentUser = profileProvider.currentUser;
    final initialUserAddress = currentUser?.addressDetail?.streetLine1;

    // Ensure address controller has the current address value
    if (_addressController.text.isEmpty && initialUserAddress != null) {
      _addressController.text = initialUserAddress;
    }

    Widget addressDisplayWidget;
    final bool apiKeyMissing = _googleApiKey == 'YOUR_API_KEY_NOT_FOUND';

    if (apiKeyMissing && widget.isEditing) {
      // Show a basic text field when API key is missing but in edit mode
      addressDisplayWidget = _buildCompactTextField(
        controller: _addressController,
        label: 'Address (Limited - API Key Missing)',
        enabled: true,
        validator: null, // Make address optional when API is not available
      );
    } else if (apiKeyMissing && !widget.isEditing) {
      // Show read-only field when API key is missing and not editing
      addressDisplayWidget = _buildReadOnlyField(
        label: 'Address',
        value: initialUserAddress ?? 'Not set',
        icon: Icons.location_on,
      );
    } else if (widget.isEditing) {
      // Full Google Address Input when API key is available and editing
      addressDisplayWidget = GoogleAddressInput(
        googleApiKey: _googleApiKey,
        initialValue: initialUserAddress,
        labelText: 'Address',
        hintText: 'Search for your address',
        onAddressSelected: (AddressDetails? details) {
          profileProvider.updateUserAddressDetails(details);
        },
        validator: (value) {
          // Make address optional for now to avoid validation errors
          return null;
        },
      );
    } else {
      // Read-only view when not editing
      addressDisplayWidget = _buildReadOnlyField(
        label: 'Address',
        value: initialUserAddress ?? 'Not set',
        icon: Icons.location_on,
      );
    }

    return Form(
      key: widget.formKey,
      autovalidateMode:
          widget.isEditing
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name Fields
          Row(
            children: [
              Expanded(
                child: _buildCompactTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  enabled: widget.isEditing,
                  validator:
                      (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  enabled: widget.isEditing,
                  validator:
                      (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Contact Fields
          Row(
            children: [
              Expanded(
                child: _buildCompactTextField(
                  controller: _emailController,
                  label: 'Email',
                  enabled: false,
                  suffixIcon: const Icon(Icons.lock_outline, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  enabled: widget.isEditing,
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        !RegExp(
                          r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$',
                        ).hasMatch(value)) {
                      return 'Invalid phone number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Address Field
          addressDisplayWidget,
        ],
      ),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required bool enabled,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: !enabled,
        fillColor:
            enabled
                ? null
                : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        labelStyle: TextStyle(
          fontSize: 14,
          color:
              enabled
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      style: TextStyle(
        fontSize: 14,
        color:
            enabled
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
      ),
      validator: validator,
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
