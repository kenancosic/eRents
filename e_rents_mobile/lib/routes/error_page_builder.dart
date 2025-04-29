import 'package:flutter/material.dart';

class ErrorPageBuilder extends StatelessWidget {
  final String errorMessage;

  const ErrorPageBuilder({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 18)),
      ),
    );
  }
}
