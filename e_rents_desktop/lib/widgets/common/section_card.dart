import 'package:flutter/material.dart';

/// Reusable section card widget to eliminate duplication across screens
/// Used by: PropertyFormScreen, ProfileScreen, HomeScreen, etc.
class SectionCard extends StatelessWidget {
  final String? title;
  final Widget? header;
  final Widget child;
  final IconData? titleIcon;
  final List<Widget>? children;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;

  const SectionCard({
    super.key,
    this.title,
    this.header,
    required this.child,
    this.titleIcon,
    this.elevation,
    this.padding,
    this.margin,
    this.backgroundColor,
  }) : children = null,
       assert(
         title != null || header != null,
         'Either title or header must be provided.',
       );

  const SectionCard.withChildren({
    super.key,
    this.title,
    this.header,
    required this.children,
    this.titleIcon,
    this.elevation,
    this.padding,
    this.margin,
    this.backgroundColor,
  }) : child = const SizedBox.shrink(),
       assert(
         title != null || header != null,
         'Either title or header must be provided.',
       );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: elevation ?? 2.0,
      margin: margin ?? const EdgeInsets.only(bottom: 16.0),
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header ?? _buildHeader(theme),
            const Divider(height: 24, thickness: 1),
            if (children != null) ...children! else child,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        if (titleIcon != null)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(titleIcon, color: theme.colorScheme.primary),
          ),
        Text(
          title!,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

/// Extension for easier section card building
extension SectionCardBuilder on Widget {
  Widget inSectionCard({
    required String title,
    IconData? icon,
    double? elevation,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
  }) {
    return SectionCard(
      title: title,
      titleIcon: icon,
      elevation: elevation,
      padding: padding,
      margin: margin,
      backgroundColor: backgroundColor,
      child: this,
    );
  }
}
