// import 'dart:ui'; // Import this for ImageFilter

import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/utils/theme.dart';

class CustomInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final bool hasSuffixIcon;
  final IconData? suffixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool isDark;
  final double height;

  const CustomInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.hasSuffixIcon = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.isDark = false,
    this.height = 40,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Colors
    final Color backgroundColor = widget.isDark
        ? Colors.white.withAlpha((255 * 0.2).round())
        : Colors.white;

    final Color textColor = widget.isDark ? Colors.white : textPrimaryColor;

    final Color hintColor = widget.isDark
        ? Colors.white.withAlpha((255 * 0.7).round())
        : textSecondaryColor;

    final Color borderColor = widget.isDark
        ? Colors.white.withAlpha((255 * 0.5).round())
        : Colors.grey[300]!;

    final Color focusedBorderColor = widget.isDark
        ? Colors.white.withAlpha((255 * 0.8).round())
        : primaryColor;

    final Color iconColor = widget.isDark
        ? Colors.white.withAlpha((255 * 0.7).round())
        : Colors.grey[500]!;

    // Dimensions
    final double fontSize = widget.height * 0.35;
    final double iconSize = widget.height * 0.4;
    final double borderRadius = widget.height * 0.2;

    // Directly return the TextFormField with styling
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: widget.height,
        child: TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          textAlignVertical: TextAlignVertical.center,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: hintColor,
              fontSize: fontSize,
            ),
            isDense: true,
            filled: true,
            fillColor: backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: borderColor, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: borderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                width: 1,
                color: Colors.red.withAlpha((255 * 0.7).round()),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                width: 1.5,
                color: Colors.red.withAlpha((255 * 0.7).round()),
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                width: 1,
                color: Colors.red.withAlpha((255 * 0.7)
                    .round()), // Assuming disabled looks like error, or use grey
              ),
            ),
            errorStyle: TextStyle(
              color: Colors.redAccent,
              fontSize: fontSize * 0.75,
            ),
            suffixIcon: widget.hasSuffixIcon
                ? IconButton(
                    icon: Icon(
                      widget.suffixIcon ??
                          (_obscureText
                              ? Icons.visibility_off
                              : Icons.visibility),
                      color: iconColor,
                      size: iconSize,
                    ),
                    onPressed: widget.obscureText ? _toggleObscureText : null,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: BoxConstraints(
                      minWidth: widget.height * 0.8,
                      minHeight: widget.height * 0.8,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
