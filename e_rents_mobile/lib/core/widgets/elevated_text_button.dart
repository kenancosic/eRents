import 'package:flutter/material.dart';

class ElevatedTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? textColor;
  final Color? backgroundColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsets? padding;
  final bool isCompact;

  const ElevatedTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.textColor,
    this.backgroundColor,
    this.fontSize,
    this.fontWeight,
    this.padding,
    this.isCompact = false,
  });

  const ElevatedTextButton.icon({
    super.key,
    required this.text,
    required this.icon,
    this.onPressed,
    this.textColor,
    this.backgroundColor,
    this.fontSize,
    this.fontWeight,
    this.padding,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTextColor = textColor ?? theme.primaryColor;
    final defaultBackgroundColor = backgroundColor ?? Colors.white;
    final defaultFontSize = fontSize ?? (isCompact ? 14.0 : 16.0);
    final defaultFontWeight = fontWeight ?? FontWeight.w600;
    final defaultPadding = padding ??
        (isCompact
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 10));

    Widget buttonChild;
    if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: defaultFontSize * 1.2,
            color: defaultTextColor,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: defaultFontSize,
              fontWeight: defaultFontWeight,
              color: defaultTextColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
    } else {
      buttonChild = Text(
        text,
        style: TextStyle(
          fontSize: defaultFontSize,
          fontWeight: defaultFontWeight,
          color: defaultTextColor,
          letterSpacing: 0.5,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: defaultBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: defaultTextColor.withOpacity(0.2),
            offset: const Offset(0, 2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 1),
            blurRadius: 2,
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: defaultTextColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          splashColor: defaultTextColor.withOpacity(0.1),
          highlightColor: defaultTextColor.withOpacity(0.05),
          child: Container(
            padding: defaultPadding,
            child: buttonChild,
          ),
        ),
      ),
    );
  }
}
