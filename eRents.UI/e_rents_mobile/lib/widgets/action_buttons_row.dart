import 'package:flutter/material.dart';

class ActionButtonsRow extends StatelessWidget {
  const ActionButtonsRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.video_library),
          label: const Text("Watch Intro Video"),
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.phone),
          label: const Text("Contact Owner"),
        ),
      ],
    );
  }
}