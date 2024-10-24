import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onFilterPressed;
  final String hintText;

  const CustomSearchBar({
    super.key,
    this.onSearchChanged,
    this.onFilterPressed,
    this.hintText = "Search address, city, location",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F3),
        borderRadius: BorderRadius.circular(25.0), 
        border: Border.all(
          color: const Color(0xFFE3E3E7), 
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: Colors.grey, // Adjust icon color as needed
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Colors.grey),
                border: InputBorder.none, // Remove default border
              ),
              style: const TextStyle(color: Colors.black),
            ),
          ),
          if (onFilterPressed != null)
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.grey),
              onPressed: onFilterPressed,
            ),
        ],
      ),
    );
  }
}
