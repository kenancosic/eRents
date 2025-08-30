import 'package:flutter/material.dart';

class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('I need to rent'),
          selected: true,
          onSelected: (selected) {
            // Handle chip selection
          },
        ),
        const SizedBox(width: 10),
        ChoiceChip(
          label: const Text('I want to list'),
          selected: false,
          onSelected: (selected) {
            // Handle chip selection
          },
        ),
      ],
    );
  }
}
