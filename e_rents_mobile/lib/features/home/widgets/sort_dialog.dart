import 'package:e_rents_mobile/features/explore/providers/property_search_provider.dart';
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
          _buildOption(title: 'Price: Low to High', value: 'price'),
          _buildOption(title: 'Price: High to Low', value: 'price_desc'),
          _buildOption(title: 'Rating: High to Low', value: 'rating'),
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
              final provider = context.read<PropertySearchProvider>();
              provider.applySortOption(_selectedSort);
            }
            context.pop();
          },
        ),
      ],
    );
  }

  Widget _buildOption({required String title, required String value}) {
    final bool selected = _selectedSort == value;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? Theme.of(context).colorScheme.primary : Colors.grey,
      ),
      title: Text(title),
      onTap: () {
        setState(() {
          _selectedSort = value;
        });
      },
    );
  }
}
