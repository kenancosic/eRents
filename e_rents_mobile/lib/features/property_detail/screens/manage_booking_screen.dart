import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/enums/booking_enums.dart';
import 'package:e_rents_mobile/core/models/property_detail.dart';
import 'package:e_rents_mobile/features/property_detail/providers/property_rental_provider.dart';
import 'package:e_rents_mobile/features/property_detail/widgets/extend_booking_dialog.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';

class ManageBookingScreen extends StatefulWidget {
  final int propertyId;
  final int bookingId;
  final Booking? booking;

  const ManageBookingScreen({
    super.key,
    required this.propertyId,
    required this.bookingId,
    this.booking,
  });

  @override
  State<ManageBookingScreen> createState() => _ManageBookingScreenState();
}

class _ManageBookingScreenState extends State<ManageBookingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Booking? _findBookingById(PropertyRentalProvider provider, int bookingId) {
    try {
      return provider.bookings.firstWhere((b) => b.bookingId == bookingId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadData() async {
    final provider = Provider.of<PropertyRentalProvider>(context, listen: false);
    await provider.fetchBookings(widget.propertyId);
    await provider.fetchPropertyDetails(widget.propertyId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Manage Booking',
        showBackButton: true,
      ),
      body: Consumer<PropertyRentalProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && (provider.property == null || provider.bookings.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }

          final booking = _findBookingById(provider, widget.bookingId) ?? widget.booking;
          final property = provider.property;

          if (booking == null || property == null) {
            return const Center(child: Text('Booking or property details not found.'));
          }

          if (provider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage.isNotEmpty 
                        ? provider.errorMessage 
                        : 'An error occurred',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    label: 'Retry',
                    isLoading: false,
                    onPressed: _loadData,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBookingInfoCard(booking, property),
                const SizedBox(height: 24),
                _buildExtensionSection(booking),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingInfoCard(Booking booking, PropertyDetail property) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.home, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    property.name.isNotEmpty ? property.name : 'Property',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Booking ID', '#${booking.bookingId}'),
            _buildInfoRow('Check-in', _formatDate(booking.startDate)),
            _buildInfoRow('Check-out', _formatDate(booking.endDate)),
            _buildInfoRow('Duration', _calculateDuration(booking.startDate, booking.endDate)),
            _buildInfoRow('Total Price', '\$${booking.totalPrice.toStringAsFixed(2)}'),
            _buildInfoRow('Status', _getStatusText(booking.status)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(booking.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getStatusColor(booking.status),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(booking.status),
                    color: _getStatusColor(booking.status),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusDescription(booking.status),
                    style: TextStyle(
                      color: _getStatusColor(booking.status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtensionSection(Booking booking) {
    // Extension is only available for active subscription-based monthly bookings with an end date
    final isSubscriptionBooking = booking.isSubscription;
    final canExtend = booking.status == BookingStatus.active && 
                     booking.endDate != null &&
                     booking.endDate!.isAfter(DateTime.now()) &&
                     isSubscriptionBooking;

    // Determine the reason if extension is not available
    String unavailableReason;
    if (!isSubscriptionBooking) {
      unavailableReason = 'Only monthly subscription-based bookings can be extended.';
    } else if (booking.status != BookingStatus.active) {
      unavailableReason = 'Only active bookings can be extended.';
    } else if (booking.endDate == null) {
      unavailableReason = 'Open-ended bookings do not require extension.';
    } else {
      unavailableReason = 'Your booking has already ended.';
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: canExtend ? Colors.green : Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Lease Extension',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              canExtend 
                ? 'You can request to extend your current monthly lease.'
                : unavailableReason,
              style: TextStyle(
                fontSize: 14,
                color: canExtend ? null : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: canExtend
                ? CustomButton(
                    label: 'Request Extension',
                    isLoading: false,
                    onPressed: () => _showExtensionDialog(),
                  )
                : CustomOutlinedButton(
                    label: 'Extension Not Available',
                    isLoading: false,
                    onPressed: () {},
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _calculateDuration(DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null || checkOut == null) return 'N/A';
    final duration = checkOut.difference(checkIn).inDays;
    return '$duration ${duration == 1 ? 'day' : 'days'}';
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
        return 'Upcoming';
      case BookingStatus.active:
        return 'Active';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.pending:
        return 'Pending Approval';
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
        return Colors.orange;
      case BookingStatus.active:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.blue;
      case BookingStatus.pending:
        return Colors.amber;
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
        return Icons.schedule;
      case BookingStatus.active:
        return Icons.check_circle;
      case BookingStatus.cancelled:
        return Icons.cancel;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.pending:
        return Icons.hourglass_empty;
    }
  }

  String _getStatusDescription(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
        return 'Your booking is scheduled to start';
      case BookingStatus.active:
        return 'Your booking is currently active';
      case BookingStatus.cancelled:
        return 'This booking has been cancelled';
      case BookingStatus.completed:
        return 'This booking has been completed';
      case BookingStatus.pending:
        return 'Your application is awaiting landlord approval';
    }
  }

  void _showExtensionDialog() {
    final booking = _findBookingById(
      Provider.of<PropertyRentalProvider>(context, listen: false),
      widget.bookingId,
    ) ?? widget.booking;

    if (booking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => ExtendBookingDialog(
        booking: booking,
        onExtended: () {
          // Refresh booking details after extension request
          Provider.of<PropertyRentalProvider>(context, listen: false)
              .getBookingDetails(widget.bookingId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Extension request sent successfully! Awaiting landlord approval.'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }
}
