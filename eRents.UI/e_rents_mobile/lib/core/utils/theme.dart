import 'package:flutter/material.dart';

const Color primaryColor = Color(0xff31448F);
const Color secondaryColor = Colors.orange;
const Color backgroundColor = Color(0xFFFCFCFC);

final ThemeData appTheme = ThemeData(
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.indigo,
  ).copyWith(
    secondary: secondaryColor,
    surface: backgroundColor,
  ),
  scaffoldBackgroundColor: backgroundColor,
  appBarTheme:const  AppBarTheme(
    backgroundColor: backgroundColor,
    iconTheme:  IconThemeData(color: primaryColor),
    titleTextStyle: TextStyle(
      color: primaryColor,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    elevation: 0,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontFamily: 'Hind', fontWeight: FontWeight.bold, fontSize: 32),
    displayMedium: TextStyle(fontFamily: 'Hind', fontWeight: FontWeight.bold, fontSize: 28),
    displaySmall: TextStyle(fontFamily: 'Hind', fontWeight: FontWeight.bold, fontSize: 24),
    headlineMedium: TextStyle(fontFamily: 'Hind', fontWeight: FontWeight.bold, fontSize: 20),
    headlineSmall: TextStyle(fontFamily: 'Hind', fontWeight: FontWeight.bold, fontSize: 18),
    titleLarge: TextStyle(fontFamily: 'Hind', fontWeight: FontWeight.bold, fontSize: 16),
    bodyLarge: TextStyle(fontFamily: 'Hind', fontWeight: FontWeight.normal, fontSize: 14),
    bodyMedium: TextStyle(fontFamily: 'Hind', fontWeight: FontWeight.normal, fontSize: 12),
    bodySmall: TextStyle(
      fontSize: 12.0,
      fontWeight: FontWeight.w400,
      color: Colors.grey,
    ),
    labelLarge: TextStyle(fontFamily: 'Hind', fontWeight: FontWeight.normal, fontSize: 10),
  ),
  buttonTheme: const ButtonThemeData(
    buttonColor: primaryColor,
    textTheme: ButtonTextTheme.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20.0)),
    ),
  ),
   bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: primaryColor,
    unselectedItemColor: Colors.grey,
  ),
);
