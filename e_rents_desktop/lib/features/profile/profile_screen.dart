import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/profile/providers/profile_state_provider.dart';
import 'package:e_rents_desktop/features/profile/widgets/profile_header_widget.dart';
import 'package:e_rents_desktop/features/profile/widgets/personal_info_form_widget.dart';
import 'package:e_rents_desktop/features/profile/widgets/change_password_widget.dart';
import 'package:e_rents_desktop/features/profile/widgets/paypal_settings_widget.dart';
import 'package:e_rents_desktop/widgets/common/section_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _personalInfoFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  bool _isEditing = false;

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });

    if (!_isEditing && _personalInfoFormKey.currentState?.validate() == true) {
      _saveProfile();
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
    // Refresh data from provider to discard changes
    final profileProvider = Provider.of<ProfileStateProvider>(
      context,
      listen: false,
    );
    profileProvider.refreshProfile();
  }

  Future<void> _saveProfile() async {
    if (_personalInfoFormKey.currentState?.validate() == true) {
      final profileProvider = Provider.of<ProfileStateProvider>(
        context,
        listen: false,
      );

      if (profileProvider.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User data is not available.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Ensure all form changes are committed before saving
      // This will update the provider with latest form data
      _personalInfoFormKey.currentState?.save();

      final success = await profileProvider.updateUserProfile(
        profileProvider.currentUser!,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _isEditing = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to update profile: ${profileProvider.error?.message ?? 'Unknown error'}',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileStateProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.currentUser == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.currentUser == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading profile: ${provider.error?.message ?? 'Unknown error'}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadUserProfile(forceRefresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header Section
                ProfileHeaderWidget(
                  isEditing: _isEditing,
                  onEditPressed: _toggleEditing,
                  onCancelPressed: _isEditing ? _cancelEditing : null,
                ),

                const SizedBox(height: 32),

                // Main Content in Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Use column layout for smaller screens
                    if (constraints.maxWidth < 800) {
                      return Column(
                        children: [
                          // Personal Information Section
                          SectionCard(
                            title: 'Personal Information',
                            titleIcon: Icons.person,
                            child: PersonalInfoFormWidget(
                              isEditing: _isEditing,
                              formKey: _personalInfoFormKey,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Security Section
                          SectionCard(
                            title: 'Security & Password',
                            titleIcon: Icons.security,
                            child: ChangePasswordWidget(
                              isEditing: _isEditing,
                              formKey: _passwordFormKey,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Payment Settings Section
                          SectionCard(
                            title: 'Payment Settings',
                            titleIcon: Icons.payment,
                            child: PaypalSettingsWidget(isEditing: _isEditing),
                          ),

                          const SizedBox(height: 24),

                          // Account Summary Section
                          SectionCard(
                            title: 'Account Summary',
                            titleIcon: Icons.info_outline,
                            child: _buildAccountSummary(provider.currentUser),
                          ),
                        ],
                      );
                    }

                    // Row layout for larger screens
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              // Personal Information Section
                              SectionCard(
                                title: 'Personal Information',
                                titleIcon: Icons.person,
                                child: PersonalInfoFormWidget(
                                  isEditing: _isEditing,
                                  formKey: _personalInfoFormKey,
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Security Section
                              SectionCard(
                                title: 'Security & Password',
                                titleIcon: Icons.security,
                                child: ChangePasswordWidget(
                                  isEditing: _isEditing,
                                  formKey: _passwordFormKey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Right Column
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              // Payment Settings Section
                              SectionCard(
                                title: 'Payment Settings',
                                titleIcon: Icons.payment,
                                child: PaypalSettingsWidget(
                                  isEditing: _isEditing,
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Account Summary Section
                              SectionCard(
                                title: 'Account Summary',
                                titleIcon: Icons.info_outline,
                                child: _buildAccountSummary(
                                  provider.currentUser,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Action Buttons
                if (_isEditing)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              provider.isUpdatingProfile ? null : _saveProfile,
                          icon:
                              provider.isUpdatingProfile
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.save),
                          label: Text(
                            provider.isUpdatingProfile
                                ? 'Saving...'
                                : 'Save Changes',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              provider.isUpdatingProfile
                                  ? null
                                  : _cancelEditing,
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.grey.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountSummary(user) {
    if (user == null) {
      return const Center(child: Text('Profile information not available'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryItem(
          'Account Type',
          user.role.toString().split('.').last.toUpperCase(),
          Icons.account_circle,
        ),
        const SizedBox(height: 12),
        _buildSummaryItem(
          'Member Since',
          '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
          Icons.calendar_today,
        ),
        const SizedBox(height: 12),
        _buildSummaryItem(
          'PayPal Status',
          user.isPaypalLinked ? 'Linked' : 'Not Linked',
          Icons.payment,
          color: user.isPaypalLinked ? Colors.green : Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildSummaryItem(
          'Profile Status',
          'Active',
          Icons.check_circle,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
