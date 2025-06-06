import 'package:flutter/material.dart';
import '../../../models/booking.dart';

class BookingStatusFilter extends StatelessWidget {
  final BookingStatus? selectedStatus;
  final ValueChanged<BookingStatus?> onStatusChanged;

  const BookingStatusFilter({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Status',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // All Status Chip
              FilterChip(
                label: const Text('All'),
                selected: selectedStatus == null,
                onSelected: (selected) {
                  if (selected) {
                    onStatusChanged(null);
                  }
                },
                backgroundColor: Colors.grey[100],
                selectedColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.2),
              ),

              // Status Chips
              ...BookingStatus.values.map(
                (status) => FilterChip(
                  label: Text(status.displayName),
                  selected: selectedStatus == status,
                  onSelected: (selected) {
                    onStatusChanged(selected ? status : null);
                  },
                  backgroundColor: _getStatusColor(
                    status,
                  ).withValues(alpha: 0.1),
                  selectedColor: _getStatusColor(status).withValues(alpha: 0.3),
                  checkmarkColor: _getStatusColor(status),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
        return Colors.blue;
      case BookingStatus.active:
        return Colors.green;
      case BookingStatus.completed:
        return Colors.grey;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }
}
