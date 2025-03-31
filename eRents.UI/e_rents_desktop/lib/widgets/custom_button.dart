import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final dynamic label;
  final bool isLoading;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final double height;
  final double fontSize;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF7065F0), // Default button color
    this.height = 45, // Default button height
    this.fontSize = 16, // Default font size
    this.borderRadius = 12, // Default border radius
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed, // Disable button if loading
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, height), // Full width, adjustable height
        backgroundColor: backgroundColor, // Customizable background color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius), // Customizable corners
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : label is String ? Text(
              label, // Dynamic label
              style: TextStyle(
                color: Colors.white, // Text color
                fontSize: fontSize, // Customizable font size
                fontWeight: FontWeight.bold, // Bold text
              ),
            )
          : label,
    );
  }
}
