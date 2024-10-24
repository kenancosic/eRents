import 'package:e_rents_mobile/core/utils/custom_decorator.dart';
import 'package:e_rents_mobile/core/widgets/custom_search_bar.dart';
import 'package:e_rents_mobile/core/widgets/gradient_text.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget; // Added this parameter
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackButtonPressed;
  final bool showFilterButton;
  final VoidCallback? onFilterButtonPressed;
  final ValueChanged<String>? onSearchChanged;
  final String? searchHintText;

  const CustomAppBar({
    Key? key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBackButtonPressed,
    this.showFilterButton = false,
    this.onFilterButtonPressed,
    this.onSearchChanged,
    this.searchHintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kToolbarHeight,
      
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          if (leading != null)
            leading!
          else if (showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBackButtonPressed ?? () => Navigator.of(context).pop(),
            ),
          Expanded(
           child: onSearchChanged != null
                ? CustomSearchBar(
                    onSearchChanged: onSearchChanged,
                    onFilterPressed: showFilterButton ? onFilterButtonPressed : null,
                    hintText: searchHintText ?? 'Search',
                  )
                : (titleWidget != null
                    ? titleWidget!
                    : (title != null
                        ? GradientText(
                            text: title!,
                            style: const TextStyle(
                              fontFamily: 'Hind',
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Container())),
          ),
          if (showFilterButton)
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: onFilterButtonPressed,
            ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
