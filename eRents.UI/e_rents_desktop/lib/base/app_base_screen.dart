import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/widgets/app_navigation_bar.dart';

/// A base screen that provides common functionality for all screens in the application.
/// This includes responsive layout handling for desktop, standard padding, and common UI elements.
class BaseScreen extends StatelessWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final PreferredSizeWidget? appBar;

  const BaseScreen({
    super.key,
    required this.child,
    this.title = '',
    this.actions,
    this.showBackButton = true,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
    this.floatingActionButton,
    this.drawer,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar ?? _buildAppBar(context),
      body: _buildBody(context),
      backgroundColor:
          backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      floatingActionButton: floatingActionButton,
      drawer: drawer,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(title),
      automaticallyImplyLeading: showBackButton,
      actions: actions,
      elevation: 0.5,
    );
  }

  Widget _buildBody(BuildContext context) {
    // For desktop applications, we might want to add some padding and max width constraints
    // to ensure the content doesn't stretch too wide on large screens
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(padding: const EdgeInsets.all(16.0), child: child),
      ),
    );
  }
}

/// A stateful version of BaseScreen for screens that need to manage state
class StatefulBaseScreen extends StatefulWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final PreferredSizeWidget? appBar;

  const StatefulBaseScreen({
    super.key,
    required this.child,
    this.title = '',
    this.actions,
    this.showBackButton = true,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
    this.floatingActionButton,
    this.drawer,
    this.appBar,
  });

  @override
  State<StatefulBaseScreen> createState() => _StatefulBaseScreenState();
}

class _StatefulBaseScreenState extends State<StatefulBaseScreen> {
  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: widget.title,
      actions: widget.actions,
      showBackButton: widget.showBackButton,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      backgroundColor: widget.backgroundColor,
      floatingActionButton: widget.floatingActionButton,
      drawer: widget.drawer,
      appBar: widget.appBar,
      child: widget.child,
    );
  }
}

class AppBaseScreen extends StatelessWidget {
  final Widget? child;
  final String title;
  final String currentPath;
  final double breakpointWidth;
  final Widget? content;

  const AppBaseScreen({
    super.key,
    this.child,
    required this.title,
    required this.currentPath,
    this.breakpointWidth = 1200,
    this.content,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > breakpointWidth;

    return Scaffold(
      appBar: isWideScreen ? AppNavigationBar(currentPath: currentPath) : null,
      body: Row(
        children: [
          if (!isWideScreen) AppNavigationBar(currentPath: currentPath),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: content ?? child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final String label;
  final IconData icon;
  final String path;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.path,
  });
}
