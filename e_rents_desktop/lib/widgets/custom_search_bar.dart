import 'package:flutter/material.dart';

/// Represents a sort option for the CustomSearchBar
class SortOption {
  final String label;
  final String field;
  final IconData? icon;

  const SortOption({
    required this.label,
    required this.field,
    this.icon,
  });
}

// Updated CustomSearchBar to use a simple TextField without SearchAnchor
// Now supports optional sorting dropdown
class CustomSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterPressed;
  final String hintText;
  
  /// Optional list of sort options to display in a dropdown
  final List<SortOption>? sortOptions;
  
  /// Currently selected sort field
  final String? currentSortField;
  
  /// Current sort direction (true = ascending, false = descending)
  final bool sortAscending;
  
  /// Callback when sort option changes: (field, ascending)
  final void Function(String field, bool ascending)? onSortChanged;

  const CustomSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onFilterPressed,
    this.hintText = 'Search...',
    this.sortOptions,
    this.currentSortField,
    this.sortAscending = true,
    this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if the controller has text to potentially show a clear button
    // Note: This requires the parent widget managing the controller to rebuild
    // when the controller's text changes if a clear button is desired.
    // final bool hasText = controller?.text.isNotEmpty ?? false;

    final hasSorting = sortOptions != null && sortOptions!.isNotEmpty;
    
    return Row(
      children: [
        // Search field
        Expanded(
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                suffixIcon:
                    onFilterPressed != null
                        ? IconButton(
                          icon: const Icon(
                            Icons.filter_list,
                            size: 20,
                            color: Colors.grey,
                          ),
                          tooltip: 'Filter Options',
                          onPressed: onFilterPressed,
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: onChanged,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        
        // Sort dropdown (if sort options provided)
        if (hasSorting) ...[
          const SizedBox(width: 12),
          _buildSortDropdown(context),
        ],
      ],
    );
  }
  
  Widget _buildSortDropdown(BuildContext context) {
    final currentOption = sortOptions!.firstWhere(
      (o) => o.field == currentSortField,
      orElse: () => sortOptions!.first,
    );
    
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sort field dropdown
          PopupMenuButton<SortOption>(
            tooltip: 'Sort by',
            offset: const Offset(0, 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    currentOption.icon ?? Icons.sort,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currentOption.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
            itemBuilder: (context) => sortOptions!.map((option) {
              final isSelected = option.field == currentSortField;
              return PopupMenuItem<SortOption>(
                value: option,
                child: Row(
                  children: [
                    if (option.icon != null) ...[
                      Icon(option.icon, size: 18, color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      option.label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onSelected: (option) {
              onSortChanged?.call(option.field, sortAscending);
            },
          ),
          
          // Sort direction toggle
          Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Colors.grey.shade300)),
            ),
            child: IconButton(
              icon: Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 18,
                color: Colors.grey.shade600,
              ),
              tooltip: sortAscending ? 'Ascending' : 'Descending',
              onPressed: () {
                final field = currentSortField ?? sortOptions!.first.field;
                onSortChanged?.call(field, !sortAscending);
              },
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
