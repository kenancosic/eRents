import 'package:e_rents_mobile/core/utils/custom_decorator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _buildDrawerHeader(),
          _buildDrawerItem(
            icon: Icons.home,
            text: 'Home',
            onTap: () => context.go('/'),
          ),
          _buildDrawerItem(
            icon: Icons.person,
            text: 'Profile',
            onTap: () => context.go('/profile'),
          ),
          _buildDrawerItem(
            icon: Icons.settings,
            text: 'Settings',
            onTap: () => context.go('/settings'),
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.info,
            text: 'About',
            onTap: () {
              // Add About navigation or action
            },
          ),
          _buildDrawerItem(
            icon: Icons.logout,
            text: 'Log Out',
            onTap: () {
              // Add Log Out action
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return UserAccountsDrawerHeader(
      decoration: CustomDecorations.gradientBoxDecoration,
      accountName: const Text(
        'Marco Jacobs',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      accountEmail: const Text(
        'marco.jacobs@example.com',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Image.asset(
            'assets/images/user-image.png', // Replace with actual image asset
            fit: BoxFit.cover,
            width: 90,
            height: 90,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required GestureTapCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      onTap: onTap,
    );
  }
}
