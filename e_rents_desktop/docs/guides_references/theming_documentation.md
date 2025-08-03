# eRents Desktop Application Theming Documentation

## Overview

This document provides documentation for the theming system used in the eRents desktop application. The application follows Material 3 design principles with a custom color palette and consistent styling across all components.

## Core Components

### Color Palette

The application uses a consistent color palette defined as constants:

```dart
// Primary color palette
const Color primaryColor = Color(0xFF7265F0); // Purple accent
const Color secondaryColor = Color(0xFF1F2937); // Dark gray
const Color backgroundColor = Color(0xFFFCFCFC); // Light background

// Additional colors
const Color accentLightColor = Color(0xFFE9D5FF); // Light purple for gradients
const Color textPrimaryColor = Color(0xFF1F2937); // Dark text
const Color textSecondaryColor = Color(0xFF6B7280); // Gray text
const Color dividerColor = Color(0xFFE5E7EB); // Light gray for dividers
```

### ThemeData

The application uses a comprehensive ThemeData configuration that follows Material 3 principles:

```dart
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
  
  // Other theme configurations...
);
```

## Theme Components

### AppBar Theme

Custom AppBar styling with no elevation and consistent text styling:

```dart
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
)
```

### Text Theme

Comprehensive text theme with consistent font family and sizing:

```dart
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
  // ... other text styles
)
```

### Button Themes

Custom button themes for consistent styling:

```dart
// Elevated buttons
elatedButtonTheme: ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  ),
)

// Outlined buttons
outlinedButtonTheme: OutlinedButtonThemeData(
  style: OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: const BorderSide(color: primaryColor),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  ),
)

// Text buttons
textButtonTheme: TextButtonThemeData(
  style: TextButton.styleFrom(
    foregroundColor: primaryColor,
    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
  ),
)
```

### Input Decoration Theme

Consistent input field styling:

```dart
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
)
```

### Card Theme

Custom card styling with shadows and rounded corners:

```dart
cardTheme: CardThemeData(
  color: Colors.white,
  elevation: 4,
  shadowColor: Colors.grey.withValues(alpha: 0.2),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  margin: const EdgeInsets.all(8),
  clipBehavior: Clip.antiAlias,
)
```

### Other Component Themes

1. **Chip Theme**: Custom chip styling
2. **Switch Theme**: Custom switch colors and shapes
3. **Bottom Navigation Bar Theme**: Consistent navigation styling
4. **Slider Theme**: Custom slider appearance
5. **Divider Theme**: Consistent divider styling

## Custom Gradients

The application provides custom gradients for special UI elements:

```dart
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
```

## Custom Decorations

Reusable decoration utilities for consistent UI elements:

```dart
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
```

## Usage Patterns

### Applying Theme

The theme is applied in the main application widget:

```dart
MaterialApp(
  theme: appTheme,
  // ... other configuration
)
```

### Using Theme Colors

Access theme colors directly:

```dart
// Using defined constants
Container(
  color: primaryColor,
  child: Text('Primary Content', style: TextStyle(color: textPrimaryColor)),
)
```

### Using Text Styles

Apply consistent text styling:

```dart
Text(
  'Heading',
  style: Theme.of(context).textTheme.headlineMedium,
)
```

### Using Custom Decorations

Apply consistent decorations:

```dart
Container(
  decoration: AppDecorations.roundedBox(),
  child: Text('Content'),
)

Container(
  decoration: AppDecorations.gradientBox(),
  child: Text('Gradient Content'),
)
```

## Best Practices

1. **Consistent Colors**: Use defined color constants throughout the app
2. **Text Styles**: Use theme text styles for consistent typography
3. **Component Themes**: Leverage component themes for consistent UI elements
4. **Custom Decorations**: Use AppDecorations for consistent box styling
5. **Gradients**: Use AppGradients for consistent gradient effects
6. **Material 3**: Follow Material 3 design principles
7. **Accessibility**: Ensure sufficient color contrast
8. **Responsive Design**: Consider how themes work across different screen sizes

## Extensibility

The theming system supports easy extension:

1. **New Colors**: Add to the color palette constants
2. **New Text Styles**: Extend the textTheme configuration
3. **New Component Themes**: Add new component theme configurations
4. **Custom Decorations**: Add new decoration utilities
5. **New Gradients**: Add to the AppGradients class
6. **Theme Variants**: Create light/dark theme variations

This theming documentation ensures consistent visual design across the application and provides a solid foundation for future enhancements.
