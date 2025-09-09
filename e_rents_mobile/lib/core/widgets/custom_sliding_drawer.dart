import 'package:e_rents_mobile/core/widgets/elevated_text_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/features/profile/providers/user_profile_provider.dart';
import 'package:e_rents_mobile/features/auth/auth_provider.dart';
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
              topRight: Radius.zero,
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/polygon.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black54,
                  BlendMode.darken,
                ),
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildCustomDrawerHeader(context),
                _buildMenuItem(context, Icons.history, "My Bookings"),
                _buildMenuItem(
                    context, Icons.person_outline, "Personal details"),
                _buildMenuItem(
                    context, Icons.payment_outlined, "Payment details"),
                _buildMenuItem(context, Icons.help_outline, "FAQ"),
                const Divider(color: Colors.white30),
                _buildMenuItem(context, Icons.logout, "Log out",
                    isLogout: true),
              ],
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
      padding: const EdgeInsets.only(
          top: 50.0, bottom: 20.0, left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            child: CircleAvatar(
              radius: 38,
              backgroundImage: const AssetImage('assets/images/user-image.png'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user?.name != null && user?.lastName != null
                ? "${user!.name} ${user.lastName}"
                : "User Name",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          ElevatedTextButton.icon(
            text: "Edit profile",
            icon: Icons.edit,
            isCompact: true,
            textColor: Colors.white,
            backgroundColor: Colors.transparent,
            onPressed: () {
              if (context.mounted) {
                context.go('/profile');
                onDrawerToggle();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title,
      {bool isLogout = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : Colors.white,
          fontWeight: isLogout ? FontWeight.bold : null,
        ),
      ),
      onTap: () async {
        if (isLogout) {
          if (!context.mounted) return;
          final bool? confirmLogout = await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
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
            // Clear tokens and user state
            await context.read<AuthProvider>().logout();
            await context.read<UserProfileProvider>().logout();
            if (!context.mounted) return;
            context.go('/login');
          }
        } else if (title == "Payment") {
          if (!context.mounted) return;
          context.go('/profile/payment');
        } else if (title == "Personal details") {
          if (!context.mounted) return;
          context.go('/profile/details');
        } else if (title == "Payment details") {
          if (!context.mounted) return;
          context.go('/profile/payment');
        } else if (title == "FAQ") {
          if (!context.mounted) return;
          context.go('/faq');
        } else if (title == "My Bookings") {
          if (!context.mounted) return;
          context.go('/profile/booking-history');
        }

        if (context.mounted) {
          onDrawerToggle();
        }
      },
    );
  }
}
