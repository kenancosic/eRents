import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import 'package:e_rents_desktop/widgets/custom_table_widget.dart';
import 'package:e_rents_desktop/features/tenants/providers/tenant_collection_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class CurrentTenantsTableWidget extends StatefulWidget {
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
  State<CurrentTenantsTableWidget> createState() =>
      _CurrentTenantsTableWidgetState();
}

class _CurrentTenantsTableWidgetState extends State<CurrentTenantsTableWidget> {
  // Columns visibility state
  final Map<String, bool> _columnVisibility = {
    'Profile': true,
    'Full Name': true,
    'Property': true,
    'Phone': true,
    'City': true,
    'Actions': true,
  };

  // Add column definitions as class member
  List<Map<String, dynamic>> _columnDefs = [];

  // Helper method to convert relative image URLs to absolute URLs
  String? _getAbsoluteImageUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) return null;

    if (relativeUrl.startsWith('/Image/')) {
      // TODO: Get base URL from configuration instead of hardcoding
      return 'http://localhost:5000$relativeUrl';
    } else if (relativeUrl.startsWith('http')) {
      return relativeUrl;
    }
    return null;
  }

  // Helper method to get cover image or first image
  String? _getPropertyImageUrl(List<dynamic>? images) {
    if (images == null || images.isEmpty) return null;

    // Try to find cover image first
    var coverImage = images.firstWhere(
      (img) => img != null && img['isCover'] == true,
      orElse: () => null,
    );

    // If no cover image, use first image
    if (coverImage == null && images.isNotEmpty) {
      coverImage = images[0];
    }

    // Convert relative URL to absolute URL
    if (coverImage != null && coverImage['url'] != null) {
      return _getAbsoluteImageUrl(coverImage['url'].toString());
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TenantCollectionProvider>(
      builder: (context, tenantProvider, child) {
        // Remove redundant error check - let parent handle errors
        // Always show table structure, even with 0 data

        // Get property assignments from provider with debug info
        final propertyAssignments = tenantProvider.propertyAssignments;
        print(
          'TenantTableWidget: Building with ${widget.tenants.length} tenants, ${propertyAssignments.length} property assignments',
        );

        // Apply filter based on search term and current filter field
        final filteredTenants =
            widget.tenants.where((tenant) {
              if (widget.searchTerm.isEmpty) return true;

              switch (widget.currentFilterField) {
                case 'Full Name':
                  return tenant.fullName.toLowerCase().contains(
                    widget.searchTerm.toLowerCase(),
                  );
                case 'Email':
                  return tenant.email.toLowerCase().contains(
                    widget.searchTerm.toLowerCase(),
                  );
                case 'Phone':
                  return (tenant.phone ?? '').toLowerCase().contains(
                    widget.searchTerm.toLowerCase(),
                  );
                case 'City':
                  return (tenant.addressDetail?.geoRegion?.city ?? '')
                      .toLowerCase()
                      .contains(widget.searchTerm.toLowerCase());
                default:
                  return tenant.fullName.toLowerCase().contains(
                    widget.searchTerm.toLowerCase(),
                  );
              }
            }).toList();

        if (filteredTenants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No current tenants found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.searchTerm.isNotEmpty
                      ? 'Try adjusting your search criteria'
                      : 'No tenants are currently registered',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          );
        }

        // Show loading overlay for property assignments if needed
        return Stack(
          children: [
            // Main content - always show table structure
            _buildTableContent(
              filteredTenants,
              propertyAssignments,
              tenantProvider,
            ),

            // Loading overlay for property assignments
            if (tenantProvider.isLoadingAssignments)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.blue[50],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue[600]!,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loading property assignments...',
                        style: TextStyle(color: Colors.blue[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTableContent(
    List<User> filteredTenants,
    Map<int, Map<String, dynamic>> propertyAssignments,
    TenantCollectionProvider tenantProvider,
  ) {
    _columnDefs = [
      {
        'name': 'Profile',
        'width': const FixedColumnWidth(50),
        'isEssential': true,
        'column': const DataColumn(label: Text('Profile')),
        'cell':
            (User tenant) => DataCell(
              CircleAvatar(
                radius: 16,
                backgroundImage:
                    (tenant.profileImage != null &&
                            tenant.profileImage!.url != null &&
                            tenant.profileImage!.url!.isNotEmpty)
                        ? NetworkImage(tenant.profileImage!.url!)
                        : const AssetImage('assets/images/user-image.png'),
                child:
                    tenant.profileImage == null
                        ? Text(
                          '${tenant.firstName[0]}${tenant.lastName[0]}',
                          style: const TextStyle(fontSize: 12),
                        )
                        : null,
              ),
            ),
      },
      {
        'name': 'Full Name',
        'width': const FlexColumnWidth(1.2),
        'isEssential': true,
        'column': const DataColumn(label: Text('Full Name')),
        'cell':
            (User tenant) => DataCell(
              Text(tenant.fullName, overflow: TextOverflow.ellipsis),
            ),
      },
      {
        'name': 'Property',
        'width': const FlexColumnWidth(1.5),
        'isEssential': true,
        'column': const DataColumn(label: Text('Property')),
        'cell': (User tenant) {
          // Get property assignment from provider
          final propertyData = propertyAssignments[tenant.id];

          if (propertyData == null || propertyData.isEmpty) {
            return const DataCell(Text('N/A - No active lease'));
          }

          // Parse property data from backend response with null safety
          final propertyTitle =
              propertyData['title']?.toString() ?? 'Unknown Property';

          // Get cover image or first image with proper URL conversion
          final propertyImageUrl = _getPropertyImageUrl(
            propertyData['images'] as List<dynamic>?,
          );

          return DataCell(
            InkWell(
              onTap: () {
                print('TenantTable: Property cell clicked!');
                print(
                  'TenantTable: propertyData is null: ${propertyData == null}',
                );
                print(
                  'TenantTable: propertyData keys: ${propertyData.keys.toList()}',
                );

                // Create a property object from the data to navigate
                if (propertyData['id'] != null) {
                  print(
                    'TenantTable: Creating property from data: $propertyData',
                  );

                  final propertyIdInt =
                      int.tryParse(propertyData['id'].toString()) ?? 0;

                  print('TenantTable: Parsed property ID: $propertyIdInt');

                  final property = Property(
                    id: propertyIdInt,
                    title: propertyTitle,
                    // Add other required fields with safe defaults
                    ownerId:
                        int.tryParse(
                          propertyData['ownerId']?.toString() ?? '0',
                        ) ??
                        0,
                    description: propertyData['description']?.toString() ?? '',
                    type: PropertyType.apartment, // Default type
                    price:
                        (propertyData['price']?.toString() != null
                            ? double.tryParse(
                                  propertyData['price'].toString(),
                                ) ??
                                0.0
                            : 0.0),
                    rentingType: RentingType.monthly, // Default
                    status: PropertyStatus.available, // Default
                    images: [], // Will be populated if needed
                    bedrooms:
                        int.tryParse(
                          propertyData['bedrooms']?.toString() ?? '0',
                        ) ??
                        0,
                    bathrooms:
                        int.tryParse(
                          propertyData['bathrooms']?.toString() ?? '0',
                        ) ??
                        0,
                    area:
                        (propertyData['area']?.toString() != null
                            ? double.tryParse(
                                  propertyData['area'].toString(),
                                ) ??
                                0.0
                            : 0.0),
                    maintenanceIssues: [], // Add required field
                    amenities: [],
                    dateAdded: DateTime.now(),
                    addressDetail: null,
                  );

                  print(
                    'TenantTable: Created property object with ID: ${property.id}, title: ${property.title}',
                  );
                  widget.onNavigateToProperty(property);
                } else {
                  print(
                    'TenantTable: propertyData[\'id\'] is null or missing!',
                  );
                  print('TenantTable: Full propertyData: $propertyData');
                }
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Row(
                  children: [
                    // Property image placeholder/actual image
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child:
                            propertyImageUrl != null &&
                                    propertyImageUrl.isNotEmpty
                                ? Image.network(
                                  propertyImageUrl,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                        width: 32,
                                        height: 32,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.home,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                      ),
                                )
                                : Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.grey[300],
                                  ),
                                  child: const Icon(
                                    Icons.home,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ),
                      ),
                    ),
                    // Property name with additional null safety
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
            ),
          );
        },
      },
      {
        'name': 'Phone',
        'width': const FlexColumnWidth(1),
        'isEssential': false,
        'column': const DataColumn(label: Text('Phone')),
        'cell':
            (User tenant) => DataCell(
              Text(tenant.phone ?? 'N/A', overflow: TextOverflow.ellipsis),
            ),
      },
      {
        'name': 'City',
        'width': const FlexColumnWidth(1),
        'isEssential': false,
        'column': const DataColumn(label: Text('City')),
        'cell':
            (User tenant) => DataCell(
              Text(
                tenant.addressDetail?.geoRegion?.city ?? 'N/A',
                overflow: TextOverflow.ellipsis,
              ),
            ),
      },
      {
        'name': 'Actions',
        'width': const FixedColumnWidth(120),
        'isEssential': true,
        'column': const DataColumn(label: Text('Actions')),
        'cell':
            (User tenant) => DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.message,
                      color: Colors.blue,
                      size: 18,
                    ),
                    onPressed: () => widget.onSendMessage(tenant),
                    tooltip: 'Send Message',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.person,
                      color: Colors.green,
                      size: 18,
                    ),
                    onPressed: () {
                      // Create properties list from assignment data
                      final propertyData = propertyAssignments[tenant.id];
                      final properties = <Property>[];

                      if (propertyData != null &&
                          propertyData.isNotEmpty &&
                          propertyData['id'] != null) {
                        // Get property image URL using helper method
                        final mainImageUrl = _getPropertyImageUrl(
                          propertyData['images'] as List<dynamic>?,
                        );

                        final property = Property(
                          id: int.tryParse(propertyData['id'].toString()) ?? 0,
                          title:
                              propertyData['title']?.toString() ??
                              'Unknown Property',
                          ownerId:
                              int.tryParse(
                                propertyData['ownerId']?.toString() ?? '0',
                              ) ??
                              0,
                          description:
                              propertyData['description']?.toString() ?? '',
                          type: PropertyType.apartment, // Default type
                          price:
                              (propertyData['price']?.toString() != null
                                  ? double.tryParse(
                                        propertyData['price'].toString(),
                                      ) ??
                                      0.0
                                  : 0.0),
                          rentingType: RentingType.monthly, // Default
                          status: PropertyStatus.available, // Default
                          images: [], // Will be populated if needed
                          bedrooms:
                              int.tryParse(
                                propertyData['bedrooms']?.toString() ?? '0',
                              ) ??
                              0,
                          bathrooms:
                              int.tryParse(
                                propertyData['bathrooms']?.toString() ?? '0',
                              ) ??
                              0,
                          area:
                              (propertyData['area']?.toString() != null
                                  ? double.tryParse(
                                        propertyData['area'].toString(),
                                      ) ??
                                      0.0
                                  : 0.0),
                          maintenanceIssues: [], // Add required field
                          amenities: [],
                          dateAdded: DateTime.now(),
                          addressDetail: null,
                        );
                        properties.add(property);
                      }

                      widget.onShowProfile(tenant, properties);
                    },
                    tooltip: 'View Profile',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
      },
    ];

    // Create the list of columns based on visibility settings
    final List<DataColumn> columns = [];
    final Map<int, TableColumnWidth> columnWidths = {};
    int columnIndex = 0;

    // Add only visible columns
    for (final colDef in _columnDefs) {
      if (_columnVisibility[colDef['name']] == true) {
        columns.add(colDef['column'] as DataColumn);
        columnWidths[columnIndex] = colDef['width'] as TableColumnWidth;
        columnIndex++;
      }
    }

    return Column(
      children: [
        // Column visibility controls
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          child: _buildColumnVisibilityControls(),
        ),
        // Fitted table container
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Use the available width from constraints
              final availableWidth = constraints.maxWidth;

              // If data is loading and we have no tenants, show loading in table
              if (tenantProvider.isLoading && filteredTenants.isEmpty) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // Table header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Current Tenants',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Loading content
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                'Loading current tenants...',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // If no filtered tenants after loading, show empty state in table
              if (filteredTenants.isEmpty) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // Table header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Current Tenants',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Empty state content
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.searchTerm.isNotEmpty
                                    ? Icons.search_off
                                    : Icons.people_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.searchTerm.isNotEmpty
                                    ? 'No tenants found'
                                    : 'No current tenants',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.searchTerm.isNotEmpty
                                    ? 'Try adjusting your search criteria'
                                    : 'Current tenants will appear here once they are registered',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Show actual table with data
              return CustomTableWidget<User>(
                data: filteredTenants,
                dataRowHeight: 60,
                columnWidths: columnWidths,
                columns: columns,
                cellsBuilder: (tenant) {
                  final cells = <DataCell>[];
                  for (final colDef in _columnDefs) {
                    if (_columnVisibility[colDef['name']] == true) {
                      final cellBuilder = colDef['cell'] as Function;
                      cells.add(cellBuilder(tenant));
                    }
                  }
                  return cells;
                },
                searchStringBuilder: (tenant) => tenant.fullName,
              );
            },
          ),
        ),
      ],
    );
  }

  // Build control for toggling column visibility
  Widget _buildColumnVisibilityControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildQuickViewButtons(),
        const Spacer(),
        const Text(
          'Show columns: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.view_column_rounded),
          tooltip: 'Select visible columns',
          onSelected: (String column) {
            setState(() {
              _columnVisibility[column] = !_columnVisibility[column]!;

              // Ensure at least two columns are visible
              int visibleCount =
                  _columnVisibility.values.where((v) => v).length;
              if (visibleCount < 2) {
                _columnVisibility[column] = true;
              }
            });
          },
          itemBuilder: (BuildContext context) {
            return _columnVisibility.keys.map((String column) {
              // Find if this column is essential
              final colDef = _columnDefs.firstWhere(
                (def) => def['name'] == column,
                orElse: () => {'isEssential': false},
              );
              final isEssential = colDef['isEssential'] == true;

              return PopupMenuItem<String>(
                value: column,
                child: Row(
                  children: [
                    Checkbox(
                      value: _columnVisibility[column],
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == false &&
                              _columnVisibility.values.where((v) => v).length <=
                                  2) {
                            return; // Keep at least 2 columns visible
                          }
                          _columnVisibility[column] = value!;
                          context.pop(); // Close the menu after selection
                        });
                      },
                    ),
                    Text(column),
                    if (isEssential) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                    ],
                  ],
                ),
              );
            }).toList();
          },
        ),
      ],
    );
  }

  // Add quick view buttons for essential columns
  Widget _buildQuickViewButtons() {
    return Row(
      children: [
        const SizedBox(width: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.aspect_ratio, size: 16),
          label: const Text('Essential Only'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () {
            setState(() {
              // Show only essential columns
              for (final colDef in _columnDefs) {
                _columnVisibility[colDef['name'] as String] =
                    colDef['isEssential'] as bool;
              }
            });
          },
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.view_list, size: 16),
          label: const Text('Show All'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () {
            setState(() {
              // Show all columns
              for (final name in _columnVisibility.keys) {
                _columnVisibility[name] = true;
              }
            });
          },
        ),
      ],
    );
  }
}
