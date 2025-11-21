import 'package:e_rents_mobile/core/widgets/custom_sliding_drawer.dart';
import 'package:e_rents_mobile/core/utils/app_spacing.dart';
import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // REMOVE if NavigationProvider is no longer needed here
// import 'package:go_router/go_router.dart'; // REMOVE if context.go is no longer needed for _onItemTapped
// import 'navigation_provider.dart'; // REMOVE if NavigationProvider is no longer needed here

class BaseScreen extends StatefulWidget {
  final Widget body;
  final bool showAppBar;
  final bool useSlidingDrawer;
  // final bool showBottomNavBar; // REMOVED
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  final PreferredSizeWidget? appBar;
  // final Widget? bottomNavigationBarWidget; // REMOVED

  // NEW: Design system parameters
  final EdgeInsets? bodyPadding;
  final bool enableScroll;
  final bool applyScreenPadding;

  const BaseScreen({
    super.key,
    required this.body,
    this.showAppBar = true,
    this.useSlidingDrawer = false,
    // this.showBottomNavBar = true, // REMOVED
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.appBar,
    // this.bottomNavigationBarWidget, // REMOVED
    this.bodyPadding,
    this.enableScroll = false,
    this.applyScreenPadding = false,
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

  // void _onItemTapped(BuildContext context, int index) { // REMOVED
  //   Provider.of<NavigationProvider>(context, listen: false).updateIndex(index);
  //   // Navigate to the corresponding screen.
  //   switch (index) {
  //     case 0:
  //       context.go('/'); // Navigate to Home.
  //       break;
  //     case 1:
  //       context.go('/explore'); // Navigate to Explore.
  //       break;
  //     case 2:
  //       context.go('/chatRoom'); // Navigate to Chat.
  //       break;
  //     case 3:
  //       context.go('/saved'); // Navigate to Saved.
  //       break;
  //     case 4:
  //       context.go('/profile'); // Navigate to Profile.
  //       break;
  //   }
  // }

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

  // NEW: Build body with optional padding and scrolling
  Widget _buildBody() {
    Widget content = widget.body;

    // Apply standard padding if requested
    if (widget.applyScreenPadding) {
      content = Padding(
        padding: widget.bodyPadding ?? AppSpacing.screenPadding,
        child: content,
      );
    }

    // Enable scroll if requested
    if (widget.enableScroll) {
      content = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: content,
      );
    }

    return content;
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
      body: _buildBody(),
      // bottomNavigationBar: widget.bottomNavigationBarWidget ?? // REMOVED
      //     (widget.showBottomNavBar // REMOVED
      //         ? Consumer<NavigationProvider>( // REMOVED
      //             builder: (context, navigationProvider, child) { // REMOVED
      //               return CustomBottomNavigationBar( // REMOVED
      //                 currentIndex: navigationProvider.currentIndex, // REMOVED
      //                 onTap: (index) => _onItemTapped(context, index), // REMOVED
      //               ); // REMOVED
      //             }, // REMOVED
      //           ) // REMOVED
      //         : null), // REMOVED
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
