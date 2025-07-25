
import 'package:e_rents_desktop/features/rents/providers/rents_provider.dart';
import 'package:e_rents_desktop/models/booking.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class StayDetailScreen extends StatelessWidget {
  final int stayId;

  const StayDetailScreen({super.key, required this.stayId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RentsProvider>(
      create: (_) => 
          RentsProvider(context.read<ApiService>(), context: context)
            ..setRentalType(RentalType.stay)
            ..getStayById(stayId),
      child: Consumer<RentsProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(title: const Text('Stay Details')),
            body: buildBody(context, provider),
          );
        },
      ),
    );
  }

  Widget buildBody(BuildContext context, RentsProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Text(
          'Error: ${provider.error ?? 'Unknown error'}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (provider.selectedStay == null) {
      return const Center(child: Text('No data available.'));
    }

    final booking = provider.selectedStay!;
    return buildBookingDetails(context, booking, provider);
  }

  Widget buildBookingDetails(
    BuildContext context,
    Booking booking,
    RentsProvider provider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailCard(
            context,
            title: 'Guest Information',
            children: [
              _buildDetailRow('Name', booking.userName ?? 'N/A'),
              _buildDetailRow('Email', booking.userEmail ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailCard(
            context,
            title: 'Property Information',
            children: [
              _buildDetailRow('Name', booking.propertyName ?? 'N/A'),
              _buildDetailRow('Address', booking.propertyAddress ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailCard(
            context,
            title: 'Stay Details',
            children: [
              _buildDetailRow(
                'Check-in',
                DateFormat.yMMMd().format(booking.startDate),
              ),
              _buildDetailRow(
                'Check-out',
                booking.endDate != null
                    ? DateFormat.yMMMd().format(booking.endDate!)
                    : 'N/A',
              ),
              _buildDetailRow('Number of guests', '${booking.numberOfGuests}'),
              _buildDetailRow('Total price', '\$${booking.totalPrice}'),
              _buildDetailRow('Status', booking.status.displayName),
            ],
          ),
          if (booking.canBeCancelled) ...[
            const SizedBox(height: 16),
            _StayActionsCard(
              provider: provider,
              booking: booking,
              onActionCompleted: () => provider.getStayById(stayId),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 20, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}

class _StayActionsCard extends StatelessWidget {
  final RentsProvider provider;
  final Booking booking;
  final VoidCallback onActionCompleted;

  const _StayActionsCard({
    required this.provider,
    required this.booking,
    required this.onActionCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = provider.isLoading;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cancel Stay', style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 20, thickness: 1),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              Text(
                'Cancelling this stay is an irreversible action. A reason is required.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => _showCancellationDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Cancel Stay'),
                  ),
                ],
              ),
            ],
            if (provider.error != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${provider.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showCancellationDialog(
    BuildContext context,
  ) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Cancellation'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Please provide a reason for cancelling this stay.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Cancellation Reason*',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'A reason is required.';
                    }
                    if (value.length < 10) {
                      return 'Please provide a more detailed reason (min 10 characters).';
                    }
                    return null;
                  },
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Back'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('Confirm Cancellation'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final reason = reasonController.text;
      final success = await provider.cancelStay(
        booking.bookingId,
        reason,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stay has been successfully cancelled.'),
            backgroundColor: Colors.green,
          ),
        );
        onActionCompleted();
      }
    }
  }
}
