// lib/feature/property_detail/widgets/property_description_section.dart
import 'package:flutter/material.dart';

class PropertyDescriptionSection extends StatefulWidget {
  final String description;

  const PropertyDescriptionSection({
    super.key,
    required this.description,
  });

  @override
  State<PropertyDescriptionSection> createState() => _PropertyDescriptionSectionState();
}

class _PropertyDescriptionSectionState extends State<PropertyDescriptionSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          widget.description,
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? null : TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
          child: Text(
            _expanded ? 'Show Less' : 'Read More',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}