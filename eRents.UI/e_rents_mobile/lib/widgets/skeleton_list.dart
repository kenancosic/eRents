import 'package:flutter/material.dart';

class SkeletonList extends StatelessWidget {
  final int itemCount;

  const SkeletonList({super.key, required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
    );
  }
}
