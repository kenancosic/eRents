import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/utils/theme.dart';

enum TextButtonSize { compact, normal, large }

enum TextButtonStyle { plain, iced, frosted }

class CustomTextButton extends StatelessWidget {
  final dynamic label;
  final bool isLoading;
  final VoidCallback onPressed;
  final Color textColor;
  final double? fontSize;
  final FontWeight fontWeight;
  final IconData? icon;
  final TextButtonSize size;
  final TextButtonStyle style;
  final EdgeInsets? padding;
  final double borderRadius;
  final Color? icingColor;
  final double icingOpacity;
  final double blurStrength;

  const CustomTextButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.textColor = primaryColor,
    this.fontSize,
    this.fontWeight = FontWeight.w600,
    this.icon,
    this.size = TextButtonSize.normal,
    this.style = TextButtonStyle.iced,
    this.padding,
    this.borderRadius = 8,
    this.icingColor,
    this.icingOpacity = 0.8,
    this.blurStrength = 10.0,
  });

  double _getFontSize() {
    switch (size) {
      case TextButtonSize.compact:
        return fontSize ?? 14;
      case TextButtonSize.normal:
        return fontSize ?? 16;
      case TextButtonSize.large:
        return fontSize ?? 18;
    }
  }

  EdgeInsets _getPadding() {
    if (padding != null) return padding!;

    switch (size) {
      case TextButtonSize.compact:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case TextButtonSize.normal:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case TextButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    }
  }

  @override
  Widget build(BuildContext context) {
    final calculatedFontSize = _getFontSize();
    final calculatedPadding = _getPadding();

    // Create button content
    Widget buttonContent;
    if (isLoading) {
      final indicatorSize = calculatedFontSize * 1.2;
      buttonContent = SizedBox(
        height: indicatorSize,
        width: indicatorSize,
        child: CircularProgressIndicator(
          color: textColor,
          strokeWidth: 2.0,
        ),
      );
    } else if (icon != null) {
      final iconSize = calculatedFontSize * 1.1;
      final spacing = calculatedFontSize * 0.4;

      buttonContent = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: iconSize),
          if (label != null) SizedBox(width: spacing),
          if (label != null)
            Flexible(
              child: label is String
                  ? Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: calculatedFontSize,
                        fontWeight: fontWeight,
                        height: 1.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  : label,
            ),
        ],
      );
    } else {
      buttonContent = label is String
          ? Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: calculatedFontSize,
                fontWeight: fontWeight,
                height: 1.0,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            )
          : label;
    }

    // Create the button based on style
    Widget button;

    switch (style) {
      case TextButtonStyle.plain:
        button = Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: calculatedPadding,
              child: buttonContent,
            ),
          ),
        );
        break;

      case TextButtonStyle.iced:
        button = ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter:
                ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
            child: Container(
              decoration: BoxDecoration(
                color: (icingColor ?? Colors.white)
                    .withOpacity(icingOpacity * 0.7),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(borderRadius),
                child: InkWell(
                  onTap: isLoading ? null : onPressed,
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: Padding(
                    padding: calculatedPadding,
                    child: buttonContent,
                  ),
                ),
              ),
            ),
          ),
        );
        break;

      case TextButtonStyle.frosted:
        button = Container(
          decoration: BoxDecoration(
            color: (icingColor ?? Colors.white).withOpacity(icingOpacity * 0.9),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius),
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Padding(
                padding: calculatedPadding,
                child: buttonContent,
              ),
            ),
          ),
        );
        break;
    }

    return IntrinsicWidth(child: button);
  }

  // Convenience factory constructors
  factory CustomTextButton.plain({
    required dynamic label,
    required bool isLoading,
    required VoidCallback onPressed,
    Color? textColor,
    IconData? icon,
    TextButtonSize size = TextButtonSize.normal,
  }) {
    return CustomTextButton(
      label: label,
      isLoading: isLoading,
      onPressed: onPressed,
      textColor: textColor ?? primaryColor,
      icon: icon,
      size: size,
      style: TextButtonStyle.plain,
    );
  }

  factory CustomTextButton.iced({
    required dynamic label,
    required bool isLoading,
    required VoidCallback onPressed,
    Color? textColor,
    IconData? icon,
    TextButtonSize size = TextButtonSize.normal,
    Color? icingColor,
    double icingOpacity = 0.8,
  }) {
    return CustomTextButton(
      label: label,
      isLoading: isLoading,
      onPressed: onPressed,
      textColor: textColor ?? primaryColor,
      icon: icon,
      size: size,
      style: TextButtonStyle.iced,
      icingColor: icingColor,
      icingOpacity: icingOpacity,
    );
  }

  factory CustomTextButton.frosted({
    required dynamic label,
    required bool isLoading,
    required VoidCallback onPressed,
    Color? textColor,
    IconData? icon,
    TextButtonSize size = TextButtonSize.normal,
    Color? icingColor,
  }) {
    return CustomTextButton(
      label: label,
      isLoading: isLoading,
      onPressed: onPressed,
      textColor: textColor ?? primaryColor,
      icon: icon,
      size: size,
      style: TextButtonStyle.frosted,
      icingColor: icingColor,
    );
  }

  factory CustomTextButton.compact({
    required dynamic label,
    required bool isLoading,
    required VoidCallback onPressed,
    Color? textColor,
    IconData? icon,
    TextButtonStyle style = TextButtonStyle.iced,
    Color? icingColor,
  }) {
    return CustomTextButton(
      label: label,
      isLoading: isLoading,
      onPressed: onPressed,
      textColor: textColor ?? primaryColor,
      icon: icon,
      size: TextButtonSize.compact,
      style: style,
      icingColor: icingColor,
    );
  }
}
