import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapView extends StatelessWidget {
  final double latitude;
  final double longitude;

  const MapView({required this.latitude, required this.longitude, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: 14,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('property_location'),
            position: LatLng(latitude, longitude),
          ),
        },
      ),
    );
  }
}
