import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:e_rents_desktop/features/profile/providers/profile_provider.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/widgets/inputs/modern_address_input.dart';

class PersonalInfoFormWidget extends StatefulWidget {
  final bool isEditing;
  final GlobalKey<FormState> formKey;

  const PersonalInfoFormWidget({
    super.key,
    required this.isEditing,
    required this.formKey,
  });

  @override
  State<PersonalInfoFormWidget> createState() => PersonalInfoFormWidgetState();
}

class PersonalInfoFormWidgetState extends State<PersonalInfoFormWidget> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  Address? _currentAddress;

  @override
  void initState() {
    super.initState();
    final user = context.read<ProfileProvider>().currentUser;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _currentAddress = user?.address;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Collects current form values and updates the provider.
  /// Call this before saving to sync controller values to provider state.
  void syncToProvider() {
    final profileProvider = context.read<ProfileProvider>();
    final currentUser = profileProvider.currentUser;
    
    if (currentUser == null) return;

    // Update provider with complete user object
    profileProvider.updateLocalUser(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      phone: _phoneController.text,
      address: _currentAddress,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use read instead of watch to prevent rebuilds on provider changes
    // Controllers maintain their own state; we sync to provider only on save
    final profileProvider = context.read<ProfileProvider>();
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
          // Modern address input with search and manual entry
          ModernAddressInput(
            initialAddress: user.address,
            enabled: widget.isEditing,
            onAddressChanged: (Address? newAddress) {
              _currentAddress = newAddress;
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
