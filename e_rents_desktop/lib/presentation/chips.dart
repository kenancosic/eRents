import 'package:flutter/material.dart';

/// Generic reusable filter chips for enum-like values.
///
/// Usage:
/// EnumFilterChips<MaintenanceIssueStatus>(
///   values: MaintenanceIssueStatus.values,
///   selected: selectedStatuses,
///   labelBuilder: (s) => s.displayName,
///   colorBuilder: (s) => s.color,
///   onChanged: (newSet) => setState(() => selectedStatuses = newSet),
/// )
class EnumFilterChips<T> extends StatelessWidget {
  final List<T> values;
  final Set<T> selected;
  final String Function(T value) labelBuilder;
  final Color Function(T value)? colorBuilder;
  final void Function(Set<T> newSelected) onChanged;
  final double spacing;
  final double runSpacing;
  final bool outlined;

  const EnumFilterChips({
    super.key,
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
    this.colorBuilder,
    this.spacing = 8,
    this.runSpacing = 4,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: values.map((v) {
        final bool isSelected = selected.contains(v);
        final Color? baseColor = colorBuilder?.call(v);
        final Color selectedColor = baseColor ?? Theme.of(context).colorScheme.primary;
        final Color unselectedColor = Theme.of(context).chipTheme.labelStyle?.color ?? Colors.black87;

        return FilterChip(
          label: Text(labelBuilder(v)),
          selected: isSelected,
          showCheckmark: false,
          onSelected: (sel) {
            final next = Set<T>.from(selected);
            if (sel) {
              next.add(v);
            } else {
              next.remove(v);
            }
            onChanged(next);
          },
          labelStyle: TextStyle(
            color: isSelected ? (outlined ? selectedColor : Colors.white) : unselectedColor,
            fontWeight: FontWeight.w600,
          ),
          side: outlined
              ? BorderSide(color: isSelected ? selectedColor : (baseColor ?? Colors.grey.shade400))
              : BorderSide.none,
          backgroundColor: outlined
              ? Colors.transparent
              : (isSelected
                  ? selectedColor
                  : Theme.of(context).chipTheme.backgroundColor ?? Colors.grey.shade200),
          selectedColor: outlined
              ? Colors.transparent
              : selectedColor,
        );
      }).toList(),
    );
  }
}
