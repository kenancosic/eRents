import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_form_provider.dart';
import 'package:e_rents_desktop/models/enums/property_status.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_status_chip.dart';

/// Atomic widget for property status and availability management.
class StatusSection extends StatelessWidget {
  const StatusSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status & Availability', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        
        // Status dropdown
        Selector<PropertyFormProvider, ({PropertyStatus status, bool hasTenant})>(
          selector: (_, p) => (status: p.state.status, hasTenant: p.state.hasTenant),
          builder: (context, data, _) {
            return PropertyStatusTenantAwareDropdown(
              selected: data.status,
              hasTenant: data.hasTenant,
              onChanged: (status) {
                context.read<PropertyFormProvider>().updateStatus(status);
              },
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        // Unavailable date fields (shown conditionally)
        Selector<PropertyFormProvider, PropertyStatus>(
          selector: (_, p) => p.state.status,
          builder: (context, status, _) {
            if (status != PropertyStatus.unavailable) {
              return const SizedBox.shrink();
            }
            
            return Selector<PropertyFormProvider, ({DateTime? from, DateTime? to})>(
              selector: (_, p) => (
                from: p.state.unavailableFrom,
                to: p.state.unavailableTo,
              ),
              builder: (context, dates, _) {
                return _UnavailableDateFields(
                  unavailableFrom: dates.from,
                  unavailableTo: dates.to,
                  onDateChanged: (from, to) {
                    context.read<PropertyFormProvider>().updateUnavailableDates(from, to);
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/// Internal widget for unavailable date range selection
class _UnavailableDateFields extends StatelessWidget {
  final DateTime? unavailableFrom;
  final DateTime? unavailableTo;
  final void Function(DateTime?, DateTime?) onDateChanged;

  const _UnavailableDateFields({
    required this.unavailableFrom,
    required this.unavailableTo,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unavailability Period',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: 'From',
                value: unavailableFrom,
                onChanged: (date) => onDateChanged(date, unavailableTo),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _DateField(
                label: 'To',
                value: unavailableTo,
                firstDate: unavailableFrom,
                onChanged: (date) => onDateChanged(unavailableFrom, date),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateTime? firstDate;
  final void Function(DateTime?) onChanged;

  const _DateField({
    required this.label,
    required this.value,
    this.firstDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: firstDate ?? DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                ),
              const Icon(Icons.calendar_today, size: 18),
              const SizedBox(width: 8),
            ],
          ),
        ),
        child: Text(
          value != null
              ? '${value!.day}/${value!.month}/${value!.year}'
              : 'Select date',
          style: TextStyle(
            color: value != null 
                ? null 
                : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}
