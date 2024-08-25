import 'package:e_rents_mobile/core/models/property.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// class PropertyCard extends StatelessWidget {
//   final Property property;

//   PropertyCard({required this.property});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
//       child: ListTile(
//         title: Text(property.name),
//         subtitle: Text('${property.city}, ${property.price}'),
//         trailing: Text('${property.averageRating} ★'),
//         onTap: () {
//           context.go('/property/${property.propertyId}');        
//           },
//       ),
//     );
//   }
// }

class PropertyCard extends StatelessWidget {
  final String title;
  final String location;
  final String details;
  final String price;
  final String rating;
  final String imageUrl;

  const PropertyCard({
    super.key,
    required this.title,
    required this.location,
    required this.details,
    required this.price,
    required this.rating,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(location),
            const SizedBox(height: 5),
            Text(details),
            const SizedBox(height: 5),
            Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Colors.yellow),
            Text(rating),
          ],
        ),
      ),
    );
  }
}
