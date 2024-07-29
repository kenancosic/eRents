import 'package:e_rents_mobile/providers/user_provider.dart';
import 'package:e_rents_mobile/services/local_storage_service.dart';
import 'package:e_rents_mobile/widgets/input_field.dart';
import 'package:e_rents_mobile/widgets/simple_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late UserProvider _userProvider;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _attemptAutoLogin();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _attemptAutoLogin() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final email = await LocalStorageService.getItem("email");
    final password = await LocalStorageService.getItem("password");

    if (email != null && password != null) {
      final loginSuccess = await userProvider.login(email, password);
      if (loginSuccess) {
        _navigateToHome();
      }
    }
  }

  Future<void> _performLogin() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (_formKey.currentState!.validate()) {
      try {
        final loginSuccess = await userProvider.login(
          _usernameController.text,
          _passwordController.text,
        );
        if (loginSuccess) {
          _navigateToHome();
        } else {
          _showErrorDialog("Invalid email or password.");
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
        reverse: true,
        controller: _scrollController,
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
                    "Sign in",
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
                          controller: _usernameController,
                          hintText: 'Email',
                          faIcon: FontAwesomeIcons.user,
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
                        const SizedBox(height: 32),
                        SimpleButton(
                          onTap: () async {
                            if (_formKey.currentState!.validate()) {
                              try {
                                var loginFlag = await _userProvider.login(
                                    _usernameController.text,
                                    _passwordController.text);
                                if (loginFlag) {
                                  context.go("/dashboard");
                                } else {
                                  if (mounted) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text("Error"),
                                          content: const Text(
                                              "Invalid email or password."),
                                          actions: [
                                            TextButton(
                                              child: const Text("Ok"),
                                              onPressed: () {
                                                if (mounted) {
                                                  Navigator.pop(context);
                                                }
                                              },
                                            )
                                          ],
                                        );
                                      },
                                    );
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text("Error"),
                                        content: Text(e.toString()),
                                        actions: [
                                          TextButton(
                                            child: const Text("Ok"),
                                            onPressed: () {
                                              if (mounted) {
                                                Navigator.pop(context);
                                              }
                                            },
                                          )
                                        ],
                                      );
                                    },
                                  );
                                }
                              }
                            }
                          },
                          bgColor: const Color(0xff4285F4),
                          textColor: Colors.white,
                          text: "Log in",
                          width: 300,
                          height: 60,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            context.go("/register");
                          },
                          child: const Text(
                              "Don't have an account? Create an Account"),
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
