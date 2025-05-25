import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/widgets/elevated_text_button.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        ElevatedTextButton(
          text: 'See all',
          isCompact: true,
          onPressed: onSeeAll,
        ),
      ],
    );
  }
}
