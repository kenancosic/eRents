import 'package:flutter/material.dart';

/// Builds a section card with a title and icon
Widget buildSection({
  required BuildContext context,
  required String title,
  required IconData icon,
  required Widget child,
}) {
  return Card(
    elevation: Theme.of(context).cardTheme.elevation,
    shape: Theme.of(context).cardTheme.shape,
    color: Theme.of(context).cardTheme.color,
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

/// Builds a text form field with common properties
Widget buildTextField({
  required TextEditingController controller,
  required String label,
  required bool enabled,
  bool isPassword = false,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    enabled: enabled,
    obscureText: isPassword,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator:
        validator ??
        (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          return null;
        },
  );
}
