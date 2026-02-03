import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/base/crud/detail_screen.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/features/chat/providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/models/enums/property_status.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/router.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_images_grid.dart';
import 'package:e_rents_desktop/models/image.dart' as model;
import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/models/property_tenant_summary.dart';
import 'package:e_rents_desktop/models/property_status_update_request.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_status_widgets.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_review_tile.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_amenities_display.dart';
import 'package:e_rents_desktop/features/properties/widgets/payment_history_widget.dart';
import 'package:e_rents_desktop/features/properties/widgets/daily_rentals_calendar.dart';
import 'package:e_rents_desktop/utils/date_utils.dart';

class PropertyDetailScreen extends StatelessWidget {
  final int propertyId;
  
  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    
    return DetailScreen<Property>(
      title: 'Property Details',
      item: Property(
        propertyId: 0,
        ownerId: 0,
        name: '',
        description: '',
        price: 0.0,
        status: PropertyStatus.available,
        imageIds: [],
        amenityIds: [],
      ), // Placeholder while loading
      fetchItem: (id) async {
        final property = await propertyProvider.loadProperty(int.parse(id));
        if (property == null) {
          throw Exception('Property not found');
        }
        return property;
      },
      itemId: propertyId.toString(),
      detailBuilder: (context, property) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Images gallery (single-call, no-cache)
              FutureBuilder<List<model.Image>?>(
                future: context.read<PropertyProvider>().fetchPropertyImages(property.propertyId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      height: 240,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return SizedBox(
                      height: 240,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text('Failed to load images', style: TextStyle(color: Colors.grey[700])),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  final imagesData = snapshot.data ?? const <model.Image>[];
                  return PropertyImagesGrid(
                    images: property.imageIds,
                    imagesData: imagesData,
                    height: 240,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Title, Status and Rental Type in one row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                        property.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  PropertyStatusPill(status: property.status),
                  const SizedBox(width: 8),
                  // Rental Type Badge
                  if (property.rentingType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: property.rentingType?.name == 'Daily' 
                            ? Colors.blue.shade100 
                            : Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: property.rentingType?.name == 'Daily' 
                              ? Colors.blue.shade400 
                              : Colors.purple.shade400,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            property.rentingType?.name == 'Daily' 
                                ? Icons.calendar_today 
                                : Icons.calendar_month,
                            size: 16,
                            color: property.rentingType?.name == 'Daily' 
                                ? Colors.blue.shade700 
                                : Colors.purple.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            property.rentingType?.displayName ?? 'Unknown',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: property.rentingType?.name == 'Daily' 
                                  ? Colors.blue.shade700 
                                  : Colors.purple.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Status update section
              _StatusUpdateSection(property: property),
              const SizedBox(height: 12),
              
              // Location
              Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      property.address?.getCityStateCountry() ?? 'No address',
                      style: TextStyle(color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Price
              Text(
                '${property.price.toStringAsFixed(2)} ${property.currency}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Description
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                property.description ?? '',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              // Amenities (own section)
              const Text(
                'Amenities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              PropertyAmenityChips(amenityIds: property.amenityIds),
              const SizedBox(height: 20),

              // Reviews | Current tenant in one row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reviews (left)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Reviews',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if ((property.averageRating ?? 0) > 0) ...[
                              const Icon(Icons.star, size: 18, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                (property.averageRating ?? 0).toStringAsFixed(1),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Consumer<PropertyProvider>(
                          builder: (context, prov, _) {
                            final reviews = prov.reviewsFor(property.propertyId);
                            final isLoading = prov.isLoadingReviews(property.propertyId);
                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: Colors.grey, width: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          reviews.isEmpty ? 'No reviews yet.' : 'Reviews (${reviews.length})',
                                          style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600),
                                        ),
                                        IconButton(
                                          tooltip: 'Refresh reviews',
                                          onPressed: isLoading ? null : () => prov.fetchPropertyReviews(property.propertyId, includeReplies: true),
                                          icon: isLoading
                                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                              : const Icon(Icons.refresh),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ...reviews.map((r) => PropertyReviewTile(
                        review: r,
                        onReply: (text) async {
                          await context.read<PropertyProvider>().replyToReview(
                                parentReviewId: r.reviewId,
                                description: text,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Reply posted')),
                            );
                          }
                        },
                      )),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Current tenant (right)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Tenant',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<PropertyTenantSummary?>(
                          future: context.read<PropertyProvider>().fetchCurrentTenantSummary(property.propertyId),
                          builder: (context, snapshot) {
                            Widget inner;
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              inner = const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                            } else if (snapshot.hasError) {
                              inner = Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.redAccent),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text('Failed to load tenant', style: TextStyle(color: Colors.grey[700]))),
                                ],
                              );
                            } else {
                              final tenant = snapshot.data;
                              if (tenant == null) {
                                inner = Row(
                                  children: [
                                    const CircleAvatar(child: Icon(Icons.person_outline)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('No current tenant', style: TextStyle(color: Colors.grey[700])),
                                          const SizedBox(height: 4),
                                          Text('When occupied, current tenant details will appear here.', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                inner = Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const CircleAvatar(child: Icon(Icons.person)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(tenant.fullName?.isNotEmpty == true ? tenant.fullName! : 'User #${tenant.userId}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                              ),
                                              // Chat icon to message tenant
                                              IconButton(
                                                icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                                                tooltip: 'Send message to tenant',
                                                onPressed: () async {
                                                  final chatProvider = context.read<ChatProvider>();
                                                  // Ensure contact exists and select them
                                                  final success = await chatProvider.ensureContact(tenant.userId);
                                                  if (success && context.mounted) {
                                                    chatProvider.selectContact(tenant.userId);
                                                    context.go(AppRoutes.chat);
                                                  } else if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Unable to start chat with tenant')),
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          if ((tenant.email ?? '').isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(tenant.email!, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                                          ],
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.event_available, size: 16, color: Colors.grey),
                                              const SizedBox(width: 6),
                                              Text('Lease: ${AppDateUtils.formatBookingPeriod(tenant.leaseStartDate, tenant.leaseEndDate)}', style: TextStyle(color: Colors.grey[800])),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }
                            }
                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(color: Colors.grey, width: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: inner,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              
              // Rental-specific section: Upcoming Rentals (Daily) or Invoices (Monthly)
              _RentalDetailsSection(property: property),

              const SizedBox(height: 16),

              // Created date
              if (property.dateAdded != null)
                Text(
                  'Created: ${property.dateAdded.toString()}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
      onEdit: (property) {
        final id = property.propertyId;
        final path = '${AppRoutes.properties}/$id/${AppRoutes.editProperty}';
        context.push(path);
      },
    );
  }
}

class _StatusUpdateSection extends StatefulWidget {
  final Property property;

  const _StatusUpdateSection({required this.property});

  @override
  State<_StatusUpdateSection> createState() => _StatusUpdateSectionState();
}

class _StatusUpdateSectionState extends State<_StatusUpdateSection> {
  PropertyStatus? _selectedStatus;
  DateTime? _unavailableFrom;
  DateTime? _unavailableTo;
  bool _isLoading = false;
  PropertyTenantSummary? _currentTenant;
  bool _isLoadingTenant = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.property.status;
    _loadCurrentTenant();
  }

  Future<void> _loadCurrentTenant() async {
    setState(() => _isLoadingTenant = true);
    try {
      final provider = context.read<PropertyProvider>();
      final tenant = await provider.fetchCurrentTenantSummary(widget.property.propertyId);
      if (mounted) {
        setState(() => _currentTenant = tenant);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingTenant = false);
      }
    }
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
        String userMessage = 'Failed to update property status';
        String errorDetails = e.toString();
        
        // Provide specific guidance for common errors
        if (errorDetails.contains('active tenant')) {
          userMessage = 'Cannot change property status while it has active tenants. Please end current leases first.';
        } else if (errorDetails.contains('Unauthorized') || errorDetails.contains('403')) {
          userMessage = 'You do not have permission to change this property status.';
        } else if (errorDetails.contains('NotFound') || errorDetails.contains('404')) {
          userMessage = 'Property not found or has been deleted.';
        } else if (errorDetails.contains('network') || errorDetails.contains('connection')) {
          userMessage = 'Network error. Please check your connection and try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                // Show detailed error in a dialog for debugging
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Error Details'),
                    content: SingleChildScrollView(
                      child: Text(errorDetails),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
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
            // Warning about active tenant restrictions
            if (_currentTenant != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange.shade800),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Status Change Restricted',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This property has an active tenant (${_currentTenant!.fullName ?? 'User #${_currentTenant!.userId}'}). '
                      'You can only change status to "Under Maintenance" or "Occupied". '
                      'To make other changes, please end the current lease first.',
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
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

class _ReviewTile extends StatefulWidget {
  final Review review;
  final Future<void> Function(String text) onReply;

  const _ReviewTile({required this.review, required this.onReply});

  @override
  State<_ReviewTile> createState() => _ReviewTileState();
}

class _ReviewTileState extends State<_ReviewTile> {
  bool _expanded = false;

  Future<void> _promptReply(BuildContext context) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reply to review'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Write your response...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Send')),
        ],
      ),
    );
    if (text != null && text.isNotEmpty) {
      await widget.onReply(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.read<PropertyProvider>();
    final r = widget.review;
    final rating = r.starRating?.toStringAsFixed(1) ?? '';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        initiallyExpanded: false,
        onExpansionChanged: (open) async {
          setState(() => _expanded = open);
          if (open) {
            await prov.fetchReplies(r.reviewId);
          }
        },
        title: Row(
          children: [
            const Icon(Icons.reviews_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                r.description ?? '(no text)',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            if (rating.isNotEmpty) ...[
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(rating),
              const SizedBox(width: 12),
            ],
            Text(
              AppDateUtils.formatRelative(r.createdAt),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        trailing: TextButton.icon(
          onPressed: () => _promptReply(context),
          icon: const Icon(Icons.reply, size: 18),
          label: const Text('Reply'),
        ),
        children: [
          if ((r.replies ?? []).isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: Text(
                _expanded ? 'No replies yet.' : 'Expand to view replies',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final rep in r.replies!)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rep.description ?? '(no text)'),
                                const SizedBox(height: 2),
                                Text(
                                  AppDateUtils.formatRelative(rep.createdAt),
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget that displays rental-specific information:
/// - For Daily rentals: Calendar with upcoming bookings/reservations
/// - For Monthly rentals: Invoice/payment history (paid/unpaid)
class _RentalDetailsSection extends StatelessWidget {
  final Property property;

  const _RentalDetailsSection({required this.property});

  @override
  Widget build(BuildContext context) {
    final isDaily = property.rentingType?.name == 'Daily';
    
    // Both DailyRentalsCalendar and PaymentHistoryWidget have their own headers,
    // so we only render the widget directly without adding another header
    if (isDaily) {
      return DailyRentalsCalendar(propertyId: property.propertyId);
    } else {
      return PaymentHistoryWidget(propertyId: property.propertyId);
    }
  }

}