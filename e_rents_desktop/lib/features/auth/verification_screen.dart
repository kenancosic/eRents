import 'package:e_rents_desktop/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:e_rents_desktop/features/auth/widgets/auth_screen_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  /// If true, this is signup email verification flow (auto-login after).
  /// If false, this is password reset flow (navigate to create-password).
  final bool isSignupVerification;

  const VerificationScreen({
    super.key,
    required this.email,
    this.isSignupVerification = true, // Default to signup flow
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode(AuthProvider authProvider) async {
    if (_formKey.currentState?.validate() ?? false) {
      if (widget.isSignupVerification) {
        // Signup flow: verify email and auto-login
        final success = await authProvider.verifyEmailAndLogin(
          widget.email,
          _codeController.text,
        );
        if (success && mounted) {
          // Navigate to home/dashboard after successful signup verification
          context.go('/');
        }
      } else {
        // Password reset flow: verify code and navigate to create password
        final success = await authProvider.verifyCode(
          widget.email,
          _codeController.text,
        );
        if (success && mounted) {
          // Navigate to the password creation screen for password reset
          context.push('/create-password?email=${widget.email}&code=${_codeController.text}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      formWidget: _buildVerificationForm(context),
    );
  }

  Widget _buildVerificationForm(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isSignupVerification ? 'Verify Your Email' : 'Enter Reset Code',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                widget.isSignupVerification
                    ? 'We\'ve sent a verification code to your email address. Please enter it below to complete your registration.'
                    : 'We\'ve sent a password reset code to your email address. Please enter it below to continue.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the verification code';
                  }
                  if (value.length < 6) {
                    return 'Code must be at least 6 characters';
                  }
                  return null;
                },
                enabled: !authProvider.isLoading,
              ),
              const SizedBox(height: 24),
              CustomButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () async {
                        await _verifyCode(authProvider);
                      },
                label: 'Verify Code',
                isLoading: authProvider.isLoading,
              ),
              if (authProvider.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    authProvider.error!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        );
      },
    );
  }
}