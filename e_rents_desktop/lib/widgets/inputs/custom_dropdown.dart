import 'package:flutter/material.dart';

/// A generic dropdown form field for use with lookup data.
class CustomDropdown<TValue> extends StatelessWidget {
  final String label;
  final TValue? value;
  final List<dynamic> items;
  final ValueChanged<TValue?> onChanged;
  final String Function(dynamic) itemToString;
  final TValue Function(dynamic) itemToValue;
  final String? Function(TValue?)? validator;

  const CustomDropdown({
    super.key,
    required this.label,
    this.value,
    required this.items,
    required this.onChanged,
    required this.itemToString,
    required this.itemToValue,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TValue>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items:
          items.map((item) {
            return DropdownMenuItem<TValue>(
              value: itemToValue(item),
              child: Text(itemToString(item)),
            );
          }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
