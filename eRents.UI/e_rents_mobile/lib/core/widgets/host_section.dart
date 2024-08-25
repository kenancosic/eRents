import 'package:flutter/material.dart';

class HostSection extends StatelessWidget {
  const HostSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Want to host your own place?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                    'Earn passive income by renting or selling your property'),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle hosting action
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Active as Landlord'),
          ),
        ],
      ),
    );
  }
}
