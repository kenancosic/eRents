import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/elevated_text_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/features/auth/auth_provider.dart';

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
    return BaseScreen(
      body: _buildVerificationForm(context),
    );
  }

  Widget _buildVerificationForm(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Form(
          key: _formKey,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App logo or icon
                  const Icon(
                    Icons.lock,
                    size: 80,
                    color: Color(0xFF7065F0),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  const Text(
                    'Verify Your Email',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    'We\'ve sent a verification code to ${widget.email}. Please enter it below to continue.',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Code input field
                  TextFormField(
                    controller: _codeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Verification Code',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF7065F0)),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
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
                  
                  // Verify button
                  ElevatedTextButton(
                    text: 'Verify Code',
                    onPressed: () async {
                      await _verifyCode(authProvider);
                    },
                    isLoading: authProvider.isLoading,
                  ),
                  
                  // Error message
                  if (authProvider.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        authProvider.errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Back button
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text(
                      'Back',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
