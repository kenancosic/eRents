import 'package:flutter/material.dart';

class PropertyInfoSection extends StatelessWidget {
  final Map<String, dynamic> property;

  const PropertyInfoSection({Key? key, required this.property}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            const Icon(Icons.hotel, color: Colors.blue),
            const SizedBox(height: 8),
            Text("${property['rooms']} rooms"),
          ],
        ),
        Column(
          children: [
            const Icon(Icons.square_foot, color: Colors.blue),
            const SizedBox(height: 8),
            Text("${property['size']} m²"),
          ],
        ),
        Column(
          children: [
            const Icon(Icons.location_on, color: Colors.blue),
            const SizedBox(height: 8),
            Text(property['location']),
          ],
        ),
      ],
    );
  }
}
