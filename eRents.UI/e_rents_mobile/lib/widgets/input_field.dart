import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class InputField extends StatefulWidget {
  final String hintText;
  final IconData? faIcon;
  final bool obscure;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const InputField(
      {super.key,
      required this.hintText,
      this.faIcon,
      required this.controller,
      this.obscure = false,
      this.validator});

  @override
  // ignore: no_logic_in_create_state
  State<InputField> createState() => _InputFieldState(
      hintText: hintText,
      faIcon: faIcon,
      obscure: obscure,
      controller: controller);
}

class _InputFieldState extends State<InputField> {
  String hintText;
  IconData? faIcon;
  bool obscure;
  TextEditingController controller;

  _InputFieldState(
      {required this.hintText,
      required this.faIcon,
      this.obscure = false,
      required this.controller});
  @override
  Widget build(BuildContext context) {
    // Check if `hintText`, `controller`, and `faIcon` are not null
    assert(hintText != null, "hintText cannot be null");
    assert(controller != null, "controller cannot be null");
    assert(faIcon != null, "faIcon cannot be null");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Material(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 0,
                blurRadius: 5,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            maxLines: 1,
            validator: widget.validator,
            obscureText: obscure,
            textAlignVertical: TextAlignVertical.center,
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              hintText: hintText,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              prefixIcon: faIcon != null
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 15, 0),
                      child: Icon(
                        faIcon,
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
