import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import 'package:e_rents_desktop/widgets/universal_table.dart';
import 'package:e_rents_desktop/features/tenants/providers/tenant_collection_provider.dart';
import 'package:provider/provider.dart';

class CurrentTenantsTableWidget extends StatelessWidget {
  final List<User> tenants;
  final String searchTerm;
  final String currentFilterField;
  final Function(User) onSendMessage;
  final Function(User, List<Property>) onShowProfile;
  final Function(Property) onNavigateToProperty;

  const CurrentTenantsTableWidget({
    super.key,
    required this.tenants,
    required this.searchTerm,
    required this.currentFilterField,
    required this.onSendMessage,
    required this.onShowProfile,
    required this.onNavigateToProperty,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TenantCollectionProvider>(
      builder: (context, tenantProvider, child) {
        final propertyAssignments = tenantProvider.propertyAssignments;

        return UniversalTable.create<User>(
          fetchData: (params) async {
            // Since this is static data (already loaded), simulate server response
            final searchTerm =
                params['searchTerm']?.toString().toLowerCase() ?? '';

            // Apply search filter
            var filteredTenants = tenants;
            if (searchTerm.isNotEmpty) {
              filteredTenants =
                  tenants.where((tenant) {
                    return tenant.fullName.toLowerCase().contains(searchTerm) ||
                        tenant.email.toLowerCase().contains(searchTerm) ||
                        (tenant.phone ?? '').toLowerCase().contains(
                          searchTerm,
                        ) ||
                        (tenant.address?.city ?? '').toLowerCase().contains(
                          searchTerm,
                        );
                  }).toList();
            }

            // Apply sorting
            final sortBy = params['sortBy']?.toString();
            final sortDesc = params['sortDesc'] as bool? ?? false;

            if (sortBy != null) {
              filteredTenants.sort((a, b) {
                dynamic aValue, bValue;
                switch (sortBy) {
                  case 'fullName':
                    aValue = a.fullName;
                    bValue = b.fullName;
                    break;
                  case 'email':
                    aValue = a.email;
                    bValue = b.email;
                    break;
                  case 'phone':
                    aValue = a.phone ?? '';
                    bValue = b.phone ?? '';
                    break;
                  case 'city':
                    aValue = a.address?.city ?? '';
                    bValue = b.address?.city ?? '';
                    break;
                  case 'property':
                    final aProperty = propertyAssignments[a.id];
                    final bProperty = propertyAssignments[b.id];
                    aValue = aProperty?['title']?.toString() ?? 'N/A';
                    bValue = bProperty?['title']?.toString() ?? 'N/A';
                    break;
                  default:
                    return 0;
                }

                int comparison = Comparable.compare(aValue, bValue);
                return sortDesc ? -comparison : comparison;
              });
            }

            // Apply pagination
            final page =
                (params['page'] as int? ?? 1) - 1; // Convert to 0-based
            final pageSize = params['pageSize'] as int? ?? 25;
            final startIndex = page * pageSize;
            final endIndex = (startIndex + pageSize).clamp(
              0,
              filteredTenants.length,
            );

            final pageItems = filteredTenants.sublist(
              startIndex.clamp(0, filteredTenants.length),
              endIndex,
            );

            return PagedResult<User>(
              items: pageItems,
              totalCount: filteredTenants.length,
              page: page,
              pageSize: pageSize,
              totalPages: (filteredTenants.length / pageSize).ceil(),
            );
          },
          columns: [
            UniversalTable.column<User>(
              key: 'profile',
              label: 'Profile',
              cellBuilder:
                  (tenant) => CircleAvatar(
                    radius: 16,
                    backgroundImage:
                        tenant.profileImageId != null
                            ? NetworkImage(
                              'http://localhost:5000/Image/${tenant.profileImageId}',
                            )
                            : null,
                    child:
                        tenant.profileImageId == null
                            ? Text(
                              '${tenant.firstName[0]}${tenant.lastName[0]}',
                              style: const TextStyle(fontSize: 12),
                            )
                            : null,
                  ),
              sortable: false,
              width: const FixedColumnWidth(60),
            ),
            UniversalTable.column<User>(
              key: 'fullName',
              label: 'Full Name',
              cellBuilder: (tenant) => UniversalTable.textCell(tenant.fullName),
              width: const FlexColumnWidth(1.2),
            ),
            UniversalTable.column<User>(
              key: 'property',
              label: 'Property',
              cellBuilder: (tenant) {
                final propertyData = propertyAssignments[tenant.id];

                if (propertyData == null || propertyData.isEmpty) {
                  return UniversalTable.textCell('N/A - No active lease');
                }

                final propertyTitle =
                    propertyData['title']?.toString() ?? 'Unknown Property';
                final propertyImageUrl = _getPropertyImageUrl(
                  propertyData['images'] as List<dynamic>?,
                );

                return InkWell(
                  onTap: () {
                    if (propertyData['id'] != null) {
                      final property = _createPropertyFromData(propertyData);
                      onNavigateToProperty(property);
                    }
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child:
                                propertyImageUrl != null
                                    ? Image.network(
                                      propertyImageUrl,
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _buildPropertyPlaceholder(),
                                    )
                                    : _buildPropertyPlaceholder(),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            propertyTitle.isEmpty
                                ? 'Unknown Property'
                                : propertyTitle,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              width: const FlexColumnWidth(1.5),
            ),
            UniversalTable.column<User>(
              key: 'email',
              label: 'Email',
              cellBuilder: (tenant) => UniversalTable.textCell(tenant.email),
              width: const FlexColumnWidth(1.2),
            ),
            UniversalTable.column<User>(
              key: 'phone',
              label: 'Phone',
              cellBuilder:
                  (tenant) => UniversalTable.textCell(tenant.phone ?? 'N/A'),
              width: const FlexColumnWidth(1),
            ),
            UniversalTable.column<User>(
              key: 'city',
              label: 'City',
              cellBuilder:
                  (tenant) =>
                      UniversalTable.textCell(tenant.address?.city ?? 'N/A'),
              width: const FlexColumnWidth(1),
            ),
            UniversalTable.column<User>(
              key: 'actions',
              label: 'Actions',
              cellBuilder:
                  (tenant) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      UniversalTable.iconActionCell(
                        icon: Icons.message,
                        onPressed: () => onSendMessage(tenant),
                        tooltip: 'Send Message',
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      UniversalTable.iconActionCell(
                        icon: Icons.person,
                        onPressed: () {
                          final propertyData = propertyAssignments[tenant.id];
                          final properties = <Property>[];

                          if (propertyData != null &&
                              propertyData.isNotEmpty &&
                              propertyData['id'] != null) {
                            properties.add(
                              _createPropertyFromData(propertyData),
                            );
                          }

                          onShowProfile(tenant, properties);
                        },
                        tooltip: 'View Profile',
                        color: Colors.green,
                      ),
                    ],
                  ),
              sortable: false,
              width: const FixedColumnWidth(100),
            ),
          ],
          title: 'Current Tenants (${tenants.length})',
          searchHint: 'Search tenants by name, email, phone, or city...',
          emptyStateMessage:
              'No current tenants found. Active tenants will appear here.',
          defaultPageSize: 25,
        );
      },
    );
  }

  // Helper method to get property image URL
  String? _getPropertyImageUrl(List<dynamic>? images) {
    if (images == null || images.isEmpty) return null;

    var coverImage = images.firstWhere(
      (img) => img != null && img['isCover'] == true,
      orElse: () => null,
    );

    if (coverImage == null && images.isNotEmpty) {
      coverImage = images[0];
    }

    if (coverImage != null && coverImage['url'] != null) {
      final relativeUrl = coverImage['url'].toString();
      if (relativeUrl.startsWith('/Image/')) {
        return 'http://localhost:5000$relativeUrl';
      }
    }

    return null;
  }

  // Helper method to build property placeholder
  Widget _buildPropertyPlaceholder() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey[300],
      ),
      child: const Icon(Icons.home, color: Colors.grey, size: 20),
    );
  }

  // Helper method to create Property object from backend data
  Property _createPropertyFromData(Map<String, dynamic> propertyData) {
    return Property(
      propertyId: int.tryParse(propertyData['id'].toString()) ?? 0,
      name: propertyData['title']?.toString() ?? 'Unknown Property',
      ownerId: int.tryParse(propertyData['ownerId']?.toString() ?? '0') ?? 0,
      description: propertyData['description']?.toString() ?? '',
      type: PropertyType.apartment, // Default type
      price:
          (propertyData['price']?.toString() != null
              ? double.tryParse(propertyData['price'].toString()) ?? 0.0
              : 0.0),
      rentingType: RentingType.monthly, // Default
      status: PropertyStatus.available, // Default
      imageIds: [], // Images fetched via ImageController
      bedrooms: int.tryParse(propertyData['bedrooms']?.toString() ?? '0') ?? 0,
      bathrooms:
          int.tryParse(propertyData['bathrooms']?.toString() ?? '0') ?? 0,
      area:
          (propertyData['area']?.toString() != null
              ? double.tryParse(propertyData['area'].toString()) ?? 0.0
              : 0.0),
      maintenanceIssues: [], // Add required field
      amenityIds: [], // Amenities fetched via AmenitiesController
      dateAdded: DateTime.now(),
      address: null,
    );
  }
}
