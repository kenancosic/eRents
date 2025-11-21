import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_input_field.dart';
import 'package:e_rents_mobile/features/auth/auth_provider.dart';
import 'package:e_rents_mobile/core/utils/theme.dart';
import 'package:e_rents_mobile/features/auth/widgets/auth_screen_layout.dart';
import 'package:e_rents_mobile/features/auth/widgets/auth_form_container.dart';
import 'package:e_rents_mobile/features/auth/widgets/auth_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class VerificationScreen extends StatefulWidget {
  final String email;

  const VerificationScreen({super.key, required this.email});

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
      // Verify the code with the AuthProvider
      final success = await authProvider.verifyCode(widget.email, _codeController.text);
      if (success && mounted) {
        // Navigate to the password creation screen
        context.push('/create-password?email=${widget.email}&code=${_codeController.text}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      child: _buildVerificationForm(context),
    );
  }

  Widget _buildVerificationForm(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            AuthFormContainer(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthHeader(
                      title: 'Verify Your Email',
                      subtitle:
                          'We\'ve sent a verification code to ${widget.email}. Please enter it below to continue.',
                      showLogo: false,
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Verification Code',
                        style: TextStyle(
                          fontSize: 14,
                          color: authLabelColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    CustomInputField(
                      controller: _codeController,
                      hintText: 'Enter code',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the verification code';
                        }
                        if (value.length < 6) {
                          return 'Code must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      label: 'Verify Code',
                      isLoading: authProvider.isLoading,
                      onPressed: () async {
                        await _verifyCode(authProvider);
                      },
                    ),
                    if (authProvider.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          authProvider.errorMessage,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
