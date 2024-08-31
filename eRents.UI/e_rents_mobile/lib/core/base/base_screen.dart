import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_bottom_navigation_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_sliding_drawer.dart';
import 'package:e_rents_mobile/feature/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigation_provider.dart';
import 'package:go_router/go_router.dart';

class BaseScreen extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showAppBar;
  final bool enableDrawer; // Add a flag to control the drawer

  const BaseScreen({
    super.key,
    required this.title,
    required this.body,
    this.showAppBar = true,
    this.enableDrawer = false, // Default drawer to be disabled
  });

  void _onItemTapped(BuildContext context, int index) {
    Provider.of<NavigationProvider>(context, listen: false).updateIndex(index);

    // Navigate to the corresponding screen
    switch (index) {
      case 0:
        context.go('/'); // Navigate to Home
        break;
      case 1:
        context.go('/explore'); // Navigate to Explore
        break;
      case 2:
        context.go('/chat'); // Navigate to Chat
        break;
      case 3:
        context.go('/saved'); // Navigate to Saved
        break;
      case 4:
        context.go('/profile'); // Navigate to Profile
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: showAppBar ? CustomAppBar(title: title) : null,
        drawer: enableDrawer ? const SlidingDrawerScreen(title: 'eRents', body: HomeScreen()) : null, // Drawer only on the home page
        body: GestureDetector(
          onPanUpdate: (details) {
            if (details.delta.dx > 0 && enableDrawer) {
              // Open drawer if swiped right on the home page
              Scaffold.of(context).openDrawer();
            }
          },
          child: body,
        ),
        bottomNavigationBar: Consumer<NavigationProvider>(
          builder: (context, navigationProvider, child) {
            return CustomBottomNavigationBar(
              currentIndex: navigationProvider.currentIndex,
              onTap: (index) => _onItemTapped(context, index),
            );
          },
        ),
      ),
    );
  }
}
