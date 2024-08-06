import 'package:e_rents_mobile/providers/user_provider.dart';
import 'package:e_rents_mobile/widgets/input_field.dart';
import 'package:e_rents_mobile/widgets/simple_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _userRoles = [];
  String? _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserRoles();
  }

  Future<void> _fetchUserRoles() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      List<dynamic> roles = await userProvider.fetchUserRoles();
      if (mounted) {
        setState(() {
          _userRoles = roles.cast<Map<String, dynamic>>();
          if (roles.isNotEmpty) {
            _selectedRole = roles[0]['name'];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to load user roles.');
      }
    }
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _surnameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }


  Future<void> _performSignUp() async {
    setState(() {
    _isLoading = true;
  });
    if (_formKey.currentState!.validate()) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      final signUpSuccess = await userProvider.signUp(
        _firstnameController.text,
        _surnameController.text,
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
        _selectedRole,
      );
      if (signUpSuccess) {
        _navigateToHome();
      } else {
        _showErrorDialog("Failed to sign up. Please try again.");
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }
  setState(() {
    _isLoading = false;
  });
}
  void _navigateToHome() {
    if (mounted) {
      context.go("/dashboard");
    }
  }
   void _showErrorDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text("Ok"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height / 3,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/background.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SvgPicture.asset(
                        "assets/images/HouseLogo.svg",
                        height: 40,
                        width: 40,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "eRents",
                        style: TextStyle(
                          height: 0.8,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff222244),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Sign up",
                    style: TextStyle(
                      fontSize: 24,
                      color: Color(0xff222244),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        InputField(
                          controller: _firstnameController,
                          hintText: 'Firstname',
                          faIcon: FontAwesomeIcons.user,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter your firstname';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        InputField(
                          controller: _surnameController,
                          hintText: 'Surname',
                          faIcon: FontAwesomeIcons.user,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter your Surname/Last name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        InputField(
                          controller: _usernameController,
                          hintText: 'Username',
                          faIcon: FontAwesomeIcons.user,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter your username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        InputField(
                          controller: _emailController,
                          hintText: 'Email',
                          faIcon: FontAwesomeIcons.envelope,
                          validator: (value) {
                            if (value!.isEmpty ||
                                !RegExp(
                                  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                                ).hasMatch(value)) {
                              return 'Please use a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        InputField(
                          controller: _passwordController,
                          hintText: 'Password',
                          faIcon: FontAwesomeIcons.lock,
                          obscure: true,
                          validator: (value) {
                            if (value!.isEmpty ||
                                !RegExp(r'^(?=.*?[!@#\$\-&*~]).{5,}$')
                                    .hasMatch(value)) {
                              return 'Password should be longer than 5 characters.\nPassword should contain at least one special character';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        InputField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirm Password',
                          faIcon: FontAwesomeIcons.lock,
                          obscure: true,
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          hint: const Text("Choose your user role"),
                          items: _userRoles
                              .map((role) => DropdownMenuItem<String>(
                                    value: role['name'] as String,
                                    child: Text(role['name']),
                                  ))
                              .toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedRole = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a user role';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        _isLoading
                        ? CircularProgressIndicator()
                         : SimpleButton(
                            onTap: _performSignUp,
                            bgColor: const Color(0xff4285F4),
                            textColor: Colors.white,
                            text: "Sign up",
                            width: 300,
                            height: 60,
                          ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            context.go("/login");
                          },
                          child: const Text("Already have an account? Log in"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
