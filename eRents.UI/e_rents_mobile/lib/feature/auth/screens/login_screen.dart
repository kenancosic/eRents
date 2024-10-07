import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/utils/helpers.dart';
import 'package:e_rents_mobile/feature/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/BaseScreen.png', // Your custom background image path
              fit: BoxFit.fill, // Ensures the image covers the whole screen
            ),
          ),
          // Foreground content (form)
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0), // Add padding to the content
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SvgPicture.asset('assets/images/Logo.svg', height: 100, width: 100),
                  const SizedBox(height: 20),
                  Text('Enter your username or e-mail:', style: Theme.of(context).textTheme.titleMedium),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'example@outlook.com',
                      fillColor: Colors.grey[200],
                      filled: true, // Ensures the fill color is shown
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Your Password', style: Theme.of(context).textTheme.titleMedium),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      hintText: '**********',
                      suffixIcon: const Icon(Icons.visibility_off),
                      fillColor: Colors.grey[200],
                      filled: true, // Ensures the fill color is shown
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
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
                          context.go('/');
                        },
                        child: Text(
                          'Login',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
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
                      context.go('/forgot_password');
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
