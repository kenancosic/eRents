import 'package:e_rents_mobile/core/widgets/custom_avatar.dart';
import 'package:e_rents_mobile/core/widgets/custom_bottom_navigation_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_sliding_drawer.dart';
import 'package:e_rents_mobile/core/widgets/sliver_custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'navigation_provider.dart';

class BaseScreen extends StatefulWidget {
  final String? title;
  final Widget? locationWidget;
  final Widget body;
  final bool showAppBar;
  final bool useSlidingDrawer;
  final bool showBottomNavBar;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  // New parameters to accommodate the updated app bar
  final bool showBackButton;
  final VoidCallback? onBackButtonPressed;
  final bool showFilterButton;
  final VoidCallback? onFilterButtonPressed;
  final ValueChanged<String>? onSearchChanged;
  final String? searchHintText;
  final List<Widget>? appBarActions;

  const BaseScreen({
    super.key,
    this.title,
    this.locationWidget,
    required this.body,
    this.showAppBar = true,
    this.useSlidingDrawer = false,
    this.showBottomNavBar = true,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.showBackButton = false,
    this.onBackButtonPressed,
    this.showFilterButton = false,
    this.onFilterButtonPressed,
    this.onSearchChanged,
    this.searchHintText,
    this.appBarActions,
  });

  @override
  _BaseScreenState createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen>
    with SingleTickerProviderStateMixin {
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
  Widget _buildSlidingDrawer() {
    if (!widget.useSlidingDrawer) return const SizedBox.shrink();

    return Stack(
      children: [
        CustomSlidingDrawer(
          controller: _drawerController,
          onDrawerToggle: _toggleDrawer,
        ),
        if (_drawerController.value > 0)
          GestureDetector(
            onTap: _toggleDrawer,
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
      ],
    );
  }

  // Builds the app bar (using NestedScrollView with SliverCustomAppBar) and body.
  Widget _buildAppBarAndBody() {
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

    return AnimatedBuilder(
      animation: _drawerController,
      builder: (context, child) {
        return Transform.translate(
          offset: widget.useSlidingDrawer
              ? Offset(
                  slideAnimation.value.dx * MediaQuery.of(context).size.width,
                  0,
                )
              : Offset.zero,
          child: widget.showAppBar
              ? NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverCustomAppBar(
                        // If using a sliding drawer and no back button, show the avatar which toggles the drawer.
                        avatar: widget.useSlidingDrawer && !widget.showBackButton
                            ? CustomAvatar(
                                imageUrl: '',
                                borderWidth: 0.5,
                                onTap: _toggleDrawer,
                              )
                            : null,
                        // Location widget (bottom row in the flexible area).
                        locationWidget: widget.locationWidget,
                        // Use the first action as the notification icon if available.
                        notification: widget.appBarActions != null &&
                                widget.appBarActions!.isNotEmpty
                            ? widget.appBarActions!.first
                            : null,
                        // Pass search bar parameters.
                        onSearchChanged: widget.onSearchChanged,
                        searchHintText: widget.searchHintText,
                        showFilterIcon: widget.showFilterButton,
                        onFilterIconPressed: widget.onFilterButtonPressed,
                      )
                    ];
                  },
                  body: widget.body,
                )
              : widget.body,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor:
            widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
        body: _buildGestureDetector(
          context,
          Stack(
            children: [
              if (widget.useSlidingDrawer) _buildSlidingDrawer(),
              _buildAppBarAndBody(),
            ],
          ),
        ),
        bottomNavigationBar: widget.showBottomNavBar
            ? Consumer<NavigationProvider>(
                builder: (context, navigationProvider, child) {
                  return CustomBottomNavigationBar(
                    currentIndex: navigationProvider.currentIndex,
                    onTap: (index) => _onItemTapped(context, index),
                  );
                },
              )
            : null,
      ),
    );
  }
}
