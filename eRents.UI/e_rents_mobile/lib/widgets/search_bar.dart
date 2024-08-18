import 'package:flutter/material.dart';

class SearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final Function onSearch;

  const SearchBar({
    Key? key,
    required this.searchController,
    required this.onSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search properties...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => onSearch(),
          ),
        ],
      ),
    );
  }
}
