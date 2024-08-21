import 'package:flutter/material.dart';
import '../../providers/base_provider.dart';
import '../../routes/base_screen.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../utils/helpers.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Login',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            Consumer<AuthProvider>(
              builder: (context, provider, child) {
                if (provider.state == ViewState.Busy) {
                  return CircularProgressIndicator();
                }

                return ElevatedButton(
                  onPressed: () async {
                    bool success = await provider.login(
                      _emailController.text,
                      _passwordController.text,
                    );
                    if (success) {
                      Navigator.pushReplacementNamed(context, '/');
                    } else {
                      showSnackBar(context, provider.errorMessage ?? 'Login failed');
                    }
                  },
                  child: Text('Login'),
                );
              },
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: Text('Sign Up'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/forgot_password');
              },
              child: Text('Forgot Password?'),
            ),
          ],
        ),
      ),
    );
  }
}
