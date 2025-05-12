import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/profile/providers/profile_provider.dart';
import 'package:e_rents_desktop/features/profile/widgets/common_widgets.dart';

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
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _loadUserData() {
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
      _roleController.text = user.role.toString();
      _cityController.text = user.city ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildSection(
      context: context,
      title: 'Personal Information',
      icon: Icons.person,
      child: Form(
        key: widget.formKey,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: buildTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    enabled: widget.isEditing,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: buildTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    enabled: widget.isEditing,
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
                    enabled: widget.isEditing,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    enabled: widget.isEditing,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: buildTextField(
                    controller: _roleController,
                    label: 'Role',
                    enabled: widget.isEditing,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: buildTextField(
                    controller: _cityController,
                    label: 'City',
                    enabled: widget.isEditing,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
