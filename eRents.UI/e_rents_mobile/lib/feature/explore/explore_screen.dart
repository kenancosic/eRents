import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(44.5328, 18.6704); // Example: Coordinates for Lukavac

  final Set<Marker> _markers = {
    Marker(
      markerId: MarkerId('marker_1'),
      position: LatLng(44.5328, 18.6704),
      infoWindow: InfoWindow(
        title: '\$2,430',
      ),
    ),
    // Add more markers as needed
  };

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Explore',
      body: Column(
        children: [
          // Google Map View
          Container(
            height: 200.0,
            width: double.infinity,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 14.0,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          // Showing results & Sort row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Showing 72 results',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      'Sort',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Icon(Icons.sort, color: Colors.grey[700]),
                  ],
                ),
              ],
            ),
          ),
          // Property List
          Expanded(
            child: ListView(
              children: const [
                PropertyCard(
                  title: 'Small cottage in the center of town',
                  location: 'Lukavac, T.K., F.BiH',
                  details: '',
                  price: '\$526',
                  rating: '4.8',
                  imageUrl: 'assets/images/house.jpg',
                  review: 73,
                  rooms: 2,
                  area: 673,
                ),
                PropertyCard(
                  title: 'Entire private villa in Tuzla City',
                  location: 'Tuzla, T.K., F.BiH',
                  details: '',
                  price: '\$400',
                  rating: '4.9',
                  imageUrl: 'assets/images/house.jpg',
                  review: 104,
                  rooms: 2,
                  area: 488,
                ),
                PropertyCard(
                  title: 'Entire rental unit, close to main square',
                  location: 'Tuzla, T.K., F.BiH',
                  details: '',
                  price: '\$1,290',
                  rating: '4.8',
                  imageUrl: 'assets/images/house.jpg',
                  review: 73,
                  rooms: 2,
                  area: 874,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
