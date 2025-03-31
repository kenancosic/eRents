import 'package:flutter/material.dart';
import 'dart:ui';

/// A specialized base screen for authentication features that provides
/// a two-column layout: one column for forms and another for supporting content.
class AuthBaseScreen extends StatelessWidget {
  final Widget formContent;
  final String? backgroundImage;
  final Widget? customSideContent;
  final String title;
  final bool showBackButton;
  final Color? backgroundColor;
  final double breakpointWidth;

  const AuthBaseScreen({
    super.key,
    required this.formContent,
    this.backgroundImage,
    this.customSideContent,
    this.title = '',
    this.showBackButton = true,
    this.backgroundColor,
    this.breakpointWidth = 800,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > breakpointWidth;

    return Scaffold(
      backgroundColor:
          backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background image (always present, but may be obscured by form on narrow screens)
          if (backgroundImage != null)
            Positioned.fill(child: _buildBackgroundImage(context)),

          // Content layout - either Row (wide) or Column (narrow)
          if (isWideScreen)
            _buildWideLayout(context, screenSize)
          else
            _buildNarrowLayout(context),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage(BuildContext context) {
    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Image.asset(backgroundImage!, fit: BoxFit.cover),
        ),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context, Size screenSize) {
    return Row(
      children: [
        // Form column - takes 40% of screen width
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/polygon.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: formContent,
              ),
            ),
          ),
        ),

        // Side content column - takes 60% of screen width
        Expanded(
          flex: 6,
          child: Container(
            height: double.infinity,
            child:
                customSideContent ??
                (backgroundImage == null
                    ? _buildDefaultSideContent(context)
                    : const SizedBox.shrink()),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: formContent,
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultSideContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.apartment, size: 120, color: Colors.black54),
          const SizedBox(height: 24),
          Text(
            'eRents Property Management',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Manage your properties with ease',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

/// A stateful version of AuthBaseScreen for screens that need to manage state
class StatefulAuthBaseScreen extends StatefulWidget {
  final Widget formContent;
  final String? backgroundImage;
  final Widget? customSideContent;
  final String title;
  final bool showBackButton;
  final Color? backgroundColor;
  final double breakpointWidth;

  const StatefulAuthBaseScreen({
    super.key,
    required this.formContent,
    this.backgroundImage,
    this.customSideContent,
    this.title = '',
    this.showBackButton = true,
    this.backgroundColor,
    this.breakpointWidth = 800,
  });

  @override
  State<StatefulAuthBaseScreen> createState() => _StatefulAuthBaseScreenState();
}

class _StatefulAuthBaseScreenState extends State<StatefulAuthBaseScreen> {
  @override
  Widget build(BuildContext context) {
    return AuthBaseScreen(
      formContent: widget.formContent,
      backgroundImage: widget.backgroundImage,
      customSideContent: widget.customSideContent,
      title: widget.title,
      showBackButton: widget.showBackButton,
      backgroundColor: widget.backgroundColor,
      breakpointWidth: widget.breakpointWidth,
    );
  }
}
