import 'dart:html';

import 'package:e_rents_mobile/widgets/InputField.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool progress = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    setState(() {
      progress = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      padding: const EdgeInsets.fromLTRB(0, 120, 0, 80),
      decoration: const BoxDecoration(
        image: DecorationImage(
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover),
      ),
      child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: _buildLoginPage()),
    ));
  }

  List<Widget> _buildLoginPage() {
    return [
      Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 30),
          child: GestureDetector(
            onTap: () {
              context.go("/welcome");
            },
            child: const Icon(
              Icons.arrow_back_ios_rounded,
            ),
          ),
        ),
      ),
      Center(child: SvgPicture.asset("assets/images/logo.svg")),
      const SizedBox(height: 50),
      Expanded(
        flex: 1,
        child: SizedBox(
          width: 500,
          child: Form(
            key: formKey,
            child: Column(children: [
              InputField(
                controller: _usernameController,
                hintText: 'Email',
                iconPath: FontAwesomeIcons.user,
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
                iconPath: 'assets/icons/Password.svg',
                obscure: true,
                validator: (value) {
                  if (value!.isEmpty ||
                      !RegExp(r'^(?=.*?[!@#\$\-&*~]).{5,}$').hasMatch(value)) {
                    return 'Password should be longer then 5 characters.\nPassword should contain at least one special character';
                  }
                  return null;
                },
              ),
            ]),
          ),
        ),
      ),
      SimpleButton(
        onTap: () async {
          if (formKey.currentState!.validate()) {
            try {
              var loginFlag = await _agencyProvider.login(
                  _usernameController.text, _passwordController.text);
              if (loginFlag) {
                context.go("/dashboard");
              } else {
                showDialog(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                          title: const Text("Error"),
                          content: Text("Invalid email or password."),
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
    ];
  }
}
