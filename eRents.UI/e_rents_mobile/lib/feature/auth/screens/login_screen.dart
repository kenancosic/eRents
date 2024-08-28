import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/utils/helpers.dart';
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
      showAppBar: false,
      body:SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
             Text(
            'eRents',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 20),
          Text('Enter your username or e-mail:', style: Theme.of(context).textTheme.titleMedium),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(hintText: 'example@outlook.com'),
            ),
          const SizedBox(height: 20),
          Text('Your Password', style: Theme.of(context).textTheme.titleMedium),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                hintText: '**********',
                suffixIcon: Icon(Icons.visibility_off)),
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
                      context.go('/');
                    } else {
                      showSnackBar(context, provider.errorMessage ?? 'Login failed');
                    }
                  },
                  child: Text('Login',style: Theme.of(context).textTheme.labelSmall),
                );
              },
            ),
            TextButton(
              onPressed: () {
                context.go('/signup');
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
