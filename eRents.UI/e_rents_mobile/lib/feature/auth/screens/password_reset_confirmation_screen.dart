import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:flutter/material.dart';


class PasswordResetConfirmationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Reset Password',
      body: const Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'A password reset email has been sent to your email address. Please check your inbox.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
