import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/core/lookups/lookup_key.dart';
import 'package:e_rents_desktop/core/lookups/lookup_registry.dart';
import 'package:e_rents_desktop/providers/lookup_provider.dart';

/// A generic dropdown form field for use with lookup data.
class CustomDropdown<TValue> extends StatelessWidget {
  final String label;
  final TValue? value;
  final List<dynamic> items;
  final ValueChanged<TValue?> onChanged;
  final String Function(dynamic) itemToString;
  final TValue Function(dynamic) itemToValue;
  final String? Function(TValue?)? validator;
  final bool enabled;
  final bool includeAny;
  final String anyLabel;
  final TValue? anyValue;

  const CustomDropdown({
    super.key,
    required this.label,
    this.value,
    required this.items,
    required this.onChanged,
    required this.itemToString,
    required this.itemToValue,
    this.validator,
    this.enabled = true,
    this.includeAny = false,
    this.anyLabel = 'Any',
    this.anyValue,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TValue>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        if (includeAny)
          DropdownMenuItem<TValue>(
            value: anyValue,
            child: Text(anyLabel),
          ),
        ...items.map((item) {
          return DropdownMenuItem<TValue>(
            value: itemToValue(item),
            child: Text(itemToString(item)),
          );
        }),
      ],
      onChanged: enabled ? onChanged : null,
      validator: validator,
    );
  }
}

/// Convenience widget: builds a dropdown from the centralized LookupProvider/Registry
/// using a LookupKey. This avoids duplicating enum/lookup mapping logic in widgets.
class LookupDropdown extends StatelessWidget {
  final String label;
  final LookupKey lookupKey;
  final int? value;
  final ValueChanged<int?> onChanged;
  final String? Function(int?)? validator;
  final bool enabled;
  final bool includeAny;
  final String anyLabel;
  final int? anyValue;

  const LookupDropdown({
    super.key,
    required this.label,
    required this.lookupKey,
    required this.value,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    this.includeAny = false,
    this.anyLabel = 'Any',
    this.anyValue,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LookupProvider>(
      builder: (context, provider, _) {
        final List<DropdownItem> dropdownItems = provider.dropdownItems(lookupKey);
        return CustomDropdown<int>(
          label: label,
          value: value,
          items: dropdownItems,
          itemToString: (dynamic item) => (item as DropdownItem).label,
          itemToValue: (dynamic item) => (item as DropdownItem).value,
          onChanged: onChanged,
          validator: validator,
          enabled: enabled,
          includeAny: includeAny,
          anyLabel: anyLabel,
          anyValue: anyValue,
        );
      },
    );
  }
}
