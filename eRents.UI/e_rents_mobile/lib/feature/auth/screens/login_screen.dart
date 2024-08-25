import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/feature/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';  // Import GoRouter

class LoginScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Sign In',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            Consumer<AuthProvider>(
              builder: (context, provider, child) {
                if (provider.state == ViewState.Busy) {
                  return const CircularProgressIndicator();
                }

                return ElevatedButton(
                  onPressed: () async {
                    bool success = await provider.login(
                      _emailController.text,
                      _passwordController.text,
                    );
                    if (success) {
                      context.go('/');  // Use GoRouter to navigate
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(provider.errorMessage ?? 'Login failed')),
                      );
                    }
                  },
                  child: const Text('Login'),
                );
              },
            ),
            TextButton(
              onPressed: () {
                context.go('/signup');  // Use GoRouter to navigate
              },
              child: const Text('Create an Account'),
            ),
            TextButton(
              onPressed: () {
                context.go('/forgot_password');  // Use GoRouter to navigate
              },
              child: Text('Forgot Password?'),
            ),
          ],
        ),
      ),
    );
  }
}
