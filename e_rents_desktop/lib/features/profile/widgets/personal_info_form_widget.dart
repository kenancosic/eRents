import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:e_rents_desktop/features/profile/providers/profile_provider.dart';

import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/widgets/inputs/google_address_input.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    final user = context.read<ProfileProvider>().currentUser;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: user?.address?.getFullAddress() ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String get _googleApiKey {
    if (dotenv.isInitialized) {
      return dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'YOUR_API_KEY_NOT_FOUND';
    }
    return 'YOUR_API_KEY_NOT_FOUND';
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final user = profileProvider.currentUser;
    if (user == null) {
      return const Center(child: Text('User not found.'));
    }

    Widget addressDisplayWidget;
        final bool apiKeyMissing = _googleApiKey == 'YOUR_API_KEY_NOT_FOUND';

        if (apiKeyMissing && widget.isEditing) {
      addressDisplayWidget = _buildCompactTextField(
        context,
                controller: _addressController,
        label: 'Address (Limited - API Key Missing)',
        enabled: true,
        onChanged: (value) {
          final currentAddress = context.read<ProfileProvider>().currentUser?.address;
          final newAddress = (currentAddress ?? Address()).copyWith(streetLine1: value);
          context.read<ProfileProvider>().updateLocalUser(address: newAddress);
        },
        validator: null,
      );
        } else if (apiKeyMissing && !widget.isEditing) {
      addressDisplayWidget = _buildReadOnlyField(
        context,
        label: 'Address',
        value: user.address?.getFullAddress() ?? 'Not set',
        icon: Icons.location_on,
      );
        } else if (widget.isEditing) {
      addressDisplayWidget = GoogleAddressInput(
        googleApiKey: _googleApiKey,
        initialValue: user.address?.getFullAddress(),
        labelText: 'Address',
        hintText: 'Search for your address',
                onAddressSelected: (address) {
          setState(() {
            _addressController.text = address?.getFullAddress() ?? '';
            if (address != null) {
              context.read<ProfileProvider>().updateLocalUser(address: address);
            }
          });
        },
        validator: (value) => null,
      );
    } else {
      addressDisplayWidget = _buildReadOnlyField(
        context,
        label: 'Address',
        value: user.address?.getFullAddress() ?? 'Not set',
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
          Row(
            children: [
              Expanded(
                child: _buildCompactTextField(
                  context,
                  controller: _firstNameController,
                  label: 'First Name',
                  enabled: widget.isEditing,
                  onChanged: (value) =>
                      context.read<ProfileProvider>().updateLocalUser(firstName: value),
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
                      context.read<ProfileProvider>().updateLocalUser(lastName: value),
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
                  onChanged: (value) => context.read<ProfileProvider>().updateLocalUser(phone: value),
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
          addressDisplayWidget,
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

  Widget _buildReadOnlyField(
    BuildContext context, {
    required String label,
    required String value,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(51),
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
                    ).colorScheme.onSurface.withAlpha(153),
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
