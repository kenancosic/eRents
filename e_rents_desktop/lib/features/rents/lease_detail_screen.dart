import 'package:e_rents_desktop/features/rents/providers/rents_provider.dart';
import 'package:e_rents_desktop/models/rental_request.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class LeaseDetailScreen extends StatelessWidget {
  final int requestId;

  const LeaseDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RentsProvider>(
      create: (_) => 
          RentsProvider(context.read<ApiService>(), context: context)
            ..setRentalType(RentalType.lease)
            ..getLeaseById(requestId),
      child: Consumer<RentsProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lease Details')),
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
          'Error: ${provider.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (provider.selectedLease == null) {
      return const Center(child: Text('No data available.'));
    }

    final lease = provider.selectedLease!;
    return buildLeaseDetails(context, lease, provider);
  }

  Widget buildLeaseDetails(
    BuildContext context,
    RentalRequest lease,
    RentsProvider provider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailCard(
            context,
            title: 'Tenant Information',
            children: [
              _buildDetailRow('Name', lease.userName),
              _buildDetailRow('Email', lease.user?.email ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailCard(
            context,
            title: 'Property Information',
            children: [
              _buildDetailRow('Name', lease.propertyName),
              _buildDetailRow(
                'Address',
                lease.property?.address?.getFullAddress() ?? 'N/A',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailCard(
            context,
            title: 'Lease Details',
            children: [
              _buildDetailRow(
                'Proposed Start',
                DateFormat.yMMMd().format(lease.proposedStartDate),
              ),
              _buildDetailRow(
                'Proposed End',
                DateFormat.yMMMd().format(lease.proposedEndDate),
              ),
              _buildDetailRow(
                'Duration',
                '${lease.leaseDurationMonths} months',
              ),
              _buildDetailRow('Monthly Rent', '\$${lease.proposedMonthlyRent}'),
              _buildDetailRow('Status', lease.status),
            ],
          ),
          if (lease.message.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailCard(
              context,
              title: 'Message from Tenant',
              children: [
                Text(
                  lease.message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
          if (lease.status == 'Pending') ...[
            const SizedBox(height: 16),
            _LeaseActionsCard(
              provider: provider, 
              lease: lease,
              onActionCompleted: () => provider.getLeaseById(lease.requestId),
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

class _LeaseActionsCard extends StatelessWidget {
  final RentsProvider provider;
  final RentalRequest lease;
  final VoidCallback onActionCompleted;

  const _LeaseActionsCard({
    required this.provider,
    required this.lease,
    required this.onActionCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = provider.isLoading;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actions', style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 20, thickness: 1),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              Text(
                'Respond to this rental request. You can add an optional message for the tenant.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed:
                        () => _showConfirmationDialog(
                          context,
                          isApproval: false,
                        ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        () => _showConfirmationDialog(
                          context,
                          isApproval: true,
                        ),
                    child: const Text('Approve'),
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

  Future<void> _showConfirmationDialog(
    BuildContext context, {
    required bool isApproval,
  }) async {
    final responseController = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isApproval ? 'Approve Request?' : 'Reject Request?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to ${isApproval ? 'approve' : 'reject'} this request?',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: responseController,
                decoration: const InputDecoration(
                  labelText: 'Optional Response',
                  hintText: 'e.g., "Welcome aboard!"',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => dialogContext.pop(false),
            ),
            ElevatedButton(
              child: Text(isApproval ? 'Approve' : 'Reject'),
              onPressed: () => dialogContext.pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final response = responseController.text;
      bool success;
      if (isApproval) {
        success = await provider.approveLease(
          lease.requestId,
          response.isNotEmpty ? response : '',
        );
      } else {
        success = await provider.rejectLease(
          lease.requestId,
          response.isNotEmpty ? response : '',
        );
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Request successfully ${isApproval ? 'approved' : 'rejected'}.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        onActionCompleted();
      }
    }
  }
}
