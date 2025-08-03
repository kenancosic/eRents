import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/property_type.dart';
import 'package:e_rents_desktop/widgets/icon_selection.dart';
import 'package:flutter/material.dart';

class PropertyTypeSelection extends StatelessWidget {
  final PropertyType selectedType;
  final Function(PropertyType) onChanged;

  const PropertyTypeSelection({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return IconSelection<PropertyType>(
      options: PropertyType.values,
      selectedValue: selectedType,
      onChanged: onChanged,
      isWrap: true,
      getIcon: (type) {
        switch (type) {
          case PropertyType.apartment:
            return Icons.apartment;
          case PropertyType.house:
            return Icons.house;
          case PropertyType.condo:
            return Icons.business;
          case PropertyType.townhouse:
            return Icons.home_work;
          case PropertyType.studio:
            return Icons.person;
        }
      },
      getLabel: (type) => type.toString().split('.').last,
    );
  }
}
