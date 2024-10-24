import 'package:flutter/material.dart';

class CustomInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final bool hasSuffixIcon;
  final IconData? suffixIcon;
  final TextInputType keyboardType;
   final String? Function(String?)? validator;

  const CustomInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.hasSuffixIcon = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.validator
  });
@override
  _CustomInputFieldState createState() => _CustomInputFieldState();
}
class _CustomInputFieldState extends State<CustomInputField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  // Toggle password visibility
  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
       margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3), // Semi-transparent background
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscureText,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        style: const TextStyle(
          color: Colors.white, // Input text color
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.7), // Hint text color
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.white.withOpacity(0.8), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          errorStyle: const TextStyle(
            color: Colors.redAccent,
            fontSize: 12,
          ),
          suffixIcon: widget.hasSuffixIcon
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  onPressed: _toggleObscureText,
                )
              : null,
        ),
      ),
    );     
      
    //   TextField(
    //     controller: controller,
    //     obscureText: obscureText,
    //     keyboardType: keyboardType,
    //     decoration: InputDecoration(
    //       hintText: hintText,
    //       hintStyle: const TextStyle(
    //         color: Color(0xFF9CA3AF), // Grey hint color
    //       ),
    //       fillColor: Colors.transparent,
    //       filled: true,
    //       contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12), // Padding inside field
    //       border: InputBorder.none, // No default border
    //       suffixIcon: hasSuffixIcon
    //           ? Icon(suffixIcon, color: Colors.grey) // Grey eye icon for password
    //           : null,
    //     ),
    //     style: const TextStyle(
    //       color: Color(0xFF6B7280), // Text color matching the hint
    //       fontSize: 16,
    //     ),
    //   ),
    // );
  }
}
