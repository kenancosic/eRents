import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/utils/theme.dart';

enum OutlinedButtonSize { compact, normal, large }

enum OutlinedButtonWidth { content, expanded, flexible }

class CustomOutlinedButton extends StatelessWidget {
  final dynamic label;
  final bool isLoading;
  final VoidCallback onPressed;
  final Color borderColor;
  final Color? backgroundColor;
  final Color textColor;
  final double? height;
  final double? fontSize;
  final double borderRadius;
  final double borderWidth;
  final IconData? icon;
  final bool useGradientBorder;
  final String? gradientType;
  final bool useShadow;
  final OutlinedButtonSize size;
  final OutlinedButtonWidth width;
  final EdgeInsets? padding;
  final double? minWidth;
  final double? maxWidth;

  const CustomOutlinedButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.borderColor = primaryColor,
    this.backgroundColor,
    this.textColor = primaryColor,
    this.height,
    this.fontSize,
    this.borderRadius = 8,
    this.borderWidth = 1.5,
    this.icon,
    this.useGradientBorder = false,
    this.gradientType = 'button',
    this.useShadow = false,
    this.size = OutlinedButtonSize.normal,
    this.width = OutlinedButtonWidth.flexible,
    this.padding,
    this.minWidth,
    this.maxWidth,
  });

  // Calculate responsive dimensions based on size and context
  double _getHeight() {
    switch (size) {
      case OutlinedButtonSize.compact:
        return height ?? 36;
      case OutlinedButtonSize.normal:
        return height ?? 44;
      case OutlinedButtonSize.large:
        return height ?? 52;
    }
  }

  double _getFontSize() {
    switch (size) {
      case OutlinedButtonSize.compact:
        return fontSize ?? 14;
      case OutlinedButtonSize.normal:
        return fontSize ?? 16;
      case OutlinedButtonSize.large:
        return fontSize ?? 18;
    }
  }

  EdgeInsets _getPadding() {
    if (padding != null) return padding!;

    switch (size) {
      case OutlinedButtonSize.compact:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case OutlinedButtonSize.normal:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      case OutlinedButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  BoxConstraints _getConstraints() {
    double defaultMinWidth = 0;
    double defaultMaxWidth = double.infinity;

    if (minWidth == null) {
      switch (size) {
        case OutlinedButtonSize.compact:
          defaultMinWidth = width == OutlinedButtonWidth.content ? 0 : 80;
          break;
        case OutlinedButtonSize.normal:
          defaultMinWidth = width == OutlinedButtonWidth.content ? 0 : 100;
          break;
        case OutlinedButtonSize.large:
          defaultMinWidth = width == OutlinedButtonWidth.content ? 0 : 120;
          break;
      }
    }

    return BoxConstraints(
      minWidth: minWidth ?? defaultMinWidth,
      maxWidth: maxWidth ?? defaultMaxWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get gradient from theme for border
    LinearGradient? gradient;
    if (useGradientBorder) {
      switch (gradientType) {
        case 'primary':
          gradient = AppGradients.primaryGradient;
          break;
        case 'button':
        default:
          gradient = AppGradients.buttonGradient;
          break;
      }
    }

    final calculatedHeight = _getHeight();
    final calculatedFontSize = _getFontSize();
    final calculatedPadding = _getPadding();
    final calculatedTextColor = useGradientBorder ? Colors.white : textColor;

    // Create the button content
    Widget buttonContent;
    if (isLoading) {
      final indicatorSize = calculatedHeight * 0.4;
      buttonContent = SizedBox(
        height: indicatorSize,
        width: indicatorSize,
        child: CircularProgressIndicator(
          color: calculatedTextColor,
          strokeWidth: indicatorSize / 10,
        ),
      );
    } else if (icon != null) {
      final iconSize = calculatedFontSize * 1.2;
      final spacing = calculatedFontSize * 0.5;

      buttonContent = Row(
        mainAxisSize: width == OutlinedButtonWidth.content
            ? MainAxisSize.min
            : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: calculatedTextColor, size: iconSize),
          if (label != null) SizedBox(width: spacing),
          if (label != null)
            Flexible(
              child: label is String
                  ? Text(
                      label,
                      style: TextStyle(
                        color: calculatedTextColor,
                        fontSize: calculatedFontSize,
                        fontWeight: FontWeight.w600,
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
                color: calculatedTextColor,
                fontSize: calculatedFontSize,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            )
          : label;
    }

    // Adaptive shadow based on size
    List<BoxShadow>? shadows;
    if (useShadow) {
      final shadowBlur = calculatedHeight * 0.3;
      final shadowOffset = calculatedHeight * 0.1;

      shadows = [
        BoxShadow(
          color: borderColor.withValues(alpha: 0.15),
          offset: Offset(0, shadowOffset),
          blurRadius: shadowBlur,
          spreadRadius: -1,
        ),
      ];
    }

    // Create the button
    Widget button;

    if (useGradientBorder && gradient != null) {
      // Gradient border implementation
      button = Container(
        constraints: _getConstraints(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: gradient,
          boxShadow: shadows,
        ),
        child: Container(
          margin: EdgeInsets.all(borderWidth),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius - borderWidth),
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: BorderRadius.circular(borderRadius - borderWidth),
              child: Container(
                height: calculatedHeight - (borderWidth * 2),
                padding: calculatedPadding,
                child: Center(child: buttonContent),
              ),
            ),
          ),
        ),
      );
    } else {
      // Regular outlined button
      button = Container(
        constraints: _getConstraints(),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: borderWidth),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: shadows,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              height: calculatedHeight,
              padding: calculatedPadding,
              child: Center(child: buttonContent),
            ),
          ),
        ),
      );
    }

    // Apply width behavior
    switch (width) {
      case OutlinedButtonWidth.content:
        return IntrinsicWidth(child: button);
      case OutlinedButtonWidth.expanded:
        return SizedBox(width: double.infinity, child: button);
      case OutlinedButtonWidth.flexible:
      default:
        return button;
    }
  }

  // Convenience factory constructors
  factory CustomOutlinedButton.compact({
    required dynamic label,
    required bool isLoading,
    required VoidCallback onPressed,
    IconData? icon,
    OutlinedButtonWidth width = OutlinedButtonWidth.content,
    Color? borderColor,
    Color? textColor,
    bool useGradientBorder = false,
  }) {
    return CustomOutlinedButton(
      label: label,
      isLoading: isLoading,
      onPressed: onPressed,
      icon: icon,
      size: OutlinedButtonSize.compact,
      width: width,
      borderColor: borderColor ?? primaryColor,
      textColor: textColor ?? primaryColor,
      useGradientBorder: useGradientBorder,
    );
  }

  factory CustomOutlinedButton.large({
    required dynamic label,
    required bool isLoading,
    required VoidCallback onPressed,
    IconData? icon,
    OutlinedButtonWidth width = OutlinedButtonWidth.expanded,
    Color? borderColor,
    Color? textColor,
    bool useGradientBorder = false,
  }) {
    return CustomOutlinedButton(
      label: label,
      isLoading: isLoading,
      onPressed: onPressed,
      icon: icon,
      size: OutlinedButtonSize.large,
      width: width,
      borderColor: borderColor ?? primaryColor,
      textColor: textColor ?? primaryColor,
      useGradientBorder: useGradientBorder,
    );
  }

  factory CustomOutlinedButton.gradient({
    required dynamic label,
    required bool isLoading,
    required VoidCallback onPressed,
    IconData? icon,
    double? height,
    double? fontSize,
    double? borderRadius,
    String gradientType = 'button',
    OutlinedButtonSize size = OutlinedButtonSize.normal,
    OutlinedButtonWidth width = OutlinedButtonWidth.flexible,
    Color? backgroundColor,
  }) {
    return CustomOutlinedButton(
      label: label,
      isLoading: isLoading,
      onPressed: onPressed,
      icon: icon,
      height: height,
      fontSize: fontSize,
      borderRadius: borderRadius ?? 8,
      useGradientBorder: true,
      useShadow: true,
      gradientType: gradientType,
      size: size,
      width: width,
      backgroundColor: backgroundColor ?? Colors.white,
      textColor: primaryColor, // Will be overridden for gradient border
    );
  }
}
