import 'package:flutter/material.dart';

/// Semi-transparent container for auth forms with clean, modern styling
class AuthFormContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final EdgeInsets? padding;

  const AuthFormContainer({
    super.key,
    required this.child,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? MediaQuery.of(context).size.width * 0.85,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((255 * 0.95).round()),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: child,
    );
  }
}
