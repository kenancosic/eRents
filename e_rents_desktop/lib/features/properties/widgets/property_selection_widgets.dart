import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/renting_type.dart';

class PropertySelectionWidgets {
  /// Generic icon selection widget
  static Widget buildIconSelection<T>({
    required List<T> options,
    required T selectedValue,
    required Function(T) onChanged,
    required IconData Function(T) getIcon,
    required String Function(T) getLabel,
    required BuildContext context,
    Color Function(T)? getColor,
    String? Function(T)? getAssetPath,
    bool isWrap = false,
    double itemWidth = 85,
  }) {
    final widgets =
        options.map((option) {
          final isSelected = selectedValue == option;
          final icon = getIcon(option);
          final label = getLabel(option);
          final color =
              getColor?.call(option) ?? Theme.of(context).primaryColor;
          final assetPath = getAssetPath?.call(option);

          Widget iconWidget;
          if (assetPath != null) {
            iconWidget = Image.asset(
              assetPath,
              width: 24,
              height: 24,
              color: isSelected ? color : Colors.grey.shade600,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.home,
                  size: 24,
                  color: isSelected ? color : Colors.grey.shade600,
                );
              },
            );
          } else {
            iconWidget = Icon(
              icon,
              size: 24,
              color: isSelected ? color : Colors.grey.shade600,
            );
          }

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
                borderRadius: BorderRadius.circular(6),
                color: isSelected ? color.withOpacity(0.1) : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  iconWidget,
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
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
        ? Wrap(spacing: 6, runSpacing: 6, children: widgets)
        : Row(children: widgets);
  }

  /// Renting type selection
  static Widget buildRentingTypeSelection({
    required RentingType selectedType,
    required Function(RentingType) onChanged,
    required BuildContext context,
  }) {
    return buildIconSelection<RentingType>(
      options: RentingType.values,
      selectedValue: selectedType,
      onChanged: onChanged,
      context: context,
      getIcon: (type) {
        switch (type) {
          case RentingType.monthly:
            return Icons.calendar_month;
          case RentingType.daily:
            return Icons.today;
        }
      },
      getLabel: (type) {
        switch (type) {
          case RentingType.monthly:
            return 'Monthly';
          case RentingType.daily:
            return 'Daily';
        }
      },
    );
  }

  /// Property type selection
  static Widget buildPropertyTypeSelection({
    required PropertyType selectedType,
    required Function(PropertyType) onChanged,
    required BuildContext context,
  }) {
    return buildIconSelection<PropertyType>(
      options: PropertyType.values,
      selectedValue: selectedType,
      onChanged: onChanged,
      context: context,
      isWrap: true,
      getIcon: (type) => Icons.home, // Fallback icon
      getLabel: (type) => _capitalizeFirst(type.toString().split('.').last),
      getAssetPath:
          (type) => 'assets/icons/${type.toString().split('.').last}.png',
    );
  }

  /// Status selection
  static Widget buildStatusSelection({
    required PropertyStatus selectedStatus,
    required Function(PropertyStatus) onChanged,
    required BuildContext context,
  }) {
    return buildIconSelection<PropertyStatus>(
      options: PropertyStatus.values,
      selectedValue: selectedStatus,
      onChanged: onChanged,
      context: context,
      getIcon: (status) {
        switch (status) {
          case PropertyStatus.available:
            return Icons.check_circle;
          case PropertyStatus.rented:
            return Icons.home;
          case PropertyStatus.maintenance:
            return Icons.build;
          case PropertyStatus.unavailable:
            return Icons.block;
        }
      },
      getLabel: (status) => _capitalizeFirst(status.toString().split('.').last),
      getColor: (status) {
        switch (status) {
          case PropertyStatus.available:
            return Colors.green;
          case PropertyStatus.rented:
            return Colors.blue;
          case PropertyStatus.maintenance:
            return Colors.orange;
          case PropertyStatus.unavailable:
            return Colors.red;
        }
      },
    );
  }

  static String _capitalizeFirst(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }
}
