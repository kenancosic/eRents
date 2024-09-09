import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title:'Profile',
      body: Column(
        children: [
          const SizedBox(height: 20),
          // User profile section
          CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage('assets/images/user-image.png'), // Replace with actual image
          ),
          const SizedBox(height: 10),
          const Text(
            'John Doe',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'johnDoe@gmail.com',
            style: TextStyle(
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
                    // Navigate to personal details screen
                  },
                ),
                _buildListTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    // Navigate to settings screen
                  },
                ),
                _buildListTile(
                  icon: Icons.payment_outlined,
                  title: 'Payment details',
                  onTap: () {
                    // Navigate to payment details screen
                  },
                ),
                _buildListTile(
                  icon: Icons.help_outline,
                  title: 'FAQ',
                  onTap: () {
                    // Navigate to FAQ screen
                  },
                ),
                const Divider(),
                _buildListTile(
                  icon: Icons.swap_horiz_outlined,
                  title: 'Switch to landlord',
                  onTap: () {
                    // Switch to landlord mode
                  },
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      backgroundColor: Theme.of(context).primaryColor, // Change the color based on your theme
                    ),
                    onPressed: () {
                      // Handle log out functionality
                    },
                    child: const Text(
                      'Log out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build a list tile
  ListTile _buildListTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
