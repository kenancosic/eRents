import 'package:flutter/material.dart';

/// Standardized spacing system based on 8-point grid
/// 
/// Usage:
/// ```dart
/// Padding(padding: AppSpacing.paddingMD, child: widget)
/// SizedBox(height: AppSpacing.lg)
/// ```
class AppSpacing {
  // Base spacing units (8-point grid)
  static const double xs = 4.0;     // 0.5x - Minimal spacing
  static const double sm = 8.0;     // 1x - Small spacing
  static const double md = 16.0;    // 2x - Medium spacing (default)
  static const double lg = 24.0;    // 3x - Large spacing
  static const double xl = 32.0;    // 4x - Extra large spacing
  static const double xxl = 48.0;   // 6x - Extra extra large spacing
  static const double xxxl = 64.0;  // 8x - Maximum spacing

  // Convenient EdgeInsets presets - All sides
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);
  static const EdgeInsets paddingXXL = EdgeInsets.all(xxl);

  // Horizontal padding
  static const EdgeInsets paddingH_XS = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets paddingH_SM = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingH_MD = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingH_LG = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingH_XL = EdgeInsets.symmetric(horizontal: xl);

  // Vertical padding
  static const EdgeInsets paddingV_XS = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets paddingV_SM = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingV_MD = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingV_LG = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets paddingV_XL = EdgeInsets.symmetric(vertical: xl);

  // Common combined paddings
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: lg,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(md);

  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  static const EdgeInsets sectionPadding = EdgeInsets.only(
    left: md,
    right: md,
    bottom: lg,
  );

  // Zero padding
  static const EdgeInsets zero = EdgeInsets.zero;
}

/// Standardized border radius system
class AppRadius {
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0; // Pill/circular shape

  // BorderRadius presets
  static BorderRadius get noneRadius => BorderRadius.circular(none);
  static BorderRadius get xsRadius => BorderRadius.circular(xs);
  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
  static BorderRadius get xxlRadius => BorderRadius.circular(xxl);
  static BorderRadius get fullRadius => BorderRadius.circular(full);

  // Directional radius (for cards with different corners)
  static BorderRadius topRadius(double radius) => BorderRadius.vertical(
        top: Radius.circular(radius),
      );

  static BorderRadius bottomRadius(double radius) => BorderRadius.vertical(
        bottom: Radius.circular(radius),
      );

  static BorderRadius leftRadius(double radius) => BorderRadius.horizontal(
        left: Radius.circular(radius),
      );

  static BorderRadius rightRadius(double radius) => BorderRadius.horizontal(
        right: Radius.circular(radius),
      );
}

/// Standardized elevation shadow system
class AppShadows {
  /// Extra small shadow (subtle elevation)
  static List<BoxShadow> get xs => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  /// Small shadow (cards)
  static List<BoxShadow> get sm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Medium shadow (elevated cards)
  static List<BoxShadow> get md => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 6,
          spreadRadius: -1,
          offset: const Offset(0, 2),
        ),
      ];

  /// Large shadow (modals, floating buttons)
  static List<BoxShadow> get lg => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 15,
          spreadRadius: -3,
          offset: const Offset(0, 4),
        ),
      ];

  /// Extra large shadow (prominent floating elements)
  static List<BoxShadow> get xl => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 25,
          spreadRadius: -5,
          offset: const Offset(0, 8),
        ),
      ];

  /// No shadow
  static List<BoxShadow> get none => [];
}
