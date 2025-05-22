import 'package:e_rents_mobile/feature/home/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SortDialog extends StatefulWidget {
  const SortDialog({super.key});

  @override
  _SortDialogState createState() => _SortDialogState();
}

class _SortDialogState extends State<SortDialog> {
  String? _selectedSort;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sort Properties'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile(
            title: const Text('Price: Low to High'),
            value: 'price',
            groupValue: _selectedSort,
            onChanged: (value) {
              setState(() {
                _selectedSort = value;
              });
            },
          ),
          RadioListTile(
            title: const Text('Price: High to Low'),
            value: 'price_desc',
            groupValue: _selectedSort,
            onChanged: (value) {
              setState(() {
                _selectedSort = value;
              });
            },
          ),
          RadioListTile(
            title: const Text('Rating: High to Low'),
            value: 'rating',
            groupValue: _selectedSort,
            onChanged: (value) {
              setState(() {
                _selectedSort = value;
              });
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
            if (_selectedSort != null) {
              bool descending = _selectedSort!.endsWith('_desc');
              String sortBy = _selectedSort!.replaceAll('_desc', '');
              final provider = context.read<HomeProvider>();
              final filter = provider.filter;
              filter.sortBy = sortBy;
              filter.sortDescending = descending;
              provider.filterProperties(filter);
            }
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
