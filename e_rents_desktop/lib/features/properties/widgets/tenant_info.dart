import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';

import 'package:e_rents_desktop/models/booking_summary.dart';
import 'package:e_rents_desktop/utils/date_utils.dart';
import 'package:e_rents_desktop/utils/formatters.dart';
import 'package:e_rents_desktop/widgets/common/section_card.dart';

class TenantInfo extends StatelessWidget {
  final Property property;
  final BookingSummary? currentTenant;

  const TenantInfo({super.key, required this.property, this.currentTenant});

  // Helper method to check if property is occupied
  bool get _isOccupied => currentTenant != null;

  @override
  Widget build(BuildContext context) {
    if (!_isOccupied) {
      return SectionCard(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('No Current Tenant'),
            ],
          ),
        ),
      );
    }

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTenantHeader(context),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildLeaseDetails(context),
        ],
      ),
    );
  }

  Widget _buildTenantHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          child: Text(_getInitials(currentTenant!.tenantName ?? 'A')),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentTenant!.tenantName ?? 'Anonymous Tenant',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (currentTenant!.tenantEmail != null)
              Text(
                currentTenant!.tenantEmail!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeaseDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lease Details', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _buildDetailRow(
          context,
          'Term',
          '${AppDateUtils.formatPrimary(currentTenant!.startDate)} - ${AppDateUtils.formatPrimary(currentTenant!.endDate)}',
        ),
        _buildDetailRow(
          context,
          'Rent',
          '${kCurrencyFormat.format(property.price)} / month',
        ),
        _buildDetailRow(context, 'Status', currentTenant!.bookingStatus),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'A';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
