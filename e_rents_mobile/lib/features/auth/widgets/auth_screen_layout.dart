import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/base/base_screen.dart';

/// Shared layout for authentication screens with clean background
class AuthScreenLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const AuthScreenLayout({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      showAppBar: false,
      useSlidingDrawer: false,
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background image without blur
          Positioned.fill(
            child: Image.asset(
              'assets/images/appartment.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Subtle overlay for depth
          
          // Content
          Positioned.fill(
            child: SingleChildScrollView(
              padding: padding ??
                  EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 60.0,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
                  ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
