import 'package:flutter/material.dart';

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
            // Background image for the entire drawer
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/city.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black54, // Darken the image for better text visibility
                  BlendMode.darken,
                ),
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Custom drawer header
                _buildCustomDrawerHeader(context),

                // Menu items with transparent background to show the image
                _buildMenuItem(Icons.payment, "Payment"),
                _buildMenuItem(Icons.flight, "My Rents"),
                _buildMenuItem(Icons.settings, "Settings"),

                const Divider(color: Colors.white30),

                _buildMenuItem(Icons.info, "Terms & Conditions"),
                _buildMenuItem(Icons.privacy_tip, "Privacy Policy"),
                _buildMenuItem(Icons.logout, "Log out", isLogout: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDrawerHeader(BuildContext context) {
    return Container(
      height: 200,
      child: Stack(
        children: [
          // Soft wavy background with 4 points
          ClipPath(
            clipper: SoftWaveClipper(),
            child: Container(
              height: 180,
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
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile picture
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 23,
                    backgroundImage: AssetImage('assets/images/user-image.png'),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Marco Jacobs",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 2,
                    ),

                    // Edit profile button
                    TextButton.icon(
                      onPressed: () {},
                      icon:
                          const Icon(Icons.edit, color: Colors.white, size: 16),
                      label: const Text(
                        "Edit profile",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {bool isLogout = false}) {
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
      onTap: () {
        // Handle menu item tap
      },
    );
  }
}

// Custom clipper for soft wavy header using 4 points
class SoftWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start at top-left
    path.moveTo(0, 0);

    // Draw line to bottom-left
    path.lineTo(0, size.height * 0.8);

    // First curve point (25% across)
    path.cubicTo(
        size.width * 0.25,
        size.height * 0.85, // First control point
        size.width * 0.25,
        size.height * 0.95, // Second control point
        size.width * 0.5,
        size.height * 0.9 // End point (50% across)
        );

    // Second curve point (to 100% across)
    path.cubicTo(
        size.width * 0.75,
        size.height * 0.85, // First control point
        size.width * 0.75,
        size.height * 0.75, // Second control point
        size.width,
        size.height * 0.8 // End point (right edge)
        );

    // Line to top-right
    path.lineTo(size.width, 0);

    // Close the path
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
