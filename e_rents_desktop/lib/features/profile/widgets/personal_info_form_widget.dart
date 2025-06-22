import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/profile/state/personal_info_form_state.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/widgets/inputs/google_address_input.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PersonalInfoFormWidget extends StatelessWidget {
  final bool isEditing;
  final GlobalKey<FormState> formKey;

  const PersonalInfoFormWidget({
    super.key,
    required this.isEditing,
    required this.formKey,
  });

  String get _googleApiKey {
    if (dotenv.isInitialized) {
      return dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'YOUR_API_KEY_NOT_FOUND';
    }
    return 'YOUR_API_KEY_NOT_FOUND';
  }

  @override
  Widget build(BuildContext context) {
    final formState = context.watch<PersonalInfoFormState>();
    final user = formState.user;

    Widget addressDisplayWidget;
    final bool apiKeyMissing = _googleApiKey == 'YOUR_API_KEY_NOT_FOUND';

    if (apiKeyMissing && isEditing) {
      addressDisplayWidget = _buildCompactTextField(
        context,
        controller: formState.addressController,
        label: 'Address (Limited - API Key Missing)',
        enabled: true,
        onChanged:
            (value) =>
                formState.updateUser(address: Address(streetLine1: value)),
        validator: null,
      );
    } else if (apiKeyMissing && !isEditing) {
      addressDisplayWidget = _buildReadOnlyField(
        context,
        label: 'Address',
        value: user.address?.getFullAddress() ?? 'Not set',
        icon: Icons.location_on,
      );
    } else if (isEditing) {
      addressDisplayWidget = GoogleAddressInput(
        googleApiKey: _googleApiKey,
        initialValue: user.address?.getFullAddress(),
        labelText: 'Address',
        hintText: 'Search for your address',
        onAddressSelected: formState.updateAddress,
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
      key: formKey,
      autovalidateMode:
          isEditing
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
                  controller: formState.firstNameController,
                  label: 'First Name',
                  enabled: isEditing,
                  validator:
                      (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactTextField(
                  context,
                  controller: formState.lastNameController,
                  label: 'Last Name',
                  enabled: isEditing,
                  validator:
                      (value) =>
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
                  controller: formState.emailController,
                  label: 'Email',
                  enabled: false,
                  suffixIcon: const Icon(Icons.lock_outline, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactTextField(
                  context,
                  controller: formState.phoneController,
                  label: 'Phone Number',
                  enabled: isEditing,
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
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
