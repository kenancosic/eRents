import 'package:flutter/material.dart';

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
              SizedBox(height: 10),
              Text(
                propertyName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(address),
              SizedBox(height: 10),
              Text(
                'Price: $price',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('Status: $status'),
              SizedBox(height: 10),
              Text(description),
              SizedBox(height: 20),
              Text('Amenities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: amenities.map((amenity) => Chip(label: Text(amenity))).toList(),
              ),
              SizedBox(height: 20),
              Text('Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Image.network(images[index], fit: BoxFit.cover);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
