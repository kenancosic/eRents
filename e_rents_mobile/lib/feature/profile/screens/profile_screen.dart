import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:e_rents_mobile/feature/profile/providers/user_detail_provider.dart';
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

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize user data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserDetailProvider>().initUser();
    });
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
            .read<UserDetailProvider>()
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
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          CustomOutlinedButton.compact(
            label: 'Cancel',
            isLoading: false,
            onPressed: () => context.pop(false),
          ),
          CustomButton.compact(
            label: 'Logout',
            isLoading: false,
            onPressed: () => context.pop(true),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await context.read<UserDetailProvider>().logout();
      // Navigate to login screen
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserDetailProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.user;
        final isLoading = userProvider.state == ViewState.busy;

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
                    GestureDetector(
                      onTap: _updateProfileImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: const AssetImage(
                                'assets/images/user-image.png'), // Default image
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
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
                            icon: Icons.payment_outlined,
                            title: 'Payment details',
                            onTap: () {
                              context.push('/profile/payment');
                            },
                          ),
                          _buildListTile(
                            icon: Icons.home_work_outlined,
                            title: 'Accommodation Preferences',
                            onTap: () {
                              context
                                  .push('/profile/accommodation-preferences');
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
                            userProvider: userProvider,
                          ),
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
    required UserDetailProvider userProvider,
  }) {
    final user = userProvider.user;
    final bool isPublic = user?.isPublic ?? false;

    return SwitchListTile(
      title: const Text('Make Profile Public'),
      value: isPublic,
      onChanged: (bool value) async {
        // Show a confirmation dialog before changing the status
        final confirm = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text(
                  value ? 'Make Profile Public?' : 'Make Profile Private?'),
              content: Text(
                  'Are you sure you want to ${value ? 'make your profile public' : 'make your profile private'}?'),
              actions: <Widget>[
                CustomOutlinedButton.compact(
                  label: 'Cancel',
                  isLoading: false,
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false); // User cancelled
                  },
                ),
                CustomButton.compact(
                  label: 'Confirm',
                  isLoading: false,
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true); // User confirmed
                  },
                ),
              ],
            );
          },
        );

        if (confirm == true) {
          final success = await userProvider.updateUserPublicStatus(value);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success
                    ? 'Profile status updated successfully!'
                    : 'Failed to update profile status.'),
              ),
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
