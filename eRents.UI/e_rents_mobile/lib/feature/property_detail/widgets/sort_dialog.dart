import 'package:e_rents_mobile/feature/home/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SortDialog extends StatefulWidget {
  @override
  _SortDialogState createState() => _SortDialogState();
}

class _SortDialogState extends State<SortDialog> {
  String? _selectedSort;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Sort Properties'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile(
            title: Text('Price: Low to High'),
            value: 'price',
            groupValue: _selectedSort,
            onChanged: (value) {
              setState(() {
                _selectedSort = value as String?;
              });
            },
          ),
          RadioListTile(
            title: Text('Price: High to Low'),
            value: 'price_desc',
            groupValue: _selectedSort,
            onChanged: (value) {
              setState(() {
                _selectedSort = value as String?;
              });
            },
          ),
          RadioListTile(
            title: Text('Rating: High to Low'),
            value: 'rating',
            groupValue: _selectedSort,
            onChanged: (value) {
              setState(() {
                _selectedSort = value as String?;
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
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedSort != null) {
              bool descending = _selectedSort!.endsWith('_desc');
              String sortBy = _selectedSort!.replaceAll('_desc', '');
              Provider.of<HomeProvider>(context, listen: false).setSort(sortBy, descending);
            }
            Navigator.of(context).pop();
          },
          child: Text('Apply'),
        ),
      ],
    );
  }
}
