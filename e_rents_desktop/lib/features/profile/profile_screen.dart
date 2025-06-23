import 'package:e_rents_desktop/features/profile/state/profile_screen_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/profile/providers/profile_state_provider.dart';
import 'package:e_rents_desktop/features/profile/widgets/profile_header_widget.dart';
import 'package:e_rents_desktop/features/profile/widgets/personal_info_form_widget.dart';
import 'package:e_rents_desktop/features/profile/widgets/change_password_widget.dart';
import 'package:e_rents_desktop/features/profile/widgets/paypal_settings_widget.dart';
import 'package:e_rents_desktop/widgets/common/section_card.dart';
import 'package:e_rents_desktop/utils/date_utils.dart';
import 'package:e_rents_desktop/features/profile/state/change_password_form_state.dart';
import 'package:e_rents_desktop/features/profile/state/personal_info_form_state.dart';
import 'package:e_rents_desktop/features/profile/state/paypal_settings_form_state.dart';
import 'package:e_rents_desktop/repositories/profile_repository.dart';
import 'package:e_rents_desktop/providers/app_state_providers.dart'; // To get repository provider
import 'package:e_rents_desktop/models/user.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We use a Consumer here to get the initial user data and the repository.
    // This also triggers a rebuild if the user data changes.
    return Consumer<ProfileStateProvider>(
      builder: (context, profileState, child) {
        final user = profileState.currentUser;

        if (profileState.isLoading && user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (profileState.error != null && user == null) {
          return Center(child: Text('Error: ${profileState.error?.message}'));
        }

        if (user == null) {
          // This can happen briefly before the user is loaded.
          // Or if there's a serious issue.
          return const Center(child: Text('No user data found.'));
        }

        // We use MultiProvider to set up the form-specific states,
        // which are local to the profile screen.
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ProfileScreenState()),
            ChangeNotifierProvider(create: (_) => PersonalInfoFormState(user)),
            ChangeNotifierProvider(create: (_) => ChangePasswordFormState()),
            ChangeNotifierProvider(
              create: (_) => PaypalSettingsFormState(user),
            ),
          ],
          child: const _ProfileScreenContent(),
        );
      },
    );
  }
}

class _ProfileScreenContent extends StatelessWidget {
  const _ProfileScreenContent();

  @override
  Widget build(BuildContext context) {
    final screenState = context.watch<ProfileScreenState>();
    final isEditing = screenState.isEditing;

    final personalInfoFormState = context.read<PersonalInfoFormState>();
    final personalInfoFormKey = GlobalKey<FormState>();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Section
            ProfileHeaderWidget(
              isEditing: isEditing,
              onEditPressed: screenState.toggleEditing,
              onCancelPressed: isEditing ? screenState.cancelEditing : null,
              onImageUploaded: (path) async {
                final personalInfoState = context.read<PersonalInfoFormState>();
                final updatedUser = await personalInfoState.uploadProfileImage(
                  path,
                );
                if (updatedUser != null && context.mounted) {
                  // Update all providers with the new user data
                  context.read<ProfileStateProvider>().updateUserState(
                    updatedUser,
                  );
                  context.read<PaypalSettingsFormState>().updateUser(
                    updatedUser,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile image updated!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to upload image: ${personalInfoState.errorMessage ?? 'Unknown error'}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 32),

            // Main Content
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 800) {
                  return Column(
                    children: _buildFormCards(
                      context,
                      isEditing,
                      personalInfoFormKey,
                    ),
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildPersonalInfoCard(
                            context,
                            isEditing,
                            personalInfoFormKey,
                          ),
                          const SizedBox(height: 24),
                          _buildSecurityCard(context, isEditing),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildPaymentCard(context, isEditing),
                          const SizedBox(height: 24),
                          _buildAccountSummaryCard(context),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Action Buttons
            if (isEditing)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          screenState.isSaving
                              ? null
                              : () async {
                                if (personalInfoFormKey.currentState
                                        ?.validate() ==
                                    true) {
                                  screenState.setSaving(true);
                                  final updatedUser =
                                      await personalInfoFormState.saveChanges();
                                  screenState.setSaving(false);

                                  if (context.mounted) {
                                    if (updatedUser != null) {
                                      // Update the main profile provider
                                      context
                                          .read<ProfileStateProvider>()
                                          .updateUserState(updatedUser);

                                      // Update the other form states with the new user data
                                      context
                                          .read<PaypalSettingsFormState>()
                                          .updateUser(updatedUser);

                                      screenState.onSaveCompleted();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Profile updated successfully!',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to update profile: ${personalInfoFormState.errorMessage ?? 'Unknown error'}',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                      icon:
                          screenState.isSaving
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.save),
                      label: Text(
                        screenState.isSaving ? 'Saving...' : 'Save Changes',
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
                          screenState.isSaving
                              ? null
                              : screenState.cancelEditing,
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
  }

  List<Widget> _buildFormCards(
    BuildContext context,
    bool isEditing,
    GlobalKey<FormState> personalInfoFormKey,
  ) {
    return [
      _buildPersonalInfoCard(context, isEditing, personalInfoFormKey),
      const SizedBox(height: 24),
      _buildSecurityCard(context, isEditing),
      const SizedBox(height: 24),
      _buildPaymentCard(context, isEditing),
      const SizedBox(height: 24),
      _buildAccountSummaryCard(context),
    ];
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

  Widget _buildSecurityCard(BuildContext context, bool isEditing) {
    return SectionCard(
      title: 'Security & Password',
      titleIcon: Icons.security,
      child: ChangePasswordWidget(isEditing: isEditing),
    );
  }

  Widget _buildPaymentCard(BuildContext context, bool isEditing) {
    return SectionCard(
      title: 'Payment Settings',
      titleIcon: Icons.payment,
      child: PaypalSettingsWidget(isEditing: isEditing),
    );
  }

  Widget _buildAccountSummaryCard(BuildContext context) {
    final user = context.watch<ProfileStateProvider>().currentUser;
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
          _buildSummaryItem(
            context,
            'PayPal Status',
            user.isPaypalLinked ? 'Linked' : 'Not Linked',
            Icons.payment,
            color: user.isPaypalLinked ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 12),
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
