import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/base/app_bar_config.dart';
import 'package:flutter/material.dart';

class PasswordResetConfirmationScreen extends StatelessWidget {
  const PasswordResetConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseScreen(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'A password reset email has been sent to your email address. Please check your inbox.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
