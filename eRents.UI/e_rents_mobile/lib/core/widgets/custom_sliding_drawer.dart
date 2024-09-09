import 'package:flutter/material.dart';

class CustomSlidingDrawer extends StatelessWidget {
  final AnimationController controller;
  final VoidCallback onDrawerToggle;

  const CustomSlidingDrawer({
    Key? key,
    required this.controller,
    required this.onDrawerToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define the animation for sliding the drawer
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
        child: const Drawer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text("Marco Jacobs"),
                accountEmail: Text("Edit profile"),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: AssetImage(
                    'assets/images/user-image.png',
                  ), // Replace with actual image URL
                ),
              ),
              ListTile(
                leading: Icon(Icons.payment),
                title: Text("Payment"),
              ),
              ListTile(
                leading: Icon(Icons.flight),
                title: Text("My Rents"),
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text("Settings"),
              ),
              Spacer(),
              ListTile(
                leading: Icon(Icons.info),
                title: Text("Terms & Conditions"),
              ),
              ListTile(
                leading: Icon(Icons.privacy_tip),
                title: Text("Privacy Policy"),
              ),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text("Log out"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
