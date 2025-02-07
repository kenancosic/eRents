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
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [
            Color(0xFF917AFD),
            Color(0xFF6246EA)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          ),
         
        ),
        child: const Padding(padding: EdgeInsets.all(2),
        child: CircleAvatar(
          backgroundImage: AssetImage('assets/images/user-image.png'),
          radius: 50,
        ),),
      ),
    );
  }
}
