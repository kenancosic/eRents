import 'package:flutter/material.dart';

class ErrorDisplay extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;

  const ErrorDisplay({
    Key? key,
    required this.errorMessage,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            errorMessage,
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text("Retry"),
            ),
        ],
      ),
    );
  }
}
