import 'package:flutter/material.dart';
import 'package:e_rents_mobile/widgets/image_carousel.dart';
import 'package:e_rents_mobile/widgets/property_info_section.dart';
import 'package:e_rents_mobile/widgets/facilities_list.dart';
import 'package:e_rents_mobile/widgets/map_view.dart';
import 'package:e_rents_mobile/widgets/action_buttons_row.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> property;

  const PropertyDetailsScreen({Key? key, required this.property}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Property Details"),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImageCarousel(images: property['images']),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property['title'],
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property['location'],
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  PropertyInfoSection(property: property),
                  const SizedBox(height: 16),
                  FacilitiesList(facilities: property['facilities']),
                  const SizedBox(height: 16),
                  const Text(
                    "Nearby Facilities",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  MapView(location: property['location']),
                  const SizedBox(height: 16),
                  const Text(
                    "About this Property",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(property['description']),
                  const SizedBox(height: 16),
                  ActionButtonsRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
