import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/utils/theme.dart';

enum ButtonSize { compact, normal, large }

enum ButtonWidth { content, expanded, flexible }

class CustomButton extends StatelessWidget {
  final dynamic label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final double? height; // Now optional
  final double? fontSize; // Now optional
  final double borderRadius;
  final IconData? icon;
  final bool useGradient;
  final String? gradientType;
  final bool useShadow;
  final ButtonSize size; // New: responsive sizing
  final ButtonWidth width; // New: width behavior
  final EdgeInsets? padding; // New: custom padding
  final double? minWidth; // New: optional min width
  final double? maxWidth; // New: optional max width

  const CustomButton({
    super.key,
    required this.label,
    required this.isLoading,
    this.onPressed,
    this.icon,
    this.backgroundColor = primaryColor,
    this.height, // Remove default, will be calculated
    this.fontSize, // Remove default, will be calculated
    this.borderRadius = 8,
    this.useGradient = true,
    this.gradientType = 'button',
    this.useShadow = true,
    this.size = ButtonSize.normal, // Default size
    this.width = ButtonWidth.flexible, // Default width behavior
    this.padding, // Custom padding override
    this.minWidth, // Optional constraints
    this.maxWidth,
  });

  // Calculate responsive dimensions based on size and context
  double _getHeight() {
    switch (size) {
      case ButtonSize.compact:
        return height ?? 36;
      case ButtonSize.normal:
        return height ?? 44;
      case ButtonSize.large:
        return height ?? 52;
    }
  }

  double _getFontSize() {
    switch (size) {
      case ButtonSize.compact:
        return fontSize ?? 14;
      case ButtonSize.normal:
        return fontSize ?? 16;
      case ButtonSize.large:
        return fontSize ?? 18;
    }
  }

  EdgeInsets _getPadding() {
    if (padding != null) return padding!;

    switch (size) {
      case ButtonSize.compact:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.normal:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  BoxConstraints _getConstraints() {
    double defaultMinWidth = 0;
    double defaultMaxWidth = double.infinity;

    // Set sensible defaults based on size if not specified
    if (minWidth == null) {
      switch (size) {
        case ButtonSize.compact:
          defaultMinWidth = width == ButtonWidth.content ? 0 : 80;
          break;
        case ButtonSize.normal:
          defaultMinWidth = width == ButtonWidth.content ? 0 : 100;
          break;
        case ButtonSize.large:
          defaultMinWidth = width == ButtonWidth.content ? 0 : 120;
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
    // Get gradient from theme
    LinearGradient gradient;
    switch (gradientType) {
      case 'primary':
        gradient = AppGradients.primaryGradient;
        break;
      case 'button':
      default:
        gradient = AppGradients.buttonGradient;
        break;
    }

    final calculatedHeight = _getHeight();
    final calculatedFontSize = _getFontSize();
    final calculatedPadding = _getPadding();

    // Create the button content
    Widget buttonContent;
    if (isLoading) {
      final indicatorSize = calculatedHeight * 0.4; // Responsive indicator size
      buttonContent = SizedBox(
        height: indicatorSize,
        width: indicatorSize,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: indicatorSize / 10,
        ),
      );
    } else if (icon != null) {
      final iconSize = calculatedFontSize * 1.2; // Icon size relative to font
      final spacing = calculatedFontSize * 0.5; // Spacing relative to font

      buttonContent = Row(
        mainAxisSize:
            width == ButtonWidth.content ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: iconSize),
          if (label != null) SizedBox(width: spacing),
          if (label != null)
            Flexible(
              child: label is String
                  ? Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
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
                color: Colors.white,
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
      final shadowBlur = calculatedHeight * 0.4; // Shadow relative to height
      final shadowOffset = calculatedHeight * 0.15;

      shadows = [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.25),
          offset: Offset(0, shadowOffset),
          blurRadius: shadowBlur,
          spreadRadius: -2,
        ),
      ];
    }

    // Create the button
    Widget button = Container(
      constraints: _getConstraints(),
      decoration: BoxDecoration(
        gradient: useGradient ? gradient : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows,
      ),
      child: Material(
        color: useGradient ? Colors.transparent : backgroundColor,
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

    // Apply width behavior
    switch (width) {
      case ButtonWidth.content:
        return IntrinsicWidth(child: button);
      case ButtonWidth.expanded:
        return SizedBox(width: double.infinity, child: button);
      case ButtonWidth.flexible:
      default:
        return button; // Let parent decide
    }
  }

  // Convenience factory constructors
  factory CustomButton.compact({
    required dynamic label,
    required bool isLoading,
    required VoidCallback onPressed,
    IconData? icon,
    ButtonWidth width = ButtonWidth.content,
    String gradientType = 'button',
  }) {
    return CustomButton(
      label: label,
      isLoading: isLoading,
      onPressed: onPressed,
      icon: icon,
      size: ButtonSize.compact,
      width: width,
      gradientType: gradientType,
    );
  }

  factory CustomButton.large({
    required dynamic label,
    required bool isLoading,
    required VoidCallback onPressed,
    IconData? icon,
    ButtonWidth width = ButtonWidth.expanded,
    String gradientType = 'button',
  }) {
    return CustomButton(
      label: label,
      isLoading: isLoading,
      onPressed: onPressed,
      icon: icon,
      size: ButtonSize.large,
      width: width,
      gradientType: gradientType,
    );
  }

  factory CustomButton.gradient({
    required dynamic label,
    required bool isLoading,
    required VoidCallback onPressed,
    IconData? icon,
    double? height,
    double? fontSize,
    double? borderRadius,
    String gradientType = 'button',
    ButtonSize size = ButtonSize.normal,
    ButtonWidth width = ButtonWidth.flexible,
  }) {
    return CustomButton(
      label: label,
      isLoading: isLoading,
      onPressed: onPressed,
      icon: icon,
      height: height,
      fontSize: fontSize,
      borderRadius: borderRadius ?? 8,
      useGradient: true,
      useShadow: true,
      gradientType: gradientType,
      size: size,
      width: width,
    );
  }
}
