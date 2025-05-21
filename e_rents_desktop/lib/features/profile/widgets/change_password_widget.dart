import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/profile/providers/profile_provider.dart';
import 'package:e_rents_desktop/features/profile/widgets/common_widgets.dart';

class ChangePasswordWidget extends StatefulWidget {
  final bool isEditing;
  final GlobalKey<FormState> formKey;

  const ChangePasswordWidget({
    Key? key,
    required this.isEditing,
    required this.formKey,
  }) : super(key: key);

  @override
  State<ChangePasswordWidget> createState() => _ChangePasswordWidgetState();
}

class _ChangePasswordWidgetState extends State<ChangePasswordWidget> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (widget.formKey.currentState!.validate()) {
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );

      final success = await profileProvider.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
        _confirmPasswordController.text,
      );

      if (mounted) {
        if (success) {
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password updated successfully'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                profileProvider.errorMessage ?? 'Failed to update password',
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildSection(
      context: context,
      title: 'Change Password',
      icon: Icons.lock,
      child: Form(
        key: widget.formKey,
        child: Column(
          children: [
            buildTextField(
              controller: _currentPasswordController,
              label: 'Current Password',
              enabled: widget.isEditing,
              isPassword: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: buildTextField(
                    controller: _newPasswordController,
                    label: 'New Password',
                    enabled: widget.isEditing,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter new password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: buildTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm New Password',
                    enabled: widget.isEditing,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm new password';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            if (widget.isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: ElevatedButton.icon(
                  onPressed: _updatePassword,
                  icon: const Icon(Icons.key),
                  label: const Text('Update Password'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
