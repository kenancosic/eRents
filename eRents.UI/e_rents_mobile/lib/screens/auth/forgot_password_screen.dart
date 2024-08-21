import 'package:e_rents_mobile/providers/base_provider.dart';
import 'package:flutter/material.dart';
import '../../routes/base_screen.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../utils/helpers.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Forgot Password',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            Consumer<AuthProvider>(
              builder: (context, provider, child) {
                if (provider.state == ViewState.Busy) {
                  return const CircularProgressIndicator();
                }

                return ElevatedButton(
                  onPressed: () async {
                    bool success = await provider.forgotPassword(_emailController.text);
                    if (!mounted) return; // Check if widget is still mounted
                    if (success) {
                      showSnackBar(context, 'Password reset link sent!');
                      Navigator.pop(context);
                    } else {
                      showSnackBar(context, provider.errorMessage ?? 'Failed to send reset link');
                    }
                  },
                  child: const Text('Reset Password'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
