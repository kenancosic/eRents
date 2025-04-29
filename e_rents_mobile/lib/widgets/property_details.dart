import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_mobile/feature/auth/auth_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  DateTime? _selectedDateOfBirth;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),  // Default date
      firstDate: DateTime(1900),    // Earliest selectable date
      lastDate: DateTime.now(),     // Latest selectable date
    );
    if (picked != null && picked != _selectedDateOfBirth){
      setState(() {
        _selectedDateOfBirth = picked;
      });
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),  // Added const
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),  // Added const
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),  // Added const
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),  // Added const
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),  // Added const
              obscureText: true,
            ),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Confirm Password'),  // Added const
              obscureText: true,
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),  // Added const
            ),
            ListTile(
              title: Text(_selectedDateOfBirth == null
                  ? 'Date of Birth'
                  : 'Date of Birth: ${_selectedDateOfBirth!.toLocal()}'.split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),  // Added const
              onTap: () => _selectDate(context),
            ),
            TextField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(labelText: 'Phone Number'),  // Added const
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'First Name'),  // Added const
            ),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),  // Added const
            ),
            const SizedBox(height: 20),  // Added const
            Consumer<AuthProvider>(
              builder: (context, provider, child) {
                if (provider.state == ViewState.Busy) {
                  return const CircularProgressIndicator();  // Added const
                }

                return ElevatedButton(
                  onPressed: () async {
                    if (_passwordController.text != _confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Passwords do not match')),  // Added const
                      );
                      return;
                    }

                    bool success = await provider.register({
                      'username': _usernameController.text,
                      'email': _emailController.text,
                      'password': _passwordController.text,
                      'confirmPassword': _confirmPasswordController.text,
                      'address': _addressController.text,
                      'dateOfBirth': _selectedDateOfBirth?.toIso8601String(),
                      'phoneNumber': _phoneNumberController.text,
                      'name': _nameController.text,
                      'lastName': _lastNameController.text,
                    });

                    if (success) {
                      context.go('/home');  // Navigate to home on success
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(provider.errorMessage ?? 'Registration failed')),
                      );
                    }
                  },
                  child: const Text('Sign Up'),  // Added const
                );
              },
            ),
            TextButton(
              onPressed: () {
                context.go('/login');  // Navigate back to login
              },
              child: const Text('Back to Login'),  // Added const
            ),
          ],
        ),
      ),
    );
  }
}
