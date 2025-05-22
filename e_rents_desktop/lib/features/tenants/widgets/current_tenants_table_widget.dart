import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/widgets/custom_table_widget.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';
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

  @override
  Widget build(BuildContext context) {
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
      return const Center(
        child: Text(
          'No current tenants found matching your search',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    // TODO: Replace this mock property assignment with real data
    final properties = MockDataService.getMockProperties();
    final Map<String, Property> tenantProperties = {};
    for (int i = 0; i < filteredTenants.length; i++) {
      tenantProperties[filteredTenants[i].id] =
          properties[i % properties.length];
    }

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
                            tenant.profileImage!.url.isNotEmpty)
                        ? NetworkImage(tenant.profileImage!.url)
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
          // Get the property, handle null case if assignment fails
          final property = tenantProperties[tenant.id];
          if (property == null) {
            return const DataCell(Text('N/A')); // Or other placeholder
          }

          return DataCell(
            InkWell(
              // Changed from GestureDetector
              onTap:
                  () => widget.onNavigateToProperty(
                    property,
                  ), // Use push if the callback allows or modify callback
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
                            property.images.isNotEmpty &&
                                    property.images.first.url.isNotEmpty
                                ? Image.network(
                                  property.images.first.url,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                )
                                : Image.asset(
                                  'assets/images/placeholder.jpg',
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                ),
                      ),
                    ),
                    // Property name
                    Expanded(
                      // Use Expanded instead of Flexible for simpler layout
                      child: Text(
                        property.title,
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
        'width': const FixedColumnWidth(80),
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
                      size: 20,
                    ),
                    onPressed: () => widget.onSendMessage(tenant),
                    tooltip: 'Send Message',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.person,
                      color: Colors.green,
                      size: 20,
                    ),
                    onPressed:
                        () => widget.onShowProfile(tenant, [
                          tenantProperties[tenant.id]!,
                        ]),
                    tooltip: 'View Profile',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
