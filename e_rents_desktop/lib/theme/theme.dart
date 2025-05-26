import 'package:flutter/material.dart';

// Primary color palette
const Color primaryColor = Color(
  0xFF7265F0,
); // Purple accent used in CustomButton and throughout the app
const Color secondaryColor = Color(0xFF1F2937); // Dark gray used for buttons
const Color backgroundColor = Color(0xFFFCFCFC); // Light background

// Additional colors
const Color accentLightColor = Color(0xFFE9D5FF); // Light purple for gradients
const Color textPrimaryColor = Color(0xFF1F2937); // Dark text
const Color textSecondaryColor = Color(0xFF6B7280); // Gray text
const Color dividerColor = Color(0xFFE5E7EB); // Light gray for dividers

final ThemeData appTheme = ThemeData(
  // Base colors
  primaryColor: primaryColor,
  scaffoldBackgroundColor: backgroundColor,

  // Color scheme
  colorScheme: ColorScheme.fromSwatch().copyWith(
    primary: primaryColor,
    secondary: secondaryColor,
    surface: backgroundColor,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: textPrimaryColor,
  ),

  // App bar theme
  appBarTheme: const AppBarTheme(
    backgroundColor: backgroundColor,
    iconTheme: IconThemeData(color: textPrimaryColor),
    titleTextStyle: TextStyle(
      color: textPrimaryColor,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: 'Hind',
    ),
    elevation: 0,
  ),

  // Text theme
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Hind',
      fontWeight: FontWeight.bold,
      fontSize: 32,
      color: textPrimaryColor,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Hind',
      fontWeight: FontWeight.bold,
      fontSize: 28,
      color: textPrimaryColor,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Hind',
      fontWeight: FontWeight.bold,
      fontSize: 24,
      color: textPrimaryColor,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Hind',
      fontWeight: FontWeight.bold,
      fontSize: 20,
      color: textPrimaryColor,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Hind',
      fontWeight: FontWeight.bold,
      fontSize: 18,
      color: textPrimaryColor,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Hind',
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: textPrimaryColor,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Hind',
      fontWeight: FontWeight.normal,
      fontSize: 14,
      color: textPrimaryColor,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Hind',
      fontWeight: FontWeight.normal,
      fontSize: 12,
      color: textPrimaryColor,
    ),
    bodySmall: TextStyle(
      fontSize: 12.0,
      fontWeight: FontWeight.w400,
      color: textSecondaryColor,
      fontFamily: 'Hind',
    ),
    labelLarge: TextStyle(
      fontFamily: 'Hind',
      fontWeight: FontWeight.normal,
      fontSize: 10,
      color: textPrimaryColor,
    ),
  ),

  // Button themes
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: primaryColor,
      side: const BorderSide(color: primaryColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryColor,
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    ),
  ),

  // Chip theme
  chipTheme: ChipThemeData(
    backgroundColor: Colors.grey[200]!,
    selectedColor: primaryColor,
    disabledColor: Colors.grey[300]!,
    labelStyle: const TextStyle(color: textPrimaryColor),
    secondaryLabelStyle: const TextStyle(color: Colors.white),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),

  // Input decoration
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryColor),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red),
    ),
    hintStyle: TextStyle(color: Colors.grey[400]),
  ),

  // Card theme
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 4,
    shadowColor: Colors.grey.withValues(alpha: 0.2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(8),
    clipBehavior: Clip.antiAlias,
  ),

  // Switch theme
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.selected)) {
        return primaryColor;
      }
      return Colors.grey[300]!;
    }),
    trackColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.selected)) {
        return primaryColor.withValues(alpha: 0.5);
      }
      return Colors.grey[200]!;
    }),
    trackOutlineColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.selected)) {
        return primaryColor.withValues(alpha: 0.5);
      }
      return Colors.grey[300]!;
    }),
  ),

  // Bottom navigation bar theme
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: primaryColor,
    unselectedItemColor: textSecondaryColor,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
    unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
  ),

  // Slider theme
  sliderTheme: SliderThemeData(
    activeTrackColor: primaryColor,
    inactiveTrackColor: Colors.grey[300],
    thumbColor: primaryColor,
    overlayColor: primaryColor.withValues(alpha: 0.2),
    trackHeight: 4,
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
  ),

  // Divider theme
  dividerTheme: DividerThemeData(color: dividerColor, thickness: 1, space: 24),
);

// Custom gradient decorations
class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFFE9D5FF), // Light purple
      primaryColor, // Main purple
      Color(0xFFE9D5FF), // Light purple
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [
      Color(0xFF917AFD), // From CustomDecorations
      Color(0xFF6246EA), // From CustomDecorations
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// Box decorations
class AppDecorations {
  static BoxDecoration roundedBox({Color? color, double radius = 12}) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          spreadRadius: 1,
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration gradientBox({
    LinearGradient? gradient,
    double radius = 16,
  }) {
    return BoxDecoration(
      gradient: gradient ?? AppGradients.primaryGradient,
      borderRadius: BorderRadius.circular(radius),
    );
  }
}
