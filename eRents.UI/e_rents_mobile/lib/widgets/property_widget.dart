import 'package:flutter/material.dart';

class PropertyWidget extends StatelessWidget {
  final String propertyName;
  final String address;
  final String price;
  final String imageUrl;
  final Function onTap;
  final bool isListItem; // To switch between list and grid view

  const PropertyWidget({
    Key? key,
    required this.propertyName,
    required this.address,
    required this.price,
    required this.imageUrl,
    required this.onTap,
    this.isListItem = false, // Default to grid view
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(),
      child: isListItem
          ? ListTile(
              leading: Image.network(
                imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
              title: Text(
                propertyName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address),
                  Text('Price: $price'),
                ],
              ),
            )
          : Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(imageUrl, fit: BoxFit.cover),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      propertyName,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(address),
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
