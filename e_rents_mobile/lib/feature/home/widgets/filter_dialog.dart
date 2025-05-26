// Removed FilterModel import - using direct parameters instead
import 'package:e_rents_mobile/feature/home/home_provider.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key});

  @override
  FilterDialogState createState() => FilterDialogState();
}

class FilterDialogState extends State<FilterDialog> {
  String? _selectedCity;
  double? _minPrice;
  double? _maxPrice;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Properties'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'City'),
            value: _selectedCity,
            onChanged: (value) {
              setState(() {
                _selectedCity = value;
              });
            },
            items: const [
              DropdownMenuItem(value: 'City1', child: Text('City1')),
              DropdownMenuItem(value: 'City2', child: Text('City2')),
              // Add more cities as needed
            ],
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Min Price'),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _minPrice = double.tryParse(value);
            },
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Max Price'),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _maxPrice = double.tryParse(value);
            },
          ),
        ],
      ),
      actions: [
        CustomOutlinedButton.compact(
          label: 'Cancel',
          isLoading: false,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        CustomButton.compact(
          label: 'Apply',
          isLoading: false,
          onPressed: () {
            context.read<HomeProvider>().filterProperties(
                  city: _selectedCity,
                  minPrice: _minPrice,
                  maxPrice: _maxPrice,
                );
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
