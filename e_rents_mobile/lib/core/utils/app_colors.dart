import 'package:flutter/material.dart';

/// Extended color system with semantic colors
/// Complements the existing theme.dart colors
class AppColors {
  // Primary colors (from theme.dart)
  static const Color primary = Color(0xFF7265F0);
  static const Color secondary = Color(0xFF1F2937);
  static const Color background = Color(0xFFFCFCFC);

  // Supporting colors (from theme.dart)
  static const Color accentLight = Color(0xFFE9D5FF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);

  // NEW: Semantic status colors
  static const Color success = Color(0xFF10B981); // Green-500
  static const Color successLight = Color(0xFFD1FAE5); // Green-100
  static const Color successDark = Color(0xFF059669); // Green-600

  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color warningLight = Color(0xFFFEF3C7); // Amber-100
  static const Color warningDark = Color(0xFFD97706); // Amber-600

  static const Color error = Color(0xFFEF4444); // Red-500
  static const Color errorLight = Color(0xFFFEE2E2); // Red-100
  static const Color errorDark = Color(0xFFDC2626); // Red-600

  static const Color info = Color(0xFF3B82F6); // Blue-500
  static const Color infoLight = Color(0xFFDBEAFE); // Blue-100
  static const Color infoDark = Color(0xFF2563EB); // Blue-600

  // NEW: Surface/background variants
  static const Color surfaceLight = Color(0xFFF9FAFB); // Gray-50
  static const Color surfaceMedium = Color(0xFFF3F4F6); // Gray-100
  static const Color surfaceDark = Color(0xFFE5E7EB); // Gray-200

  // NEW: Additional text colors
  static const Color textTertiary = Color(0xFF9CA3AF); // Gray-400
  static const Color textDisabled = Color(0xFFD1D5DB); // Gray-300

  // NEW: Border colors
  static const Color borderLight = Color(0xFFF3F4F6); // Gray-100
  static const Color borderMedium = Color(0xFFE5E7EB); // Gray-200
  static const Color borderDark = Color(0xFFD1D5DB); // Gray-300

  // NEW: Overlay colors
  static Color overlayLight = Colors.black.withValues(alpha: 0.1);
  static Color overlayMedium = Colors.black.withValues(alpha: 0.3);
  static Color overlayDark = Colors.black.withValues(alpha: 0.6);

  // NEW: Special purpose colors
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // Property type colors
  static const Color propertyDaily = Color(0xFF3B82F6); // Blue
  static const Color propertyMonthly = Color(0xFF10B981); // Green

  // Booking status colors
  static const Color bookingPending = Color(0xFFF59E0B); // Amber
  static const Color bookingConfirmed = Color(0xFF10B981); // Green
  static const Color bookingCancelled = Color(0xFFEF4444); // Red
  static const Color bookingCompleted = Color(0xFF6B7280); // Gray
}

/// Helper methods for color operations
extension AppColorExtensions on Color {
  /// Creates a lighter version of the color
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Creates a darker version of the color
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Creates a color with custom opacity (0.0 - 1.0)
  Color withOpacityValue(double opacity) {
    assert(opacity >= 0.0 && opacity <= 1.0);
    return withValues(alpha: opacity);
  }
}
