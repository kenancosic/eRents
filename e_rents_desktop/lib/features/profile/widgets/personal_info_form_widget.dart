import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:e_rents_desktop/features/profile/providers/profile_provider.dart';

import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/widgets/inputs/address_input.dart'; // Use generic AddressInput

class PersonalInfoFormWidget extends StatefulWidget {
  final bool isEditing;
  final GlobalKey<FormState> formKey;

  const PersonalInfoFormWidget({
    super.key,
    required this.isEditing,
    required this.formKey,
  });

  @override
  State<PersonalInfoFormWidget> createState() => _PersonalInfoFormWidgetState();
}

class _PersonalInfoFormWidgetState extends State<PersonalInfoFormWidget> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController; // This may become redundant

  late final TextEditingController _streetNameController;
  late final TextEditingController _streetNumberController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _countryController;


  @override
  void initState() {
    super.initState();
    final user = context.read<ProfileProvider>().currentUser;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: user?.address?.getFullAddress() ?? ''); // Still used for display if not editing

    // Initialize address controllers separately
    _streetNameController = TextEditingController(text: user?.address?.streetLine1 ?? '');
    _streetNumberController = TextEditingController(text: user?.address?.streetLine2 ?? '');
    _cityController = TextEditingController(text: user?.address?.city ?? '');
    _postalCodeController = TextEditingController(text: user?.address?.postalCode ?? '');
    _countryController = TextEditingController(text: user?.address?.country ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose(); // Still needed if used for display

    _streetNameController.dispose();
    _streetNumberController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final user = profileProvider.currentUser;
    if (user == null) {
      return const Center(child: Text('User not found.'));
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
          Row(
            children: [
              Expanded(
                child: _buildCompactTextField(
                  context,
                  controller: _firstNameController,
                  label: 'First Name',
                  enabled: widget.isEditing,
                  onChanged: (value) =>
                      profileProvider.updateLocalUser(firstName: value),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactTextField(
                  context,
                  controller: _lastNameController,
                  label: 'Last Name',
                  enabled: widget.isEditing,
                  onChanged: (value) =>
                      profileProvider.updateLocalUser(lastName: value),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCompactTextField(
                  context,
                  controller: _emailController,
                  label: 'Email',
                  enabled: false,
                  suffixIcon: const Icon(Icons.lock_outline, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactTextField(
                  context,
                  controller: _phoneController,
                  label: 'Phone Number',
                  enabled: widget.isEditing,
                  onChanged: (value) => profileProvider.updateLocalUser(phone: value),
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
          // Replaced GoogleAddressInput with AddressInput
          AddressInput(
            initialAddress: user.address,
            streetNameController: _streetNameController,
            streetNumberController: _streetNumberController,
            cityController: _cityController,
            postalCodeController: _postalCodeController,
            countryController: _countryController,
            onManualAddressChanged: () {
              // Update local user property directly from controllers
              profileProvider.updateLocalUser(
                address: Address(
                  streetLine1: _streetNameController.text,
                  streetLine2: _streetNumberController.text,
                  city: _cityController.text,
                  postalCode: _postalCodeController.text,
                  country: _countryController.text,
                  latitude: null, // Removed with GoogleMaps
                  longitude: null, // Removed with GoogleMaps
                ),
              );
            },
            // This callback is for an external address picker, not strictly needed for manual inputs
            // but kept for compatibility as it might be useful if the AddressInput widget changes
            onAddressSelected: (Address? selectedAddress) {
              if (selectedAddress != null) {
                profileProvider.updateLocalUser(address: selectedAddress);
                // Also update text controllers if AddressInput's internal fields differ
                _streetNameController.text = selectedAddress.streetLine1 ?? '';
                _streetNumberController.text = selectedAddress.streetLine2 ?? '';
                _cityController.text = selectedAddress.city ?? '';
                _postalCodeController.text = selectedAddress.postalCode ?? '';
                _countryController.text = selectedAddress.country ?? '';
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required bool enabled,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: !enabled,
        fillColor:
            enabled
                ? null
                : Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withAlpha(77),
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
                  : Theme.of(context).colorScheme.onSurface.withAlpha(153),
        ),
      ),
      style: TextStyle(
        fontSize: 14,
        color:
            enabled
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withAlpha(204),
      ),
      validator: validator,
    );
  }
}
