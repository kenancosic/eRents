import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/services/booking_service.dart';
import 'package:intl/intl.dart';

class TenantInfo extends StatelessWidget {
  final Property property;
  final BookingSummary? currentTenant;

  const TenantInfo({super.key, required this.property, this.currentTenant});

  // Helper method to check if property is occupied
  bool get _isOccupied => currentTenant != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Tenant',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[300],
              child:
                  _isOccupied
                      ? Text(
                        _getInitials(currentTenant!.tenantName ?? 'T'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : Icon(Icons.person, size: 30, color: Colors.grey[600]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isOccupied
                        ? (currentTenant!.tenantName ?? 'Anonymous Tenant')
                        : 'No Tenant',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isOccupied
                        ? (currentTenant!.tenantEmail ?? 'No email provided')
                        : 'N/A',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    _isOccupied ? _formatPhoneNumber() : 'N/A',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        _buildLeaseInfo(
          'Lease Start',
          _isOccupied
              ? DateFormat.yMMMd().format(currentTenant!.startDate)
              : 'N/A',
        ),
        const Divider(),
        _buildLeaseInfo(
          'Lease End',
          _isOccupied
              ? (currentTenant!.endDate != null
                  ? DateFormat.yMMMd().format(currentTenant!.endDate!)
                  : 'Open-ended')
              : 'N/A',
        ),
        const Divider(),
        _buildLeaseInfo(
          'Monthly Rent',
          '${property.price.toStringAsFixed(0)} ${property.currency}',
        ),
        const Divider(),
        _buildLeaseInfo(
          'Booking Value',
          _isOccupied
              ? '${currentTenant!.totalPrice.toStringAsFixed(0)} ${currentTenant!.currency}'
              : 'N/A',
        ),
        const Divider(),
        _buildLeaseInfo(
          'Status',
          _isOccupied ? _formatStatus(currentTenant!.status) : 'Vacant',
        ),
      ],
    );
  }

  Widget _buildLeaseInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return 'T';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  String _formatPhoneNumber() {
    // Since we don't have phone in BookingSummary, we'll show a placeholder
    // This could be fetched from a user details API call if needed
    return 'Contact via email';
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active Lease';
      case 'upcoming':
        return 'Lease Starting Soon';
      case 'completed':
        return 'Lease Completed';
      case 'cancelled':
        return 'Lease Cancelled';
      default:
        return status;
    }
  }
}
