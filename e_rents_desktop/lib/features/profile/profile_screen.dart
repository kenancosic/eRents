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
    _tabController = TabController(length: 3, vsync: this);

    // Initialize the provider
    _profileProvider = ProfileProvider(
      Provider.of<ProfileService>(context, listen: false),
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
      // Updated _saveProfile logic
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

      final success = await _profileProvider.updateProfile(
        _profileProvider.currentUser!,
      );

      if (mounted) {
        // Check if widget is still in the tree
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _isEditing = false; // Exit editing mode
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
                    textAlign:
                        TextAlign.center, // Added for better text display
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
                    boxShadow: const [
                      BoxShadow(
                        color: const Color.fromRGBO(0, 0, 0, 0.1),
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
                      Tab(icon: Icon(Icons.payment), text: 'Payments'),
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: ElevatedButton.icon(
                                onPressed: _saveProfile,
                                icon: const Icon(Icons.save),
                                label: const Text('Save Personal Info'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                ),
                              ),
                            ),
                        ],
                      ),

                      SingleChildScrollView(
                        child: ChangePasswordWidget(
                          isEditing: _isEditing,
                          formKey: _passwordFormKey,
                        ),
                      ),

                      PaypalSettingsWidget(isEditing: _isEditing),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
