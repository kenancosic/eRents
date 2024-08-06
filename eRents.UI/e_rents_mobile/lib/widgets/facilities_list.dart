import 'package:flutter/material.dart';

class FacilitiesList extends StatelessWidget {
  final List<String> facilities;

  const FacilitiesList({Key? key, required this.facilities}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: facilities.map((facility) {
        return Chip(label: Text(facility));
      }).toList(),
    );
  }
}
