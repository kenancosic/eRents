import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue),
  textTheme: const TextTheme(
    headlineLarge:TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    // Define more text styles as needed
  ),
  // Add other theme properties as needed
);
