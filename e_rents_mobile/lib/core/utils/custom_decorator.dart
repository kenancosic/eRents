import 'package:flutter/material.dart';

class CustomDecorations {
  static const BoxDecoration gradientBoxDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF917AFD), Color(0xFF6246EA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );
  
static const BoxDecoration whiteBoxDecoration = BoxDecoration(
  color: Colors.white,
  boxShadow: [
    BoxShadow(
      color: Colors.black26,
      blurRadius: 10.0,
      offset: Offset(0, 5),
    ),
  ],
);


  static const BoxDecoration simpleBoxDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(16)),
    boxShadow: [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 10.0,
        offset: Offset(0, 5),
      ),
    ],
  );
}
