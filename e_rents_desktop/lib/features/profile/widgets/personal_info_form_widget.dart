import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/profile/providers/profile_provider.dart';
import 'package:e_rents_desktop/features/profile/widgets/common_widgets.dart';
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

  late String _googleApiKey = 'YOUR_API_KEY_NOT_FOUND';

  @override
  void initState() {
    super.initState();
    _loadGoogleApiKey();
    _loadUserData();
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final currentUser = profileProvider.currentUser;
    final initialUserAddress = currentUser?.formattedAddress;

    Widget addressDisplayWidget;
    if (_googleApiKey == 'YOUR_API_KEY_NOT_FOUND') {
      addressDisplayWidget = Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Text(
          'Address input is unavailable (API Key missing or incorrect configuration).',
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: 14,
          ),
        ),
      );
    } else if (widget.isEditing) {
      addressDisplayWidget = GoogleAddressInput(
        googleApiKey: _googleApiKey,
        initialValue: initialUserAddress,
        labelText: 'Full Address',
        hintText: 'Search for your address',
        onAddressSelected: (AddressDetails? details) {
          profileProvider.updateUserAddressDetails(details);
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select or enter an address.';
          }
          return null;
        },
      );
    } else {
      addressDisplayWidget = buildStaticInfoField(
        label: 'Address',
        value: initialUserAddress ?? 'Not set',
        icon: Icons.location_on,
      );
    }

    return buildSection(
      context: context,
      title: 'Personal Information',
      icon: Icons.person,
      child: Form(
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
                  child: buildTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    enabled: widget.isEditing,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'First name cannot be empty'
                                : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: buildTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    enabled: widget.isEditing,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Last name cannot be empty'
                                : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    enabled: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    enabled: widget.isEditing,
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          !RegExp(
                            r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$',
                          ).hasMatch(value)) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            addressDisplayWidget,
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

Widget buildStaticInfoField({
  required String label,
  required String value,
  IconData? icon,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          children: [
            if (icon != null) Icon(icon, color: Colors.grey[700], size: 18),
            if (icon != null) const SizedBox(width: 8),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
          ],
        ),
      ],
    ),
  );
}
