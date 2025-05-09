import 'package:flutter/material.dart';
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

/// Main application base screen that includes the navigation bar
class AppBaseScreen extends StatelessWidget {
  final Widget? child;
  final String title;
  final String currentPath;

  const AppBaseScreen({
    super.key,
    this.child,
    required this.title,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Expanded(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Title
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),

              // Main Content Area
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Always use side navigation rail layout
    return Scaffold(
      body: Row(
        children: [AppNavigationBar(currentPath: currentPath), content],
      ),
    );
  }
}
