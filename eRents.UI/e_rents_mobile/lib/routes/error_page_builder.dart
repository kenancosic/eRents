import 'package:flutter/material.dart';

class ErrorPageBuilder extends StatelessWidget {
  final String errorMessage;

  ErrorPageBuilder({required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Error'),
      ),
      body: Center(
        child: Text(errorMessage, style: TextStyle(color: Colors.red, fontSize: 18)),
      ),
    );
  }
}
