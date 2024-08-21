import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PropertyCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double price;

  PropertyCard({required this.imageUrl, required this.name, required this.price});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: <Widget>[
          CachedNetworkImage(
            imageUrl: imageUrl,
            placeholder: (context, url) => CircularProgressIndicator(),
            errorWidget: (context, url, error) => Icon(Icons.error),
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          ListTile(
            title: Text(name),
            subtitle: Text('\$$price per night'),
          ),
        ],
      ),
    );
  }
}
