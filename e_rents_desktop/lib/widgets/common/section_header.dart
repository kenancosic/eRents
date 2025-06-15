import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  final EdgeInsets padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.padding = const EdgeInsets.only(bottom: 8.0),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (action != null) ...[const SizedBox(width: 16), action!],
        ],
      ),
    );
  }
}
