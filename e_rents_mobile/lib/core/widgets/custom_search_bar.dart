import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomSearchBar extends StatelessWidget {
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onFilterIconPressed;
  final String hintText;
  final bool showFilterIcon;
  final List<String> localData;
  final List<String> searchHistory;

  const CustomSearchBar({
    this.onSearchChanged,
    this.onFilterIconPressed,
    this.hintText = 'Search ',
    this.showFilterIcon = true,
    this.searchHistory = const [],
    this.localData = const [],
    super.key,
  });

  void _openFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
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
          const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w400,
            // fontSize: 16,
          ),
        ),
        barHintText: hintText,
        barElevation: const WidgetStatePropertyAll(10),
        barLeading: SvgPicture.asset(
          'assets/icons/search.svg',
          height: 20,
          alignment: Alignment.center,
        ),
        viewHintText: hintText,
        viewBackgroundColor: Colors.grey[100],
        barTrailing: showFilterIcon
            ? [
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/filters.svg',
                    height: 20,
                  ),
                  onPressed:
                      onFilterIconPressed ?? () => _openFilterModal(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: const ButtonStyle(
                    alignment: Alignment.centerRight,
                  ),
                )
              ]
            : null,
        viewTrailing: showFilterIcon
            ? [
                Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/filters.svg',
                      height: 20,
                    ),
                    onPressed:
                        onFilterIconPressed ?? () => _openFilterModal(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                )
              ]
            : null,
        suggestionsBuilder:
            (BuildContext context, TextEditingController controller) {
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
          final suggestions = localData
              .where((item) =>
                  item.toLowerCase().contains(controller.text.toLowerCase()))
              .toList();
          return suggestions.map((suggestion) {
            return ListTile(
              title: Text(suggestion),
              onTap: () {
                controller.text = suggestion;
                onSearchChanged?.call(suggestion);
              },
            );
          }).toList();
        },
        onChanged: onSearchChanged ?? (query) {},
      ),
    );
  }
}
