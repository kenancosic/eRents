import 'package:flutter/material.dart';

class PropertyListItem extends StatelessWidget {
  final String propertyName;
  final String address;
  final String price;
  final String imageUrl;
  final Function onTap;

  const PropertyListItem({
    Key? key,
    required this.propertyName,
    required this.address,
    required this.price,
    required this.imageUrl,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Image.network(
              imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    propertyName,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(address),
                  Text('Price: $price'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
