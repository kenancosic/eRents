import 'package:flutter/material.dart';

class InputField extends StatefulWidget {
  final String hintText;
  final IconData? faIcon;
  final bool obscure;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final int maxLines;

  const InputField({
    super.key,
    required this.hintText,
    this.faIcon,
    required this.controller,
    this.obscure = false,
    this.validator,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Material(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                spreadRadius: 0,
                blurRadius: 5,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            maxLines: widget.maxLines,
            validator: widget.validator,
            obscureText: widget.obscure,
            textAlignVertical: TextAlignVertical.center,
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: widget.keyboardType,
            decoration: InputDecoration(
              filled: true,
              hintText: widget.hintText,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              prefixIcon: widget.faIcon != null
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 15, 0),
                      child: Icon(
                        widget.faIcon,
                        size: 20,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
