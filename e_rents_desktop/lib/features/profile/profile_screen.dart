import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/features/profile/providers/profile_provider.dart';
import 'package:e_rents_desktop/features/profile/widgets/profile_header_widget.dart';
import 'package:e_rents_desktop/features/profile/widgets/personal_info_form_widget.dart';
import 'package:e_rents_desktop/widgets/common/section_card.dart';
import 'package:e_rents_desktop/utils/date_utils.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final user = profileProvider.currentUser;

        if (profileProvider.isLoading && user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (profileProvider.error != null && user == null) {
          return Center(child: Text('Error: ${profileProvider.error}'));
        }

        if (user == null) {
          return const Center(child: Text('No user data found.'));
        }

        return const _ProfileScreenContent();
      },
    );
  }
}

class _ProfileScreenContent extends StatelessWidget {
  const _ProfileScreenContent();

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final isEditing = profileProvider.isEditing;

    final personalInfoFormKey = GlobalKey<FormState>();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Section (simplified - no image upload logic tied to provider)
            ProfileHeaderWidget(
              onImageUploaded: (path) async {
                // Image upload functionality simplified: placeholder or handled externally
                // The widget itself might provide a pick, but actual upload is not in provider
                // For academic submission, this can be a dummy function or removed.
                // Or you can add it to the profile provider if it uses multipart
                // For now, no action.
              },
            ),

            const SizedBox(height: 32),

            // Main Content
            LayoutBuilder(
              builder: (context, constraints) {
                // Simplified layout for all screen widths
                return Column(
                  children: [
                    _buildPersonalInfoCard(
                      context,
                      isEditing,
                      personalInfoFormKey,
                    ),
                    const SizedBox(height: 24),
                    _buildAccountSummaryCard(context),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Action Buttons
            if (isEditing)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: profileProvider.toggleEditing,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Consumer<ProfileProvider>(
                      builder: (context, provider, child) {
                        return ElevatedButton(
                          onPressed: provider.isLoading // Using general isLoading
                              ? null
                              : () async {
                                  if (personalInfoFormKey.currentState?.validate() ?? false) {
                                    final success = await provider.saveChanges();
                                    if (context.mounted) {
                                      if (success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Profile updated successfully!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(provider.error ?? 'Failed to update profile.'), // Using general error
                                            backgroundColor: Theme.of(context).colorScheme.error,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: provider.isLoading // Using general isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Save Changes'),
                        );
                      },
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Logout Button
            Center(
              child: SizedBox(
                width: 200,
                child: OutlinedButton(
                  onPressed: () async {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    await authProvider.logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(
    BuildContext context,
    bool isEditing,
    GlobalKey<FormState> personalInfoFormKey,
  ) {
    return SectionCard(
      title: 'Personal Information',
      titleIcon: Icons.person,
      child: PersonalInfoFormWidget(
        isEditing: isEditing,
        formKey: personalInfoFormKey,
      ),
    );
  }

  Widget _buildAccountSummaryCard(BuildContext context) {
    final user = context.watch<ProfileProvider>().currentUser;
    if (user == null) {
      return const Center(child: Text('Profile information not available'));
    }

    return SectionCard(
      title: 'Account Summary',
      titleIcon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryItem(
            context,
            'Account Type',
            user.role.toString().split('.').last.toUpperCase(),
            Icons.account_circle,
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            context,
            'Member Since',
            AppDateUtils.formatPrimary(user.createdAt),
            Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          // PayPal status removed for simplification
          _buildSummaryItem(
            context,
            'Profile Status',
            'Active',
            Icons.check_circle,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
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
