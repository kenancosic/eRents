import 'package:e_rents_mobile/feature/home/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FilterDialog extends StatefulWidget {
  const FilterDialog({Key? key}) : super(key: key);

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
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
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            context.read<HomeProvider>().setFilter(
              city: _selectedCity,
              minPrice: _minPrice,
              maxPrice: _maxPrice,
            );
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
