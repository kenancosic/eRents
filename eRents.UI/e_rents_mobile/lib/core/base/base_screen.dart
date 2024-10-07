import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_bottom_navigation_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_sliding_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'navigation_provider.dart';

class BaseScreen extends StatefulWidget {
  final String title;
  final Widget body;
  final bool showAppBar;
  final bool useSlidingDrawer;

  const BaseScreen({
    Key? key,
    required this.title,
    required this.body,
    this.showAppBar = true,
    this.useSlidingDrawer = true,
  }) : super(key: key);

  @override
  _BaseScreenState createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> with SingleTickerProviderStateMixin {
  late AnimationController _drawerController;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    if (_drawerController.isDismissed) {
      _drawerController.forward();
    } else {
      _drawerController.reverse();
    }
  }

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
        context.go('/chatRoom'); // Navigate to Chat
        break;
      case 3:
        context.go('/saved'); // Navigate to Saved
        break;
      case 4:
        context.go('/profile'); // Navigate to Profile
        break;
    }
  }

  // Method to handle swipe gestures for the drawer
  GestureDetector _buildGestureDetector(BuildContext context, Widget child) {
    if (!widget.useSlidingDrawer) return GestureDetector(child: child); // If sliding drawer is not used, just return the child.

    final drawerWidth = MediaQuery.of(context).size.width * 0.7;
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        // Update the drawerController based on horizontal drag distance
        _drawerController.value += details.primaryDelta! / drawerWidth;
      },
      onHorizontalDragEnd: (details) {
        // Check the position of the drawer when drag ends
        if (_drawerController.value > 0.5) {
          // If more than 50% of the drawer is open, snap it fully open
          _drawerController.forward();
        } else {
          // If less than 50% of the drawer is open, snap it closed
          _drawerController.reverse();
        }
      },
      child: child,
    );
  }

  // Method to build the sliding drawer and overlay
  Widget _buildSlidingDrawer() {
    if (!widget.useSlidingDrawer) return const SizedBox.shrink(); // If sliding drawer is not used, return an empty widget.

    return Stack(
      children: [
        CustomSlidingDrawer(
          controller: _drawerController,
          onDrawerToggle: _toggleDrawer,
        ),
        if (_drawerController.value > 0) // Show overlay if the drawer is at least partially open
          GestureDetector(
            onTap: _toggleDrawer, // Close drawer on tap outside
            child: Container(
              color: Colors.black.withOpacity(0.5), // Semi-transparent overlay
            ),
          ),
      ],
    );
  }

  // Method to build the app bar and body
  Widget _buildAppBarAndBody() {
    final drawerWidth = MediaQuery.of(context).size.width * 0.7;
    final slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(drawerWidth / MediaQuery.of(context).size.width, 0.0),
    ).animate(CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeInOut,
    ));

    return AnimatedBuilder(
      animation: _drawerController,
      builder: (context, child) {
        return Transform.translate(
          offset: widget.useSlidingDrawer
              ? Offset(slideAnimation.value.dx * MediaQuery.of(context).size.width, 0)
              : Offset.zero, // Only apply the translation when sliding drawer is used
          child: Column(
            children: [
              if (widget.showAppBar)
                CustomAppBar(
                  title: widget.title,
                  leading: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: _toggleDrawer,
                  ),
                ),
              Expanded(child: widget.body),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: _buildGestureDetector(
          context,
          Stack(
            children: [
              if (widget.useSlidingDrawer) 
                _buildSlidingDrawer(), // Only build drawer if it's being used
              _buildAppBarAndBody(),
            ],
          ),
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
