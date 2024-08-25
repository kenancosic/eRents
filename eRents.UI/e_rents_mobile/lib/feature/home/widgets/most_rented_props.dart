import 'package:flutter/material.dart';

class MostRentedProps extends StatelessWidget {
  const MostRentedProps({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSmallPropertyCard(context, 'Sarajevo, K.S.', '345 rented props',
            'https://via.placeholder.com/100'), // Replace with your image URL
        _buildSmallPropertyCard(context, 'Mostar, H.N.K.', '290 rented props',
            'https://via.placeholder.com/100'), // Replace with your image URL
      ],
    );
  }

  Widget _buildSmallPropertyCard(
      BuildContext context, String location, String props, String imageUrl) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imageUrl,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 5),
        Text(location, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(props),
      ],
    );
  }
}
