import 'package:e_rents_mobile/core/utils/custom_decorator.dart';
import 'package:e_rents_mobile/core/widgets/gradient_text.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          CustomDecorations.whiteBoxDecoration, // Apply the gradient decoration
      child: AppBar(
        backgroundColor:
            Colors.transparent, // Make the AppBar background transparent
        elevation: 0, // Remove the AppBar shadow to match the gradient
        title: GradientText(
          text: title,
          style:
              const TextStyle(fontFamily: 'Hind', fontSize: 25, fontWeight: FontWeight.bold),
        ),
        actions: actions,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
