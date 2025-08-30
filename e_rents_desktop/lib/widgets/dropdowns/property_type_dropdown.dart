import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/providers/lookup_provider.dart';
import 'package:e_rents_desktop/base/lookups/lookup_key.dart';
import 'package:e_rents_desktop/widgets/inputs/custom_dropdown.dart';

class PropertyTypeDropdown extends StatelessWidget {
  final int? selectedValue;
  final ValueChanged<int?> onChanged;
  final String? hintText;
  final bool enabled;

  const PropertyTypeDropdown({
    super.key,
    this.selectedValue,
    required this.onChanged,
    this.hintText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final lookup = context.read<LookupProvider>();
    return FutureBuilder(
      future: lookup.getPropertyTypes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasError) {
          return Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                'Failed to load property types',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }

        return LookupDropdown(
          label: hintText ?? 'Select Property Type',
          lookupKey: LookupKey.propertyType,
          value: selectedValue,
          onChanged: onChanged,
          enabled: enabled,
          validator: (value) {
            if (value == null) {
              return 'Please select a property type';
            }
            return null;
          },
        );
      },
    );
  }
}

class RentingTypeDropdown extends StatelessWidget {
  final int? selectedValue;
  final ValueChanged<int?> onChanged;
  final String? hintText;
  final bool enabled;

  const RentingTypeDropdown({
    super.key,
    this.selectedValue,
    required this.onChanged,
    this.hintText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final lookup = context.read<LookupProvider>();
    return FutureBuilder(
      future: lookup.getRentingTypes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                'Failed to load renting types',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }

        return LookupDropdown(
          label: hintText ?? 'Select Renting Type',
          lookupKey: LookupKey.rentingType,
          value: selectedValue,
          onChanged: onChanged,
          enabled: enabled,
          validator: (value) {
            if (value == null) {
              return 'Please select a renting type';
            }
            return null;
          },
        );
      },
    );
  }
}

class PropertyStatusDropdown extends StatelessWidget {
  final int? selectedValue;
  final ValueChanged<int?> onChanged;
  final String? hintText;
  final bool enabled;

  const PropertyStatusDropdown({
    super.key,
    this.selectedValue,
    required this.onChanged,
    this.hintText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final lookup = context.read<LookupProvider>();
    return FutureBuilder(
      future: lookup.getPropertyStatuses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                'Failed to load property statuses',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }

        return LookupDropdown(
          label: hintText ?? 'Select Property Status',
          lookupKey: LookupKey.propertyStatus,
          value: selectedValue,
          onChanged: onChanged,
          enabled: enabled,
          validator: (value) {
            if (value == null) {
              return 'Please select a property status';
            }
            return null;
          },
        );
      },
    );
  }
}
