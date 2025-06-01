import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/profile/providers/profile_provider.dart';
import 'package:e_rents_desktop/features/profile/widgets/profile_header_widget.dart';
import 'package:e_rents_desktop/features/profile/widgets/personal_info_form_widget.dart';
import 'package:e_rents_desktop/features/profile/widgets/change_password_widget.dart';
import 'package:e_rents_desktop/features/profile/widgets/paypal_settings_widget.dart';
import 'package:e_rents_desktop/services/profile_service.dart';
import 'package:e_rents_desktop/base/base_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _personalInfoFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  bool _isEditing = false;
  late ProfileProvider _profileProvider;

  @override
  void initState() {
    super.initState();
    // Initialize the provider
    _profileProvider = ProfileProvider(
      Provider.of<ProfileService>(context, listen: false),
    );

    // Load user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _profileProvider.fetchUserProfile();
    });
  }

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
    _profileProvider.fetchUserProfile();
  }

  Future<void> _saveProfile() async {
    if (_personalInfoFormKey.currentState?.validate() == true) {
      if (_profileProvider.currentUser == null) {
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

      final success = await _profileProvider.updateProfile(
        _profileProvider.currentUser!,
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
                'Failed to update profile: ${_profileProvider.errorMessage ?? 'Unknown error'}',
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
    return ChangeNotifierProvider.value(
      value: _profileProvider,
      child: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          if (provider.state == ViewState.Busy) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.state == ViewState.Error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading profile: ${provider.errorMessage ?? 'Unknown error'}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchUserProfile(),
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
                            _buildSectionCard(
                              title: 'Personal Information',
                              icon: Icons.person,
                              child: PersonalInfoFormWidget(
                                isEditing: _isEditing,
                                formKey: _personalInfoFormKey,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Security Section
                            _buildSectionCard(
                              title: 'Security & Password',
                              icon: Icons.security,
                              child: ChangePasswordWidget(
                                isEditing: _isEditing,
                                formKey: _passwordFormKey,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Payment Settings Section
                            _buildSectionCard(
                              title: 'Payment Settings',
                              icon: Icons.payment,
                              child: PaypalSettingsWidget(
                                isEditing: _isEditing,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Account Summary Section
                            _buildSectionCard(
                              title: 'Account Summary',
                              icon: Icons.info_outline,
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
                                _buildSectionCard(
                                  title: 'Personal Information',
                                  icon: Icons.person,
                                  child: PersonalInfoFormWidget(
                                    isEditing: _isEditing,
                                    formKey: _personalInfoFormKey,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Security Section
                                _buildSectionCard(
                                  title: 'Security & Password',
                                  icon: Icons.security,
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
                                _buildSectionCard(
                                  title: 'Payment Settings',
                                  icon: Icons.payment,
                                  child: PaypalSettingsWidget(
                                    isEditing: _isEditing,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Account Summary Section
                                _buildSectionCard(
                                  title: 'Account Summary',
                                  icon: Icons.info_outline,
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
                            onPressed: _saveProfile,
                            icon: const Icon(Icons.save),
                            label: const Text('Save All Changes'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _cancelEditing,
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel Changes'),
                            style: OutlinedButton.styleFrom(
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
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSummary(user) {
    if (user == null) {
      return const Text('No user data available');
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
          size: 16,
          color:
              color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
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
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
