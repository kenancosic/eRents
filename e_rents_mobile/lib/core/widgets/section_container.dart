import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/utils/app_spacing.dart';
import 'package:e_rents_mobile/core/utils/app_colors.dart';

/// Standardized section wrapper with consistent spacing and optional dividers
/// 
/// Usage:
/// ```dart
/// SectionContainer(
///   title: 'Account Settings',
///   child: Column(children: [...]),
/// )
/// ```
class SectionContainer extends StatelessWidget {
  final Widget child;
  final String? title;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final bool addDivider;
  final bool addTopDivider;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;

  const SectionContainer({
    super.key,
    required this.child,
    this.title,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.addDivider = false,
    this.addTopDivider = false,
    this.borderRadius,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.only(bottom: AppSpacing.lg),
      padding: padding,
      decoration: backgroundColor != null || shadows != null || borderRadius != null
          ? BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius,
              boxShadow: shadows,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Optional title
          if (title != null) ...[
            Padding(
              padding: padding ?? AppSpacing.paddingH_MD,
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            SizedBox(height: AppSpacing.sm),
          ],
          
          // Optional top divider
          if (addTopDivider)
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.divider,
            ),
          
          // Main content
          child,
          
          // Optional bottom divider
          if (addDivider) ...[
            SizedBox(height: AppSpacing.md),
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.divider,
            ),
          ],
        ],
      ),
    );
  }
}

/// Card-style section with elevation and rounded corners
class SectionCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Widget? trailing;

  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.padding,
    this.margin,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Optional title with trailing widget
          if (title != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          
          // Content
          Padding(
            padding: padding ?? EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// List-style section for settings/menu items
class SectionList extends StatelessWidget {
  final String? title;
  final List<Widget> items;
  final EdgeInsets? margin;
  final bool compact;

  const SectionList({
    super.key,
    this.title,
    required this.items,
    this.margin,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Optional title
          if (title != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                compact ? AppSpacing.xs : AppSpacing.sm,
              ),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 13 : null,
                    ),
              ),
            ),
          
          // List items
          ...items,
        ],
      ),
    );
  }
}
