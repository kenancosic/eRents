import 'package:flutter/material.dart';

/// A base screen that provides common functionality for standalone screens.
/// This includes responsive layout handling for desktop, standard padding, and common UI elements.
/// Use this for modal dialogs, overlays, or any screen that needs to be displayed independently
/// without the main app navigation.
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
