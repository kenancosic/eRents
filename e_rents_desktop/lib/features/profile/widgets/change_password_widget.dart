import 'package:flutter/material.dart';
import 'package:e_rents_desktop/features/profile/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class ChangePasswordWidget extends StatefulWidget {
  final bool isEditing;

  const ChangePasswordWidget({super.key, required this.isEditing});

  @override
  State<ChangePasswordWidget> createState() => _ChangePasswordWidgetState();
}

class _ChangePasswordWidgetState extends State<ChangePasswordWidget> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isEditing)
            Container(
              padding: const EdgeInsets.all(16),
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
                  Icon(
                    Icons.lock,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(153),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password Security',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your password is encrypted and secure',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(153),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (widget.isEditing) ...[
            _buildCompactTextField(
              context,
              controller: _currentPasswordController,
              label: 'Current Password',
              isPassword: true,
              enabled: !profileProvider.isChangingPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Current password is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCompactTextField(
                    context,
                    controller: _newPasswordController,
                    label: 'New Password',
                    isPassword: true,
                    enabled: !profileProvider.isChangingPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'New password is required';
                      }
                      if (value.length < 8) {
                        return 'Minimum 8 characters';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactTextField(
                    context,
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    isPassword: true,
                    enabled: !profileProvider.isChangingPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm password';
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
            const SizedBox(height: 16),
            if (profileProvider.passwordChangeError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  profileProvider.passwordChangeError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: profileProvider.isChangingPassword
                    ? null
                    : () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          final success = await context.read<ProfileProvider>().changePassword(
                                currentPassword: _currentPasswordController.text,
                                newPassword: _newPasswordController.text,
                                confirmPassword: _confirmPasswordController.text,
                              );
                          if (success && context.mounted) {
                            _currentPasswordController.clear();
                            _newPasswordController.clear();
                            _confirmPasswordController.clear();
                            FocusScope.of(context).unfocus();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password updated successfully'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                icon: profileProvider.isChangingPassword
                    ? Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(right: 8),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.key),
                label: Text(
                  profileProvider.isChangingPassword ? 'Updating...' : 'Update Password',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required bool isPassword,
    required bool enabled,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        labelStyle: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        suffixIcon:
            isPassword ? const Icon(Icons.lock_outline, size: 16) : null,
      ),
      style: const TextStyle(fontSize: 14),
      validator: validator,
    );
  }
}
