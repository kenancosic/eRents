import 'package:e_rents_mobile/core/utils/custom_decorator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SlidingDrawerScreen extends StatefulWidget {
  final String title;
  final Widget body;

  const SlidingDrawerScreen({
    Key? key,
    required this.title,
    required this.body,
  }) : super(key: key);

  @override
  _SlidingDrawerScreenState createState() => _SlidingDrawerScreenState();
}

class _SlidingDrawerScreenState extends State<SlidingDrawerScreen> {
  bool _isDrawerOpen = false;

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main Content
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            left: _isDrawerOpen ? 250.0 : 0.0,  // Adjust this value for the drawer width
            right: _isDrawerOpen ? -250.0 : 0.0, // Adjust this value for the drawer width
            top: 0.0,
            bottom: 0.0,
            child: Material(
              elevation: 8.0,
              color: Colors.white,
              child: Column(
                children: [
                  AppBar(
                    title: Text(widget.title),
                    leading: IconButton(
                      icon: Icon(Icons.menu),
                      onPressed: _toggleDrawer,
                    ),
                  ),
                  Expanded(child: widget.body),
                ],
              ),
            ),
          ),

          // Sliding Drawer
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            left: _isDrawerOpen ? 0.0 : -250.0, // Adjust this value for the drawer width
            top: 0.0,
            bottom: 0.0,
            child: Container(
              width: 250.0, // Adjust the width as needed
              child: Drawer(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
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
              ),
            ),
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
