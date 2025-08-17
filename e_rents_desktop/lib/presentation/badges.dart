import 'package:flutter/material.dart';
import 'package:e_rents_desktop/presentation/extensions.dart';
import 'package:e_rents_desktop/models/enums/maintenance_issue_status.dart';
import 'package:e_rents_desktop/models/enums/maintenance_issue_priority.dart';

enum BadgeVariant { subtle, solid, outlined }
enum BadgeSize { sm, md }

class _BadgeStyle {
  final EdgeInsetsGeometry padding;
  final double radius;
  final double iconSize;
  final double fontSize;
  const _BadgeStyle({
    required this.padding,
    required this.radius,
    required this.iconSize,
    required this.fontSize,
  });
}

_BadgeStyle _styleFor(BadgeSize size) {
  switch (size) {
    case BadgeSize.sm:
      return const _BadgeStyle(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        radius: 14,
        iconSize: 14,
        fontSize: 11,
      );
    case BadgeSize.md:
      return const _BadgeStyle(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        radius: 20,
        iconSize: 16,
        fontSize: 12,
      );
  }
}

class StatusBadge extends StatelessWidget {
  final MaintenanceIssueStatus status;
  final BadgeVariant variant; // subtle (tinted), solid, outlined
  final BadgeSize size;
  final bool showIcon;

  const StatusBadge({
    super.key,
    required this.status,
    this.variant = BadgeVariant.subtle,
    this.size = BadgeSize.md,
    this.showIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    final style = _styleFor(size);

    final Color? bgColor;
    final Color fgColor;
    final BoxBorder? border;
    switch (variant) {
      case BadgeVariant.subtle:
        bgColor = color.withOpacity(0.15);
        fgColor = color;
        border = null;
        break;
      case BadgeVariant.solid:
        bgColor = color;
        fgColor = Colors.white;
        border = null;
        break;
      case BadgeVariant.outlined:
        bgColor = Colors.transparent;
        fgColor = color;
        border = Border.all(color: color);
        break;
    }

    return Container(
      padding: style.padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(style.radius),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(status.icon, size: style.iconSize, color: fgColor),
            const SizedBox(width: 6),
          ],
          Text(
            status.displayName,
            style: TextStyle(
              color: fgColor,
              fontWeight: FontWeight.bold,
              fontSize: style.fontSize,
            ),
          ),
        ],
      ),
    );
  }
}

class PriorityBadge extends StatelessWidget {
  final MaintenanceIssuePriority priority;
  final BadgeVariant variant;
  final BadgeSize size;
  final bool showIcon;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.variant = BadgeVariant.subtle,
    this.size = BadgeSize.sm,
    this.showIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = priority.color;
    final style = _styleFor(size);

    final Color? bgColor;
    final Color fgColor;
    final BoxBorder? border;
    switch (variant) {
      case BadgeVariant.subtle:
        bgColor = color.withOpacity(0.12);
        fgColor = color;
        border = null;
        break;
      case BadgeVariant.solid:
        bgColor = color;
        fgColor = Colors.white;
        border = null;
        break;
      case BadgeVariant.outlined:
        bgColor = Colors.transparent;
        fgColor = color;
        border = Border.all(color: color);
        break;
    }

    return Container(
      padding: style.padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(style.radius),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(priority.icon, size: style.iconSize, color: fgColor),
            const SizedBox(width: 6),
          ],
          Text(
            priority.displayName,
            style: TextStyle(
              color: fgColor,
              fontWeight: FontWeight.w600,
              fontSize: style.fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
