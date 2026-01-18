import 'package:flutter/material.dart';

/// A sort option configuration
class SortOption {
  final String value;
  final String label;
  final IconData? icon;

  const SortOption({
    required this.value,
    required this.label,
    this.icon,
  });
}

/// Reusable sorting options widget for filter panels
class SortOptionsWidget extends StatelessWidget {
  final String? selectedSortBy;
  final bool ascending;
  final List<SortOption> options;
  final ValueChanged<String?> onSortByChanged;
  final ValueChanged<bool> onAscendingChanged;
  final String sortByLabel;
  final String orderLabel;

  const SortOptionsWidget({
    super.key,
    required this.selectedSortBy,
    required this.ascending,
    required this.options,
    required this.onSortByChanged,
    required this.onAscendingChanged,
    this.sortByLabel = 'Sort By',
    this.orderLabel = 'Order',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(sortByLabel, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String?>(
                value: selectedSortBy,
                decoration: InputDecoration(
                  labelText: 'Sort Field',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.sort),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('Default'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Default'),
                  ),
                  ...options.map((opt) => DropdownMenuItem<String?>(
                    value: opt.value,
                    child: Row(
                      children: [
                        if (opt.icon != null) ...[
                          Icon(opt.icon, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                        ],
                        Text(opt.label),
                      ],
                    ),
                  )),
                ],
                onChanged: onSortByChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<bool>(
                value: ascending,
                decoration: InputDecoration(
                  labelText: orderLabel,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(
                    value: true,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_upward, size: 16),
                        SizedBox(width: 4),
                        Text('Ascending'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: false,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_downward, size: 16),
                        SizedBox(width: 4),
                        Text('Descending'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) => onAscendingChanged(value ?? true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Pre-defined sort options for bookings
const List<SortOption> bookingSortOptions = [
  SortOption(value: 'startdate', label: 'Start Date', icon: Icons.calendar_today),
  SortOption(value: 'enddate', label: 'End Date', icon: Icons.event),
  SortOption(value: 'totalprice', label: 'Total Price', icon: Icons.attach_money),
  SortOption(value: 'createdat', label: 'Date Created', icon: Icons.schedule),
  SortOption(value: 'status', label: 'Status', icon: Icons.flag),
];

/// Pre-defined sort options for tenants
const List<SortOption> tenantSortOptions = [
  SortOption(value: 'leasestartdate', label: 'Lease Start Date', icon: Icons.calendar_today),
  SortOption(value: 'leaseenddate', label: 'Lease End Date', icon: Icons.event),
  SortOption(value: 'fullname', label: 'Tenant Name', icon: Icons.person),
  SortOption(value: 'createdat', label: 'Date Added', icon: Icons.schedule),
];

/// Pre-defined sort options for payments
const List<SortOption> paymentSortOptions = [
  SortOption(value: 'createdat', label: 'Date', icon: Icons.calendar_today),
  SortOption(value: 'amount', label: 'Amount', icon: Icons.attach_money),
  SortOption(value: 'status', label: 'Status', icon: Icons.flag),
];
