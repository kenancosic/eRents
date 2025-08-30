import 'package:e_rents_mobile/features/property_detail/providers/property_detail_provider.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class SortDialog extends StatefulWidget {
  const SortDialog({super.key});

  @override
  SortDialogState createState() => SortDialogState();
}

class SortDialogState extends State<SortDialog> {
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
        CustomOutlinedButton.compact(
          label: 'Cancel',
          isLoading: false,
          onPressed: () {
            context.pop();
          },
        ),
        CustomButton.compact(
          label: 'Apply',
          isLoading: false,
          onPressed: () {
            if (_selectedSort != null) {
              bool descending = _selectedSort!.endsWith('_desc');
              String sortBy = _selectedSort!.replaceAll('_desc', '');
              final provider = context.read<PropertyDetailProvider>();
              provider.applyPropertyFilters({
                'sortBy': sortBy,
                'sortDescending': descending,
              });
            }
            context.pop();
          },
        ),
      ],
    );
  }
}
