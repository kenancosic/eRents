import 'package:flutter/material.dart';

// Updated CustomSearchBar to use a simple TextField without SearchAnchor
class CustomSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterPressed;
  final String hintText;

  const CustomSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onFilterPressed,
    this.hintText = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    // Determine if the controller has text to potentially show a clear button
    // Note: This requires the parent widget managing the controller to rebuild
    // when the controller's text changes if a clear button is desired.
    // final bool hasText = controller?.text.isNotEmpty ?? false;

    return SizedBox(
      height: 40, // Maintain consistent height
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
          suffixIcon:
              onFilterPressed != null
                  ? IconButton(
                    icon: const Icon(
                      Icons.filter_list,
                      size: 20,
                      color: Colors.grey,
                    ),
                    tooltip: 'Filter Options',
                    onPressed: onFilterPressed,
                  )
                  : null,
          // Example: Add clear button if needed (requires controller listener in parent)
          // suffixIcon: Row(
          //   mainAxisSize: MainAxisSize.min,
          //   children: [
          //     if (hasText)
          //       IconButton(
          //         icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
          //         onPressed: () => controller?.clear(),
          //       ),
          //     if (onFilterPressed != null)
          //       IconButton(
          //         icon: const Icon(Icons.filter_list, size: 20, color: Colors.grey),
          //         tooltip: 'Filter Options',
          //         onPressed: onFilterPressed,
          //       ),
          //   ],
          // ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0), // Softer corners
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 12,
          ), // Adjust padding
          filled: true,
          fillColor:
              Colors
                  .white, // Or Theme.of(context).inputDecorationTheme.fillColor
        ),
        onChanged: onChanged,
        style: Theme.of(context).textTheme.bodyMedium, // Use theme text style
      ),
    );
  }
}
