import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final dynamic label;
  final bool isLoading;
  final Future<void> Function()? onPressed;
  final Color backgroundColor;
  final double height;
  final double fontSize;
  final double borderRadius;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF7065F0), // Default button color
    this.height = 45, // Default button height
    this.fontSize = 16, // Default font size
    this.borderRadius = 12, // Default border radius
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor, // Customizable background color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius), // Customizable corners
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16), // Add some padding
    );

    final textLabel = label is String
        ? Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          )
        : label;

    return SizedBox(
      height: height,
      child: icon != null
          ? ElevatedButton.icon(
              onPressed: isLoading || onPressed == null ? null : () async => await onPressed!(),
              style: buttonStyle,
              icon: isLoading ? const SizedBox.shrink() : Icon(icon, size: 18),
              label: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : textLabel,
            )
          : ElevatedButton(
              onPressed: isLoading || onPressed == null ? null : () async => await onPressed!(),
              style: buttonStyle,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : textLabel,
            ),
    );
  }
}
