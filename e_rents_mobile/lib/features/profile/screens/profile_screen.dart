import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_avatar.dart';
import 'package:e_rents_mobile/core/widgets/custom_dialogs.dart';
import 'package:e_rents_mobile/features/profile/providers/user_profile_provider.dart';
import 'package:e_rents_mobile/features/auth/auth_provider.dart';
import 'package:e_rents_mobile/features/home/providers/home_provider.dart';
import 'package:e_rents_mobile/features/explore/providers/property_search_provider.dart';
import 'package:e_rents_mobile/core/providers/current_user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:e_rents_mobile/core/utils/app_spacing.dart';
import 'package:e_rents_mobile/core/utils/app_colors.dart';
import 'package:e_rents_mobile/core/widgets/section_container.dart';

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
      // Refresh user profile on app resume
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
      // Clear tokens and user state via auth providers
      await context.read<AuthProvider>().logout();
      await context.read<UserProfileProvider>().logout();
      
      // Clear all cached user-specific data from other providers
      // This ensures a fresh state when a different user logs in
      context.read<CurrentUserProvider>().clearOnLogout();
      context.read<HomeProvider>().clearOnLogout();
      context.read<PropertySearchProvider>().clearOnLogout();
      
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
              // Gradient background instead of image
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.1),
                        AppColors.surfaceLight,
                      ],
                    ),
                  ),
                ),
              ),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  children: [
                    // Header Section
                    Container(
                      padding: AppSpacing.paddingV_XL,
                      child: Column(
                        children: [
                          SizedBox(height: AppSpacing.md),
                          CustomAvatar(
                            imageUrl: profileProvider.profileImageUrlOrPlaceholder,
                            size: 100,
                            onTap: _updateProfileImage,
                            showCameraIcon: true,
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            user?.name != null && user?.lastName != null
                                ? '${user!.name} ${user.lastName}'
                                : 'John Doe',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            user?.email ?? 'johnDoe@gmail.com',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content Sections
                    Expanded(
                      child: ListView(
                        padding: AppSpacing.paddingH_MD,
                        children: [
                          // Account Settings Section
                          _buildSectionCard(
                            title: 'Account Settings',
                            items: [
                              _buildListTile(
                                icon: Icons.person_outline,
                                title: 'Personal details',
                                onTap: () => context.push('/profile/details'),
                              ),
                              _buildListTile(
                                icon: Icons.lock_outline,
                                title: 'Change Password',
                                onTap: () => context.push('/profile/change-password'),
                              ),
                              _buildSwitchListTile(
                                context: context,
                                profileProvider: profileProvider,
                              ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.md),
                          // Payment & Bookings Section
                          _buildSectionCard(
                            title: 'Payment & Bookings',
                            items: [
                              _buildListTile(
                                icon: Icons.payment_outlined,
                                title: 'Payment details',
                                onTap: () => context.push('/profile/payment'),
                              ),
                              _buildListTile(
                                icon: Icons.receipt_long_outlined,
                                title: 'Invoices',
                                onTap: () => context.push('/profile/invoices'),
                              ),
                              _buildListTile(
                                icon: Icons.history,
                                title: 'Booking History',
                                onTap: () => context.push('/profile/booking-history'),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.md),
                          // Support Section
                          _buildSectionCard(
                            title: 'Support',
                            items: [
                              _buildListTile(
                                icon: Icons.help_outline,
                                title: 'FAQ',
                                onTap: () => context.push('/faq'),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.lg),
                          // Logout Button
                          CustomButton(
                            label: 'Log out',
                            icon: Icons.logout,
                            isLoading: false,
                            width: ButtonWidth.expanded,
                            backgroundColor: AppColors.error,
                            onPressed: _handleLogout,
                          ),
                          SizedBox(height: AppSpacing.xl),
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

  // Helper method to build a section card
  Widget _buildSectionCard({
    required String title,
    required List<Widget> items,
  }) {
    return SectionCard(
      title: title,
      child: Column(
        children: items,
      ),
    );
  }

  // Helper method to build a list tile
  ListTile _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textSecondary,
      ),
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
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      title: Text(
        'Make Profile Public',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
      ),
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
      secondary: Icon(
        isPublic ? Icons.visibility : Icons.visibility_off,
        color: AppColors.textPrimary,
      ),
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return Colors.grey.shade400;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary.withValues(alpha: 0.5);
        }
        return Colors.grey.shade300;
      }),
    );
  }
}
