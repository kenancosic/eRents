import 'package:flutter/material.dart';

class AmenityChip extends StatelessWidget {
  final String amenityName;

  const AmenityChip({required this.amenityName, super.key});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(amenityName),
      backgroundColor: Colors.blueGrey[100],
    );
  }
}
