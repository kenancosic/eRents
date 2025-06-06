import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../base/base.dart';
import '../../models/booking.dart';
import 'providers/booking_collection_provider.dart';
import 'widgets/booking_filter_bar.dart';
import 'widgets/booking_list_item.dart';
import 'widgets/booking_stats_card.dart';
import 'widgets/booking_status_filter.dart';

/// Main bookings screen for landlords to manage property bookings
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  BookingStatus? _selectedStatus;
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date', 'price', 'property'
  bool _sortDescending = true;

  @override
  void initState() {
    super.initState();
    // Load bookings when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookings();
    });
  }

  void _loadBookings() {
    final provider = context.read<BookingCollectionProvider>();
    // Load landlord bookings (all bookings for landlord's properties)
    provider.loadLandlordBookings();
  }

  void _refreshBookings() {
    final provider = context.read<BookingCollectionProvider>();
    provider.refreshItems();
  }

  List<Booking> _getFilteredAndSortedBookings(List<Booking> bookings) {
    List<Booking> filtered = bookings;

    // Filter by status
    if (_selectedStatus != null) {
      filtered =
          filtered
              .where((booking) => booking.status == _selectedStatus)
              .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered.where((booking) {
            final propertyName = booking.propertyName?.toLowerCase() ?? '';
            final userName = booking.userName?.toLowerCase() ?? '';
            final bookingId = booking.bookingId.toString();
            return propertyName.contains(query) ||
                userName.contains(query) ||
                bookingId.contains(query);
          }).toList();
    }

    // Sort bookings
    filtered.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'date':
          comparison = a.startDate.compareTo(b.startDate);
          break;
        case 'price':
          comparison = a.totalPrice.compareTo(b.totalPrice);
          break;
        case 'property':
          comparison = (a.propertyName ?? '').compareTo(b.propertyName ?? '');
          break;
      }

      return _sortDescending ? -comparison : comparison;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<BookingCollectionProvider>(
        builder: (context, provider, child) {
          if (provider.state.isLoading && provider.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load bookings',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error?.message ?? 'Unknown error occurred',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadBookings,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final filteredBookings = _getFilteredAndSortedBookings(
            provider.items,
          );

          return Column(
            children: [
              // Header with stats - commented out for now
              // if (provider.hasData) ...[
              //   BookingStatsCard(bookings: provider.items),
              //   const SizedBox(height: 16),
              // ],

              // Simple header for now
              if (provider.hasData) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Total Bookings: ${provider.items.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        'Revenue: ${provider.totalRevenue.toStringAsFixed(2)} BAM',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Simple filter bar for now
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search bookings...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: _refreshBookings,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Simple status filter
              if (provider.hasData) ...[
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildStatusChip(null, 'All', provider.items.length),
                      const SizedBox(width: 8),
                      _buildStatusChip(
                        BookingStatus.upcoming,
                        'Upcoming',
                        provider.upcomingBookings.length,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(
                        BookingStatus.active,
                        'Active',
                        provider.activeBookings.length,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(
                        BookingStatus.completed,
                        'Completed',
                        provider.completedBookings.length,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(
                        BookingStatus.cancelled,
                        'Cancelled',
                        provider.cancelledBookings.length,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Bookings list
              Expanded(child: _buildBookingsList(filteredBookings, provider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(BookingStatus? status, String label, int count) {
    final isSelected = _selectedStatus == status;

    return FilterChip(
      selected: isSelected,
      label: Text('$label ($count)'),
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
        });
      },
    );
  }

  Widget _buildBookingsList(
    List<Booking> bookings,
    BookingCollectionProvider provider,
  ) {
    if (bookings.isEmpty) {
      String emptyMessage = 'No bookings found';

      if (_selectedStatus != null) {
        emptyMessage =
            'No ${_selectedStatus!.displayName.toLowerCase()} bookings found';
      } else if (_searchQuery.isNotEmpty) {
        emptyMessage = 'No bookings match your search';
      } else if (provider.isEmpty) {
        emptyMessage = 'No bookings yet';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            if (provider.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Bookings from tenants will appear here',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshBookings(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.propertyName ?? 'Unknown Property',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Booking #${booking.bookingId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(booking.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  booking.userName ?? 'Unknown Tenant',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Icon(
                  Icons.attach_money,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  booking.formattedPrice,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  booking.dateRange,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Icon(
                  Icons.people,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  '${booking.numberOfGuests} guests',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            if (booking.canBeCancelled) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showCancelDialog(booking),
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Cancel Booking'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    Color badgeColor;
    Color textColor;

    switch (status) {
      case BookingStatus.upcoming:
        badgeColor = Colors.blue;
        textColor = Colors.white;
        break;
      case BookingStatus.active:
        badgeColor = Colors.green;
        textColor = Colors.white;
        break;
      case BookingStatus.completed:
        badgeColor = Colors.grey;
        textColor = Colors.white;
        break;
      case BookingStatus.cancelled:
        badgeColor = Colors.red;
        textColor = Colors.white;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showCancelDialog(Booking booking) {
    showDialog(
      context: context,
      builder:
          (context) => _CancelBookingDialog(
            booking: booking,
            onConfirm: (reason, requestRefund) async {
              try {
                final provider = context.read<BookingCollectionProvider>();
                await provider.cancelBooking(
                  booking.bookingId,
                  cancellationReason: reason,
                  requestRefund: requestRefund,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Booking #${booking.bookingId} has been cancelled',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel booking: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
    );
  }
}

/// Dialog for cancelling a booking
class _CancelBookingDialog extends StatefulWidget {
  final Booking booking;
  final Function(String? reason, bool requestRefund) onConfirm;

  const _CancelBookingDialog({required this.booking, required this.onConfirm});

  @override
  State<_CancelBookingDialog> createState() => _CancelBookingDialogState();
}

class _CancelBookingDialogState extends State<_CancelBookingDialog> {
  final _reasonController = TextEditingController();
  bool _requestRefund = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Booking'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel booking #${widget.booking.bookingId}?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),

            Text(
              'Property: ${widget.booking.propertyName ?? 'Unknown'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Tenant: ${widget.booking.userName ?? 'Unknown'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Total: ${widget.booking.formattedPrice}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason (Optional)',
                hintText: 'Enter reason for cancellation...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            CheckboxListTile(
              value: _requestRefund,
              onChanged: (value) {
                setState(() {
                  _requestRefund = value ?? false;
                });
              },
              title: const Text('Request Refund'),
              subtitle: const Text(
                'Process refund according to cancellation policy',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleCancel,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Cancel Booking'),
        ),
      ],
    );
  }

  Future<void> _handleCancel() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onConfirm(
        _reasonController.text.isEmpty ? null : _reasonController.text,
        _requestRefund,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Error handling is done in the parent
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
