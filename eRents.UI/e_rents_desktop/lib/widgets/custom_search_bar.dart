import 'package:flutter/material.dart';

class CustomSearchBar<T> extends StatelessWidget {
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onFilterIconPressed;
  final String hintText;
  final bool showFilterIcon;
  final List<String> searchHistory;
  final List<T> localData;
  final bool showSuggestions;
  final String Function(T item)? itemToString;
  final Widget Function(
    T item,
    TextEditingController controller,
    Function(String) onSelected,
  )?
  customSuggestionBuilder;

  const CustomSearchBar({
    super.key,
    this.onSearchChanged,
    this.onFilterIconPressed,
    this.hintText = 'Search...',
    this.showFilterIcon = true,
    required this.searchHistory,
    required this.localData,
    this.showSuggestions = false,
    this.itemToString,
    this.customSuggestionBuilder,
  });

  void _openFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => Container(
            padding: const EdgeInsets.all(16),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Filter Options'),
                // Add your filter widgets (e.g., Chips, Tabs)
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: SearchAnchor.bar(
        barHintStyle: WidgetStateProperty.all(
          const TextStyle(color: Colors.grey, fontWeight: FontWeight.w400),
        ),
        barHintText: hintText,
        barElevation: const WidgetStatePropertyAll(2),
        barLeading: const Icon(Icons.search, size: 20, color: Colors.grey),
        viewHintText: hintText,
        viewBackgroundColor: Colors.grey.shade100,
        barTrailing:
            showFilterIcon
                ? [
                  IconButton(
                    icon: const Icon(
                      Icons.filter_list,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onPressed:
                        onFilterIconPressed ?? () => _openFilterModal(context),
                    style: const ButtonStyle(alignment: Alignment.centerRight),
                  ),
                ]
                : null,
        viewTrailing:
            showFilterIcon
                ? [
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: IconButton(
                      icon: const Icon(
                        Icons.filter_list,
                        size: 20,
                        color: Colors.grey,
                      ),
                      onPressed:
                          onFilterIconPressed ??
                          () => _openFilterModal(context),
                    ),
                  ),
                ]
                : null,
        suggestionsBuilder: (
          BuildContext context,
          TextEditingController controller,
        ) {
          if (controller.text.isEmpty) {
            return searchHistory.map((historyItem) {
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(historyItem),
                onTap: () {
                  controller.text = historyItem;
                  onSearchChanged?.call(historyItem);
                },
              );
            }).toList();
          }

          final suggestions =
              localData.where((item) {
                final String searchString =
                    itemToString != null
                        ? itemToString!(item)
                        : item.toString();
                return searchString.toLowerCase().contains(
                  controller.text.toLowerCase(),
                );
              }).toList();

          return suggestions.map((suggestion) {
            if (customSuggestionBuilder != null) {
              return customSuggestionBuilder!(suggestion, controller, (value) {
                controller.text = value;
                onSearchChanged?.call(value);
              });
            }

            final String displayText =
                itemToString != null
                    ? itemToString!(suggestion)
                    : suggestion.toString();

            return ListTile(
              title: Text(displayText),
              onTap: () {
                controller.text = displayText;
                onSearchChanged?.call(displayText);
              },
            );
          }).toList();
        },
        onChanged: onSearchChanged ?? (query) {},
      ),
    );
  }
}
