import 'package:flutter/material.dart';

class PropertyFormFields {
  /// Builds a standard text form field with consistent styling
  static Widget buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? suffixText,
    TextInputType? keyboardType,
    int maxLines = 1,
    required String? Function(String?) validator,
    int? flex,
  }) {
    final field = TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        isDense: true,
        suffixText: suffixText,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );

    return flex != null ? Expanded(flex: flex, child: field) : field;
  }

  /// Builds a number field with validation
  static Widget buildNumberField({
    required TextEditingController controller,
    required String labelText,
    String? suffixText,
    required String errorMessage,
    int? flex,
  }) {
    return buildTextField(
      controller: controller,
      labelText: labelText,
      suffixText: suffixText,
      keyboardType: TextInputType.number,
      flex: flex,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return errorMessage;
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  /// Builds a required text field
  static Widget buildRequiredTextField({
    required TextEditingController controller,
    required String labelText,
    String? suffixText,
    int maxLines = 1,
    int? flex,
  }) {
    return buildTextField(
      controller: controller,
      labelText: labelText,
      suffixText: suffixText,
      maxLines: maxLines,
      flex: flex,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $labelText';
        }
        return null;
      },
    );
  }

  /// Builds a section title
  static Widget buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  /// Builds a spacer with consistent height
  static Widget buildSpacer({double height = 12}) {
    return SizedBox(height: height);
  }
}
