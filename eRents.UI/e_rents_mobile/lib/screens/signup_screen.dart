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
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _userType;

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _performSignUp() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (_formKey.currentState!.validate()) {
      try {
        // Sign up logic (e.g., userProvider.signUp(...))
        // Example:
        final signUpSuccess = await userProvider.signUp(
          _firstnameController.text,
          _lastnameController.text,
          _emailController.text,
          _passwordController.text,
          _userType,
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
  }

  void _navigateToHome() {
    if (context.mounted) {
      context.go("/dashboard");
    }
  }

  void _showErrorDialog(String message) {
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
                          controller: _lastnameController,
                          hintText: 'Lastname',
                          faIcon: FontAwesomeIcons.user,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter your lastname';
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
                          value: _userType,
                          hint: const Text("Choose your user-type"),
                          items: <String>['User', 'Admin']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _userType = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a user type';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        SimpleButton(
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
                          child: const Text(
                              "Already have an account? Log in"),
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
