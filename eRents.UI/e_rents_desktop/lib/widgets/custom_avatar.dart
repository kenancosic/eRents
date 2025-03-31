import 'package:flutter/material.dart';

class CustomAvatar extends StatelessWidget {
  final String imageUrl;
  final double size;
  final double borderWidth;
  final VoidCallback? onTap;

  const CustomAvatar({
    super.key,
    required this.imageUrl,
    this.size = 40.0,
    this.borderWidth = 1,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF917AFD), Color(0xFF6246EA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            width: borderWidth,
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: CircleAvatar(
            backgroundImage: AssetImage(imageUrl),
            radius: 50,
          ),
        ),
      ),
    );
  }
}
