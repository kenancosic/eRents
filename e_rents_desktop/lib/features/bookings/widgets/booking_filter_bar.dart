import 'package:flutter/material.dart';
import '../../../models/booking.dart';

class BookingFilterBar extends StatelessWidget {
  final BookingStatus? selectedStatus;
  final String searchQuery;
  final String selectedSort;
  final ValueChanged<BookingStatus?> onStatusChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSortChanged;

  const BookingFilterBar({
    super.key,
    required this.selectedStatus,
    required this.searchQuery,
    required this.selectedSort,
    required this.onStatusChanged,
    required this.onSearchChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Status Filter
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter by Status',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<BookingStatus?>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<BookingStatus?>(
                          value: null,
                          child: Text('All Status'),
                        ),
                        ...BookingStatus.values.map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.displayName),
                          ),
                        ),
                      ],
                      onChanged: onStatusChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Search
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: searchQuery,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText:
                            'Search by property, tenant, or booking ID...',
                        prefixIcon: Icon(Icons.search),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: onSearchChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Sort
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sort by',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedSort,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'date_desc',
                          child: Text('Newest First'),
                        ),
                        DropdownMenuItem(
                          value: 'date_asc',
                          child: Text('Oldest First'),
                        ),
                        DropdownMenuItem(
                          value: 'price_desc',
                          child: Text('Price: High to Low'),
                        ),
                        DropdownMenuItem(
                          value: 'price_asc',
                          child: Text('Price: Low to High'),
                        ),
                        DropdownMenuItem(
                          value: 'property',
                          child: Text('Property Name'),
                        ),
                      ],
                      onChanged: (value) => onSortChanged(value ?? 'date_desc'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
