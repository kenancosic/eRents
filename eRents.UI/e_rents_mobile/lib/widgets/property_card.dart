import 'package:flutter/material.dart';

class PropertyCard extends StatelessWidget {
  final String name;
  final String location;
  final double price;
  final String imageUrl;
  final Function onTap;

  const PropertyCard({
    Key? key,
    required this.name,
    required this.location,
    required this.price,
    required this.imageUrl,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(imageUrl, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(location),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('\$$price per night', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      ),
    );
  }
}
