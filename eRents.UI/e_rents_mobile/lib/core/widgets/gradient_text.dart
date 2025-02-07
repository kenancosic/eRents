import 'package:flutter/material.dart';

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  const GradientText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          colors: [Color(0xFF917AFD), Color(0xFF6246EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(
          Rect.fromLTWH(0.0, 0.0, bounds.width, bounds.height),
        );
      },
      child: Text(
        text,
        style: (style ?? const TextStyle()).copyWith(color: Colors.white),
        textAlign: textAlign,
      ),
    );
  }
}
