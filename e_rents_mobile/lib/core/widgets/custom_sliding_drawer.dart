import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_avatar.dart';
import 'package:e_rents_mobile/features/profile/providers/user_profile_provider.dart';
import 'package:e_rents_mobile/features/auth/auth_provider.dart';
import 'package:e_rents_mobile/core/utils/app_colors.dart';
import 'package:e_rents_mobile/core/utils/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CustomSlidingDrawer extends StatelessWidget {
  final AnimationController controller;
  final VoidCallback onDrawerToggle;

  const CustomSlidingDrawer({
    super.key,
    required this.controller,
    required this.onDrawerToggle,
  });

  @override
  Widget build(BuildContext context) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0), // Start hidden to the left
      end: const Offset(0.0, 0.0), // End at the normal position
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));

    final double drawerWidth = MediaQuery.of(context).size.width * 0.7;

    return SlideTransition(
      position: slideAnimation,
      child: SizedBox(
        width: drawerWidth, // Set the drawer width
        child: Drawer(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.05),
                  AppColors.surfaceLight,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildCustomDrawerHeader(context),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      children: [
                        SizedBox(height: AppSpacing.sm),
                        _buildMenuItem(context, Icons.person_outline, "Profile", '/profile'),
                        _buildMenuItem(context, Icons.calendar_today_outlined, "My Bookings", '/profile/booking-history'),
                        _buildMenuItem(context, Icons.payment_outlined, "Payment Methods", '/profile/payment'),
                        _buildMenuItem(context, Icons.help_outline, "Help & FAQ", '/faq'),
                        SizedBox(height: AppSpacing.md),
                        _buildLogoutButton(context),
                        SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDrawerHeader(BuildContext context) {
    final userProvider = Provider.of<UserProfileProvider>(context);
    final user = userProvider.user;

    return Container(
      margin: EdgeInsets.all(AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CustomAvatar(
            imageUrl: userProvider.profileImageUrlOrPlaceholder,
            size: 56,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name != null && user?.lastName != null
                      ? "${user!.name} ${user.lastName}"
                      : "User Name",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  user?.email ?? "user@example.com",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String route) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onTap: () {
          if (context.mounted) {
            context.go(route);
            onDrawerToggle();
          }
        },
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.logout,
            color: Colors.red,
            size: 20,
          ),
        ),
        title: const Text(
          'Log out',
          style: TextStyle(
            color: Colors.red,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () async {
          if (!context.mounted) return;
          final bool? confirmLogout = await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text('Confirm Logout'),
                content: const Text('Are you sure you want to log out?'),
                actions: <Widget>[
                  CustomOutlinedButton.compact(
                    label: 'Cancel',
                    isLoading: false,
                    onPressed: () {
                      dialogContext.canPop() ? dialogContext.pop(false) : null;
                    },
                  ),
                  CustomButton.compact(
                    label: 'Logout',
                    isLoading: false,
                    onPressed: () {
                      dialogContext.canPop() ? dialogContext.pop(true) : null;
                    },
                  ),
                ],
              );
            },
          );

          if (confirmLogout == true) {
            if (!context.mounted) return;
            await context.read<AuthProvider>().logout();
            await context.read<UserProfileProvider>().logout();
            if (!context.mounted) return;
            context.go('/login');
          }

          if (context.mounted) {
            onDrawerToggle();
          }
        },
      ),
    );
  }
}
