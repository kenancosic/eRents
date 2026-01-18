import 'package:flutter/material.dart';

/// Reusable auth screen layout to eliminate duplication across auth screens
/// Used by: LoginScreen, SignupScreen, ForgotPasswordScreen
class AuthScreenLayout extends StatelessWidget {
  final Widget formWidget;
  final String? customBackgroundImage;
  final String? customPolygonImage;
  final Widget? customSideContent;

  const AuthScreenLayout({
    super.key,
    required this.formWidget,
    this.customBackgroundImage,
    this.customPolygonImage,
    this.customSideContent,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 800;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background image (always present, but may be obscured by form on narrow screens)
          Positioned.fill(
            child: Image.asset(
              customBackgroundImage ?? 'assets/images/apartment.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Content layout - either Row (wide) or Column (narrow)
          if (isWideScreen)
            _buildWideLayout(context, screenSize)
          else
            _buildNarrowLayout(context),
        ],
      ),
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
                image: AssetImage(
                  customPolygonImage ?? 'assets/images/polygon.jpg',
                ),
                fit: BoxFit.cover,
              ),
            ),
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: formWidget,
                ),
              ),
            ),
          ),
        ),

        // Side content column - takes 60% of screen width
        Expanded(
          flex: 6,
          child: SizedBox(height: double.infinity, child: customSideContent),
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
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: formWidget,
          ),
        ),
      ),
    );
  }
}
