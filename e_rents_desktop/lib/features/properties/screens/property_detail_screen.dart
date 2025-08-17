import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/base/crud/detail_screen.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/models/enums/property_status.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/router.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_images_grid.dart';
import 'package:e_rents_desktop/models/image.dart' as model;
import 'package:e_rents_desktop/widgets/status_chip.dart';
import 'package:e_rents_desktop/core/lookups/lookup_key.dart';
import 'package:e_rents_desktop/providers/lookup_provider.dart';
import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/models/property_tenant_summary.dart';

class PropertyDetailScreen extends StatelessWidget {
  final int propertyId;
  
  const PropertyDetailScreen({super.key, required this.propertyId});

  // ── Chips helpers (standardized with list screen) ─────────────────────────
  Color _statusColor(PropertyStatus status, BuildContext context) {
    switch (status) {
      case PropertyStatus.available:
        return Colors.green.shade600;
      case PropertyStatus.occupied:
        return Colors.deepOrange.shade600;
      case PropertyStatus.underMaintenance:
        return Colors.amber.shade700;
      case PropertyStatus.unavailable:
        return Colors.grey.shade600;
    }
  }

  Widget _statusChip(PropertyStatus status, BuildContext context) {
    final bg = _statusColor(status, context);
    final IconData icon;
    switch (status) {
      case PropertyStatus.available:
        icon = Icons.check_circle_outline;
        break;
      case PropertyStatus.occupied:
        icon = Icons.home_work_outlined;
        break;
      case PropertyStatus.underMaintenance:
        icon = Icons.build_outlined;
        break;
      case PropertyStatus.unavailable:
        icon = Icons.block;
        break;
    }
    return StatusChip(
      label: status.displayName,
      backgroundColor: bg,
      iconData: icon,
      foregroundColor: Colors.white,
    );
  }

  List<Widget> _amenityChips(BuildContext context, List<int> amenityIds) {
    final lookup = context.read<LookupProvider>();
    final names = amenityIds
        .map((id) => lookup.label(LookupKey.amenity, id: id) ?? 'ID $id')
        .toList();
    return names
        .map(
          (name) => Chip(
            label: Text(name),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          ),
        )
        .toList();
  }

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

              // Title and Status in one row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                      property.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                  ),
                  const SizedBox(width: 12),
                  _statusChip(property.status, context),
                ],
              ),
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
              if (property.amenityIds.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _amenityChips(context, property.amenityIds),
                )
              else
                Text(
                  'No amenities listed',
                  style: TextStyle(color: Colors.grey[600]),
                ),
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
                                    ...reviews.map((r) => _ReviewTile(
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
                                String _fmt(DateTime? d) => d == null ? '-' : '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
                                inner = Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const CircleAvatar(child: Icon(Icons.person)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(tenant.fullName?.isNotEmpty == true ? tenant.fullName! : 'User #${tenant.userId}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                          if ((tenant.email ?? '').isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(tenant.email!, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                                          ],
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.event_available, size: 16, color: Colors.grey),
                                              const SizedBox(width: 6),
                                              Text('Lease: ${_fmt(tenant.leaseStartDate)} - ${_fmt(tenant.leaseEndDate)}', style: TextStyle(color: Colors.grey[800])),
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
              r.createdAt.toString(),
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
                                  rep.createdAt.toString(),
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