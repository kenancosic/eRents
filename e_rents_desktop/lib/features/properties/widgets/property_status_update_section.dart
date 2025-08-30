import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/enums/property_status.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/models/property_status_update_request.dart';

/// A reusable widget for updating property status with date range selection
class PropertyStatusUpdateSection extends StatefulWidget {
  final Property property;

  const PropertyStatusUpdateSection({super.key, required this.property});

  @override
  State<PropertyStatusUpdateSection> createState() => _PropertyStatusUpdateSectionState();
}

class _PropertyStatusUpdateSectionState extends State<PropertyStatusUpdateSection> {
  PropertyStatus? _selectedStatus;
  DateTime? _unavailableFrom;
  DateTime? _unavailableTo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.property.status;
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == null) return;

    // Validate date range for unavailable status
    if (_selectedStatus == PropertyStatus.unavailable && 
        (_unavailableFrom == null || _unavailableTo == null)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both from and to dates for unavailable status')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final provider = context.read<PropertyProvider>();
      final request = PropertyStatusUpdateRequest(
        status: _selectedStatus!,
        unavailableFrom: _unavailableFrom,
        unavailableTo: _unavailableTo,
      );
      
      await provider.updatePropertyStatus(widget.property.propertyId, request);
      
      // Show refund notification message for daily rentals
      if (mounted && 
          (widget.property.rentingType == 'Daily' || widget.property.rentingType == 'daily') &&
          (_selectedStatus == PropertyStatus.unavailable || _selectedStatus == PropertyStatus.underMaintenance)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property status updated. Refunds will be processed for affected bookings and notifications sent to users.'),
            duration: Duration(seconds: 5),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property status updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update property status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _unavailableFrom = picked;
        } else {
          _unavailableTo = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Property Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PropertyStatus>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: PropertyStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 12),
            if (_selectedStatus == PropertyStatus.unavailable) ...[
              const Text(
                'Unavailable Date Range',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'From',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_unavailableFrom == null
                            ? 'Select date'
                            : '${_unavailableFrom!.year}-${_unavailableFrom!.month.toString().padLeft(2, '0')}-${_unavailableFrom!.day.toString().padLeft(2, '0')}'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'To',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_unavailableTo == null
                            ? 'Select date'
                            : '${_unavailableTo!.year}-${_unavailableTo!.month.toString().padLeft(2, '0')}-${_unavailableTo!.day.toString().padLeft(2, '0')}'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateStatus,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Update Status'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
