import 'package:e_rents_mobile/providers/user_provider.dart';
import 'package:e_rents_mobile/services/local_storage_service.dart';
import 'package:e_rents_mobile/widgets/input_field.dart';
import 'package:e_rents_mobile/widgets/simple_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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

  @override
  void initState() {
    super.initState();
    _attemptAutoLogin();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
        scrollDirection: Axis.vertical,
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(0, 120, 0, 80),
              decoration: const BoxDecoration(
                color: Colors.pinkAccent,
                image: DecorationImage(
                  image: AssetImage("assets/images/background.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
                padding: const EdgeInsets.only(left: 20, top: 100),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () {
                      context.go("/welcome");
                    },
                    child: const Icon(Icons.arrow_back_ios_rounded),
                  ),
                )),
            SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: buildLoginScreen(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> buildLoginScreen() {
    return [
      const SizedBox(height: 50),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: SvgPicture.asset("assets/images/logo.svg")),
        ],
      ),
      const SizedBox(height: 50),
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
                    !RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                        .hasMatch(value)) {
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
                    !RegExp(r'^(?=.*?[!@#\$\-&*~]).{5,}$').hasMatch(value)) {
                  return 'Password should be longer than 5 characters.\nPassword should contain at least one special character';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      const SizedBox(
        height: 50,
      ),
      SimpleButton(
        onTap: () async {
          if (_formKey.currentState!.validate()) {
            try {
              var loginFlag = await _userProvider.login(
                  _usernameController.text, _passwordController.text);
              if (loginFlag) {
                context.go("/dashboard");
              } else {
                showDialog(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                          title: const Text("Error"),
                          content: const Text("Invalid email or password."),
                          actions: [
                            TextButton(
                              child: const Text("Ok"),
                              onPressed: () => Navigator.pop(context),
                            )
                          ],
                        ));
              }
            } catch (e) {
              showDialog(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                        title: const Text("Error"),
                        content: Text(e.toString()),
                        actions: [
                          TextButton(
                            child: const Text("Ok"),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ));
            }
          }
        },
        bgColor: const Color(0xffEAAD5F),
        textColor: Colors.white,
        text: "Log in",
        width: 300,
        height: 70,
      ),
      const SizedBox(
        height: 20,
      )
    ];
  }
}
