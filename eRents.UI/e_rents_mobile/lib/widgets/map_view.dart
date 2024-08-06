import 'package:flutter/material.dart';

class MapView extends StatelessWidget {
  final String location;

  const MapView({Key? key, required this.location}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[300],
      child: Center(child: Text("Map of $location")),
      // Use an actual map widget like Google Maps Plugin for a real map
    );
  }
}
