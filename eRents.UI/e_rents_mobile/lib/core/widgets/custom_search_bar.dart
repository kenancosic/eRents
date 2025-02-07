import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomSearchBar extends StatelessWidget {
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onFilterIconPressed;
  final String hintText;
  final bool showFilterIcon;

  const CustomSearchBar({
    super.key,
    this.onSearchChanged,
    this.onFilterIconPressed,
    this.hintText = "Search address, city, location",
    this.showFilterIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical:5),
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
          SvgPicture.asset('assets/icons/search.svg'),
          const SizedBox(width: 8.0),
          Expanded(
            child: TextField(
              onChanged: onSearchChanged,
              cursorHeight: 20,
              textAlignVertical: TextAlignVertical.center,     
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle
                  (color: Colors.grey,
                  fontSize: 18.0,
                  height: 1,
                  ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                suffixIcon: showFilterIcon
            ? IconButton(
                icon: SvgPicture.asset('assets/icons/filters.svg'),
                onPressed: onFilterIconPressed,
                style: const ButtonStyle(
                  alignment: Alignment.centerRight,
                ),
              )
            : null,
              ),
              style: const TextStyle(
                color: Colors.black, // Text color for user input
                fontSize: 18.0, // Size of user input text
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
