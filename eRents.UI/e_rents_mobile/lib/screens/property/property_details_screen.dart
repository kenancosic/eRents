import 'package:flutter/material.dart';
import 'package:e_rents_mobile/widgets/action_buttons_row.dart';
import 'package:e_rents_mobile/widgets/simple_button.dart';
import 'package:e_rents_mobile/widgets/custom_snack_bar.dart';

class PropertyDetails extends StatelessWidget {
  final String propertyName;
  final String address;
  final String description;
  final String price;
  final List<String> amenities;
  final List<String> images;
  final String status;

  const PropertyDetails({
    Key? key,
    required this.propertyName,
    required this.address,
    required this.description,
    required this.price,
    required this.amenities,
    required this.images,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(propertyName),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                images.isNotEmpty ? images[0] : '',
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
              ),
              const SizedBox(height: 10),
              Text(
                propertyName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(address),
              const SizedBox(height: 10),
              Text(
                'Price: $price',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text('Status: $status'),
              const SizedBox(height: 10),
              Text(description),
              const SizedBox(height: 20),
              const Text('Amenities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: amenities.map((amenity) => Chip(label: Text(amenity))).toList(),
              ),
              const SizedBox(height: 20),
              const Text('Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Image.network(images[index], fit: BoxFit.cover);
                },
              ),
              const SizedBox(height: 20),
              ActionButtonsRow(
                buttons: [
                  ActionButtonData(
                    label: 'Contact Owner',
                    icon: Icons.phone,
                    onPressed: () {
                      CustomSnackBar.showSuccessSnackBar("Contacting Owner...");
                    },
                  ),
                  ActionButtonData(
                    label: 'Watch Video',
                    icon: Icons.play_circle_filled,
                    onPressed: () {
                      CustomSnackBar.showSuccessSnackBar("Playing Video...");
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SimpleButton(
                text: 'Book Now',
                textColor: Colors.white,
                bgColor: Colors.green,
                onTap: () {
                  CustomSnackBar.showSuccessSnackBar("Booking in progress...");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
