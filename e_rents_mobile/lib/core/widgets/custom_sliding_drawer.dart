import 'package:e_rents_mobile/feature/profile/user_provider.dart';
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
          child: Column(
            children: [
              _buildCustomDrawerHeader(context),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 16.0, bottom: 30.0, right: 16.0),
                      child: _buildMenuItem(
                        context,
                        Icons.logout,
                        "Log out",
                        isLogout: true,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDrawerHeader(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Stack(
      children: [
        Container(
          height: 230,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF7265F0),
                Color(0xFF9C8FFF),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 50.0, left: 16.0, right: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white.withOpacity(0.8),
                child: CircleAvatar(
                  radius: 38,
                  backgroundImage:
                      const AssetImage('assets/images/user-image.png'),
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
              TextButton.icon(
                onPressed: () {
                  if (context.mounted) {
                    context.go('/profile');
                  }
                },
                icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                label: const Text(
                  "Edit profile",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ],
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
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false);
                    },
                  ),
                  TextButton(
                    child: const Text('Logout'),
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true);
                    },
                  ),
                ],
              );
            },
          );

          if (confirmLogout == true) {
            if (!context.mounted) return;
            await context.read<UserProvider>().logout();
            if (!context.mounted) return;
            context.go('/login');
          }
        } else if (title == "Payment") {
          if (!context.mounted) return;
          context.go('/profile/payment');
        } else if (title == "Settings") {
          if (!context.mounted) return;
          context.go('/profile/settings');
        }
      },
    );
  }
}
