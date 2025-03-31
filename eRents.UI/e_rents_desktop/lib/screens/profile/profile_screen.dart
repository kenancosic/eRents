import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: 'Profile',
      currentPath: '/profile',
      content: const Center(child: Text('Profile Screen Content')),
    );
  }
}
