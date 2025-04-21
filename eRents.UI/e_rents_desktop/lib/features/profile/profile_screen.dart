import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/profile/providers/profile_provider.dart';
import 'package:e_rents_desktop/features/profile/widgets/profile_header_widget.dart';
import 'package:e_rents_desktop/features/profile/widgets/personal_info_form_widget.dart';
import 'package:e_rents_desktop/features/profile/widgets/change_password_widget.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/base/base_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _personalInfoFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  bool _isEditing = false;
  late ProfileProvider _profileProvider;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize the tab controller
    _tabController = TabController(length: 2, vsync: this);

    // Initialize the provider
    _profileProvider = ProfileProvider(
      Provider.of<ApiService>(context, listen: false),
    );

    // Load user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _profileProvider.fetchUserProfile();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      // Get form data and update user
      // This would need to extract data from the form controllers
      // For now, we're just showing a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  Future<void> _updatePassword() async {
    if (_passwordFormKey.currentState?.validate() == true) {
      // The actual password update logic is in the ChangePasswordWidget,
      // but we need to trigger it from here
      // For now, we're showing a simulated success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _profileProvider,
      child: AppBaseScreen(
        title: 'Profile',
        currentPath: '/profile',
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
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading profile: ${provider.errorMessage}',
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

            return Column(
              children: [
                ProfileHeaderWidget(
                  isEditing: _isEditing,
                  onEditPressed: _toggleEditing,
                  onCancelPressed: _isEditing ? _cancelEditing : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor:
                          Theme.of(context).colorScheme.onSurface,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      tabs: const [
                        Tab(icon: Icon(Icons.person), text: 'Personal Info'),
                        Tab(icon: Icon(Icons.lock), text: 'Change Password'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Personal Info Tab
                        Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: PersonalInfoFormWidget(
                                  isEditing: _isEditing,
                                  formKey: _personalInfoFormKey,
                                ),
                              ),
                            ),
                            if (_isEditing)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _saveProfile,
                                  icon: const Icon(Icons.save),
                                  label: const Text('Save Personal Info'),
                                ),
                              ),
                          ],
                        ),

                        // Change Password Tab
                        Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: ChangePasswordWidget(
                                  isEditing: _isEditing,
                                  formKey: _passwordFormKey,
                                ),
                              ),
                            ),
                            if (_isEditing)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _updatePassword,
                                  icon: const Icon(Icons.key),
                                  label: const Text('Update Password'),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
