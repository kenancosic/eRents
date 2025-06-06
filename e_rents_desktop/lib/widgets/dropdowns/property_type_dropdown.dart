import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/models/lookup_data.dart';
import 'package:e_rents_desktop/providers/lookup_provider.dart';

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
    return Consumer<LookupProvider>(
      builder: (context, lookupProvider, child) {
        // Show loading spinner while data is being fetched
        if (lookupProvider.isLoading) {
          return const SizedBox(
            height: 48,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        // Show error message if data failed to load
        if (lookupProvider.error != null && !lookupProvider.hasData) {
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

        final propertyTypes = lookupProvider.propertyTypes;

        // Show empty state if no data
        if (propertyTypes.isEmpty) {
          return Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text(
                'No property types available',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          );
        }

        return DropdownButtonFormField<int>(
          value: selectedValue,
          onChanged: enabled ? onChanged : null,
          hint: Text(hintText ?? 'Select Property Type'),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items:
              propertyTypes.map((LookupItem propertyType) {
                return DropdownMenuItem<int>(
                  value: propertyType.id,
                  child: Text(propertyType.name),
                );
              }).toList(),
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
    return Consumer<LookupProvider>(
      builder: (context, lookupProvider, child) {
        if (lookupProvider.isLoading) {
          return const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (lookupProvider.error != null && !lookupProvider.hasData) {
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

        final rentingTypes = lookupProvider.rentingTypes;

        if (rentingTypes.isEmpty) {
          return Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text(
                'No renting types available',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          );
        }

        return DropdownButtonFormField<int>(
          value: selectedValue,
          onChanged: enabled ? onChanged : null,
          hint: Text(hintText ?? 'Select Renting Type'),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items:
              rentingTypes.map((LookupItem rentingType) {
                return DropdownMenuItem<int>(
                  value: rentingType.id,
                  child: Text(rentingType.name),
                );
              }).toList(),
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
    return Consumer<LookupProvider>(
      builder: (context, lookupProvider, child) {
        if (lookupProvider.isLoading) {
          return const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (lookupProvider.error != null && !lookupProvider.hasData) {
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

        final propertyStatuses = lookupProvider.propertyStatuses;

        if (propertyStatuses.isEmpty) {
          return Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text(
                'No property statuses available',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          );
        }

        return DropdownButtonFormField<int>(
          value: selectedValue,
          onChanged: enabled ? onChanged : null,
          hint: Text(hintText ?? 'Select Property Status'),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items:
              propertyStatuses.map((LookupItem status) {
                return DropdownMenuItem<int>(
                  value: status.id,
                  child: Text(status.name),
                );
              }).toList(),
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
