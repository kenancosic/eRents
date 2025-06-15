import 'package:flutter/material.dart';

class IconSelection<T> extends StatelessWidget {
  final List<T> options;
  final T selectedValue;
  final Function(T) onChanged;
  final IconData Function(T) getIcon;
  final String Function(T) getLabel;
  final Color Function(T)? getColor;
  final bool isWrap;
  final double itemWidth;

  const IconSelection({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    required this.getIcon,
    required this.getLabel,
    this.getColor,
    this.isWrap = false,
    this.itemWidth = 85,
  });

  @override
  Widget build(BuildContext context) {
    final widgets =
        options.map((option) {
          final isSelected = selectedValue == option;
          final icon = getIcon(option);
          final label = getLabel(option);
          final color =
              getColor?.call(option) ?? Theme.of(context).primaryColor;

          final widget = GestureDetector(
            onTap: () => onChanged(option),
            child: Container(
              width: isWrap ? itemWidth : null,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isSelected ? color.withOpacity(0.1) : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: isSelected ? color : Colors.grey.shade600,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? color : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );

          return isWrap
              ? widget
              : Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: widget,
                ),
              );
        }).toList();

    return isWrap
        ? Wrap(spacing: 8, runSpacing: 8, children: widgets)
        : Row(children: widgets);
  }
}
