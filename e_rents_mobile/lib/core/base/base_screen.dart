import 'package:e_rents_mobile/core/widgets/custom_bottom_navigation_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_sliding_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'navigation_provider.dart';

class BaseScreen extends StatefulWidget {
  final Widget body;
  final bool showAppBar;
  final bool useSlidingDrawer;
  final bool showBottomNavBar;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBarWidget;

  const BaseScreen({
    super.key,
    required this.body,
    this.showAppBar = true,
    this.useSlidingDrawer = false,
    this.showBottomNavBar = true,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.appBar,
    this.bottomNavigationBarWidget,
  });

  @override
  BaseScreenState createState() => BaseScreenState();
}

class BaseScreenState extends State<BaseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _drawerController;

  // Add a static 'of' method
  static BaseScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<BaseScreenState>();
  }

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

  // Make this method public
  void toggleDrawer() {
    if (_drawerController.isDismissed) {
      _drawerController.forward();
    } else {
      _drawerController.reverse();
    }
  }

  void _onItemTapped(BuildContext context, int index) {
    Provider.of<NavigationProvider>(context, listen: false).updateIndex(index);
    // Navigate to the corresponding screen.
    switch (index) {
      case 0:
        context.go('/'); // Navigate to Home.
        break;
      case 1:
        context.go('/explore'); // Navigate to Explore.
        break;
      case 2:
        context.go('/chatRoom'); // Navigate to Chat.
        break;
      case 3:
        context.go('/saved'); // Navigate to Saved.
        break;
      case 4:
        context.go('/profile'); // Navigate to Profile.
        break;
    }
  }

  // Wraps the child with a gesture detector if sliding drawer is used.
  GestureDetector _buildGestureDetector(BuildContext context, Widget child) {
    if (!widget.useSlidingDrawer) return GestureDetector(child: child);

    final drawerWidth = MediaQuery.of(context).size.width * 0.7;
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        _drawerController.value += details.primaryDelta! / drawerWidth;
      },
      onHorizontalDragEnd: (details) {
        if (_drawerController.value > 0.5) {
          _drawerController.forward();
        } else {
          _drawerController.reverse();
        }
      },
      child: child,
    );
  }

  // Builds the sliding drawer and overlay.
  Widget _buildSlidingDrawerContent() {
    return CustomSlidingDrawer(
      controller: _drawerController,
      onDrawerToggle: toggleDrawer, // Use the public method
    );
  }

  @override
  Widget build(BuildContext context) {
    final PreferredSizeWidget? effectiveAppBar =
        widget.showAppBar ? widget.appBar : null;

    Widget scaffoldContent = Scaffold(
      backgroundColor:
          widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      appBar: effectiveAppBar,
      body: widget.body,
      bottomNavigationBar: widget.bottomNavigationBarWidget ??
          (widget.showBottomNavBar
              ? Consumer<NavigationProvider>(
                  builder: (context, navigationProvider, child) {
                    return CustomBottomNavigationBar(
                      currentIndex: navigationProvider.currentIndex,
                      onTap: (index) => _onItemTapped(context, index),
                    );
                  },
                )
              : null),
    );

    if (widget.useSlidingDrawer) {
      final drawerWidth = MediaQuery.of(context).size.width * 0.7;
      final slideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset(drawerWidth / MediaQuery.of(context).size.width, 0.0),
      ).animate(
        CurvedAnimation(
          parent: _drawerController,
          curve: Curves.easeInOut,
        ),
      );

      return SafeArea(
        child: Stack(
          children: [
            _buildSlidingDrawerContent(),
            AnimatedBuilder(
              animation: _drawerController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    slideAnimation.value.dx * MediaQuery.of(context).size.width,
                    0,
                  ),
                  child: child,
                );
              },
              child: _buildGestureDetector(context, scaffoldContent),
            ),
            if (_drawerController.value > 0)
              GestureDetector(
                onTap: toggleDrawer, // Use the public method
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: double.infinity,
                  color: Colors.black
                      .withAlpha((255 * 0.5 * _drawerController.value).round()),
                ),
              ),
          ],
        ),
      );
    } else {
      return SafeArea(child: scaffoldContent);
    }
  }
}
