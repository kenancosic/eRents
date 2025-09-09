import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_avatar.dart';
import 'package:e_rents_mobile/core/widgets/custom_dialogs.dart';
import 'package:e_rents_mobile/features/profile/providers/user_profile_provider.dart';
import 'package:e_rents_mobile/features/auth/auth_provider.dart';
import 'package:e_rents_mobile/features/profile/widgets/paypal_settings_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize user data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProfileProvider>().initUser();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      // On returning to the app (e.g., from PayPal), refresh user profile
      context.read<UserProfileProvider>().loadCurrentUser(forceRefresh: true);
    }
  }

  // Function to pick and upload profile image
  Future<void> _updateProfileImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        // Upload image using provider
        final success = await context
            .read<UserProfileProvider>()
            .uploadProfileImage(imageFile);

        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile image')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  // Function to handle logout
  void _handleLogout() async {
    // Show confirmation dialog
    final shouldLogout = await CustomDialogs.showConfirmationDialog(
      context: context,
      title: 'Logout',
      content: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      isDestructive: true,
    );

    if (shouldLogout == true && mounted) {
      // Clear tokens and user state via both providers
      await context.read<AuthProvider>().logout();
      await context.read<UserProfileProvider>().logout();
      // Navigate to login screen
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, profileProvider, _) {
        final user = profileProvider.user;
        final isLoading = profileProvider.isLoading;

        return BaseScreen(
          showAppBar: false,
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/polygon.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  children: [
                    const SizedBox(height: 20),
                    // User profile section
                    Center(
                      child: CustomAvatar(
                        imageUrl: 'assets/images/user-image.png',
                        size: 100,
                        onTap: _updateProfileImage,
                        showCameraIcon: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user?.name != null && user?.lastName != null
                          ? '${user!.name} ${user.lastName}'
                          : 'John Doe',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      user?.email ?? 'johnDoe@gmail.com',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    Expanded(
                      child: ListView(
                        children: [
                          _buildListTile(
                            icon: Icons.person_outline,
                            title: 'Personal details',
                            onTap: () {
                              context.push('/profile/details');
                            },
                          ),
                          _buildListTile(
                            icon: Icons.lock_outline,
                            title: 'Change Password',
                            onTap: () {
                              context.push('/profile/change-password');
                            },
                          ),
                          _buildListTile(
                            icon: Icons.payment_outlined,
                            title: 'Payment details',
                            onTap: () {
                              context.push('/profile/payment');
                            },
                          ),
                          _buildListTile(
                            icon: Icons.history,
                            title: 'Booking History',
                            onTap: () {
                              context.push('/profile/booking-history');
                            },
                          ),
                          _buildSwitchListTile(
                            context: context,
                            profileProvider: profileProvider,
                          ),
                          const SizedBox(height: 20),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.0),
                            child: PaypalSettingsWidget(isEditing: true),
                          ),
                          const SizedBox(height: 20),
                          _buildListTile(
                            icon: Icons.help_outline,
                            title: 'FAQ',
                            onTap: () {
                              context.push('/faq');
                            },
                          ),
                          const Divider(),
                          const SizedBox(height: 20),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: CustomButton(
                              label: 'Log out',
                              icon: Icons.logout,
                              isLoading: false,
                              width: ButtonWidth.expanded,
                              backgroundColor: Theme.of(context).primaryColor,
                              onPressed: _handleLogout,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to build a list tile
  ListTile _buildListTile(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // Helper method to build a switch list tile for public profile
  Widget _buildSwitchListTile({
    required BuildContext context,
    required UserProfileProvider profileProvider,
  }) {
    final user = profileProvider.user;
    final bool isPublic = user?.isPublic ?? false;

    return SwitchListTile(
      title: const Text('Make Profile Public'),
      value: isPublic,
      onChanged: (bool value) async {
        // Show a confirmation dialog before changing the status
        final confirm = await CustomDialogs.showConfirmationDialog(
          context: context,
          title: value ? 'Make Profile Public?' : 'Make Profile Private?',
          content: 'Are you sure you want to ${value ? 'make your profile public' : 'make your profile private'}?',
          confirmText: 'Confirm',
        );

        if (confirm == true) {
          String? cityToSend;
          if (value) {
            // Making public: ensure city present or ask for it
            final currentCity = user?.address?.city?.trim() ?? '';
            if (currentCity.isEmpty) {
              final entered = await CustomDialogs.showInputDialog(
                context: context,
                title: 'Enter your city',
                hintText: 'City',
              );
              if ((entered ?? '').isEmpty) {
                if (mounted) {
                  CustomDialogs.showCustomSnackBar(
                    context: context,
                    message: 'City is required to make your profile public.',
                    isError: true,
                  );
                }
                return; // Abort toggle
              }
              cityToSend = entered;
            }
          }

          final success = await profileProvider.updateUserPublicStatus(value, city: cityToSend);
          if (mounted) {
            CustomDialogs.showCustomSnackBar(
              context: context,
              message: success
                  ? 'Profile status updated successfully!'
                  : 'Failed to update profile status.',
              isError: !success,
            );
          }
        }
      },
      secondary: Icon(isPublic ? Icons.visibility : Icons.visibility_off,
          color: Colors.black),
      activeColor: Theme.of(context).primaryColor,
    );
  }
}
