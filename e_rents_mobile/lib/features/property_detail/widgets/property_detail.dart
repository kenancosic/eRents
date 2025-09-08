// lib/feature/property_detail/widgets/property_details_info.dart
import 'package:flutter/material.dart';

class PropertyDetails extends StatelessWidget {
  final double? averageRating;
  final String? city;
  final String? address;
  final int rooms;
  final String area;
  final int numberOfReviews;

  const PropertyDetails({
    super.key,
    this.averageRating,
    this.city,
    this.address,
    required this.rooms,
    required this.area,
    required this.numberOfReviews,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            spacing: 20,
            runSpacing: 10,
            alignment: WrapAlignment.start,
            runAlignment: WrapAlignment.start,
            children: [
              Column(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem(icon: Icons.star_rounded, text: '${averageRating ?? 'N/A'} ($numberOfReviews reviews)', color: Colors.amber),
                  _buildDetailItem(icon: Icons.location_on_rounded, text: '${city ?? ''}, ${address ?? ''}', color: const Color(0xFF7D7F88)),
                ],
              ),
              Column(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem(icon: Icons.bed, text: rooms.toString(), color: const Color(0xFF7D7F88)),
                  _buildDetailItem(icon: Icons.square_foot_rounded, text: area, color: const Color(0xFF7D7F88)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailItem({required IconData icon, required String text, required Color color}) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          text, 
          style: const TextStyle(color: Colors.black), 
          maxLines: 2,
          textAlign: TextAlign.start, 
          overflow: TextOverflow.ellipsis
        ),
      ],
    );
  }
}