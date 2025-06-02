import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/tenants/providers/tenant_collection_provider.dart';
import 'package:e_rents_desktop/features/tenants/widgets/tenant_match_score_widget.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/utils/formatters.dart';
import 'package:e_rents_desktop/widgets/custom_table_widget.dart';
import 'package:go_router/go_router.dart';

class TenantsAdvertisementTableWidget extends StatefulWidget {
  final List<TenantPreference> preferences;
  final List<User>
  tenants; // Keep for compatibility, but won't be used for user data
  final String searchTerm;
  final String currentFilterField;
  final Function(TenantPreference) onSendMessage;
  final Function(TenantPreference, User)
  onShowDetails; // Keep signature for compatibility

  const TenantsAdvertisementTableWidget({
    super.key,
    required this.preferences,
    required this.tenants,
    required this.searchTerm,
    required this.currentFilterField,
    required this.onSendMessage,
    required this.onShowDetails,
  });

  @override
  State<TenantsAdvertisementTableWidget> createState() =>
      _TenantsAdvertisementTableWidgetState();
}

class _TenantsAdvertisementTableWidgetState
    extends State<TenantsAdvertisementTableWidget> {
  // Columns visibility state with smart defaults - Description hidden by default
  final Map<String, bool> _columnVisibility = {
    'Tenant': true,
    'Location': true,
    'Budget': true,
    'Move-in Timeline': true,
    'Key Amenities': true,
    'Description': false, // Hide description by default, it's in details view
    'Match': true,
    'Actions': true,
  };

  // Add this as a class member
  List<Map<String, dynamic>> _columnDefs = [];

  @override
  Widget build(BuildContext context) {
    // Apply filter based on search term and current filter field
    final filteredPreferences =
        widget.preferences.where((preference) {
          if (widget.searchTerm.isEmpty) return true;

          switch (widget.currentFilterField) {
            case 'City':
              return preference.city.toLowerCase().contains(
                widget.searchTerm.toLowerCase(),
              );
            case 'Price Range':
              final priceRange =
                  '${preference.minPrice ?? "Any"} - ${preference.maxPrice ?? "Any"}';
              return priceRange.toLowerCase().contains(
                widget.searchTerm.toLowerCase(),
              );
            case 'Amenities':
              return preference.amenities.any(
                (amenity) => amenity.toLowerCase().contains(
                  widget.searchTerm.toLowerCase(),
                ),
              );
            case 'Description':
              return preference.description.toLowerCase().contains(
                widget.searchTerm.toLowerCase(),
              );
            default:
              return preference.city.toLowerCase().contains(
                widget.searchTerm.toLowerCase(),
              );
          }
        }).toList();

    // Calculate match scores using the backend-provided values
    final matchScores = <int, int>{};
    for (var preference in filteredPreferences) {
      // Convert decimal score (0.75) to percentage (75)
      matchScores[preference.id] = (preference.matchScore * 100).round();
    }

    return Consumer<TenantCollectionProvider>(
      builder: (context, tenantProvider, child) {
        return Column(
          children: [
            // Column visibility controls
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
              child: _buildColumnVisibilityControls(),
            ),
            // Table container
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // If data is loading and we have no preferences, show loading in table
                  if (tenantProvider.isLoadingProspective &&
                      filteredPreferences.isEmpty) {
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
                                    'Tenant Advertisements',
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
                                    'Loading tenant advertisements...',
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

                  // If no filtered preferences after loading, show empty state in table
                  if (filteredPreferences.isEmpty) {
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
                                    'Tenant Advertisements',
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
                                        : Icons.campaign_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    widget.searchTerm.isNotEmpty
                                        ? 'No advertisements found'
                                        : 'No tenant advertisements',
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
                                        : 'Tenant advertisements will appear here when users are actively searching for properties',
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
                  return _buildTableWithData(filteredPreferences, matchScores);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTableWithData(
    List<TenantPreference> filteredPreferences,
    Map<int, int> matchScores,
  ) {
    // Create the list of columns based on visibility settings
    final List<DataColumn> columns = [];
    final Map<int, TableColumnWidth> columnWidths = {};
    int columnIndex = 0;

    // Define column definitions with their builders
    _columnDefs = [
      {
        'name': 'Tenant',
        'width': const FlexColumnWidth(1.2),
        'minWidth': 150.0,
        'column': const DataColumn(label: Text('Tenant')),
        'cell':
            (TenantPreference preference) => DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tenant photo/avatar
                  CircleAvatar(
                    radius: 16,
                    backgroundImage:
                        (preference.profileImageUrl != null &&
                                preference.profileImageUrl!.isNotEmpty)
                            ? NetworkImage(preference.profileImageUrl!)
                            : null,
                    child:
                        preference.profileImageUrl == null ||
                                preference.profileImageUrl!.isEmpty
                            ? Text(
                              _getInitials(
                                preference.userFullName ?? 'Unknown User',
                              ),
                              style: const TextStyle(fontSize: 10),
                            )
                            : null,
                  ),
                  const SizedBox(width: 8),
                  // Tenant name
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preference.userFullName ?? 'Unknown User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          preference.userEmail ?? 'No email',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        'isEssential': true,
      },
      {
        'name': 'Location',
        'width': const FixedColumnWidth(80),
        'minWidth': 80.0,
        'column': const DataColumn(label: Text('Location')),
        'cell':
            (TenantPreference preference) => DataCell(
              Text(preference.city, overflow: TextOverflow.ellipsis),
            ),
        'isEssential': true,
      },
      {
        'name': 'Budget',
        'width': const FixedColumnWidth(90),
        'minWidth': 90.0,
        'column': const DataColumn(label: Text('Budget')),
        'cell':
            (TenantPreference preference) => DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${preference.minPrice != null ? kCurrencyFormat.format(preference.minPrice) : 'Any'} - '
                    '${preference.maxPrice != null ? kCurrencyFormat.format(preference.maxPrice) : 'Any'}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (preference.maxPrice != null)
                    Text(
                      '/month',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
        'isEssential': true,
      },
      {
        'name': 'Move-in Timeline',
        'width': const FixedColumnWidth(110),
        'minWidth': 110.0,
        'column': const DataColumn(
          label: Text('Move-in\nTimeline', softWrap: true),
        ),
        'cell':
            (TenantPreference preference) => DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Add urgency indicator if move-in date is within 30 days
                      if (_isUrgentMoveIn(preference.searchStartDate))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 1,
                          ),
                          margin: const EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            'Urgent',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.red[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Flexible(
                        child: Text(
                          _formatDate(preference.searchStartDate),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    preference.searchEndDate != null
                        ? 'to ${_formatDate(preference.searchEndDate!)}'
                        : 'Open-ended',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
        'isEssential': true,
      },
      {
        'name': 'Key Amenities',
        'width': const FlexColumnWidth(1.2),
        'minWidth': 140.0,
        'column': const DataColumn(label: Text('Key Amenities')),
        'cell':
            (TenantPreference preference) => DataCell(
              SizedBox(
                width: 140,
                child: Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  children: [
                    ...preference.amenities
                        .take(2)
                        .map(
                          (a) => Container(
                            margin: const EdgeInsets.only(right: 2, bottom: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              a,
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    if (preference.amenities.length > 2)
                      Tooltip(
                        message: preference.amenities.skip(2).join(', '),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '+${preference.amenities.length - 2}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              placeholder: false,
            ),
        'isEssential': true,
      },
      {
        'name': 'Description',
        'width': const FlexColumnWidth(1.5),
        'minWidth': 160.0,
        'column': const DataColumn(label: Text('Description')),
        'cell':
            (TenantPreference preference) => DataCell(
              Tooltip(
                message: preference.description,
                child: Text(
                  preference.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        'isEssential': false, // Not essential - available in details view
      },
      {
        'name': 'Match',
        'width': const FixedColumnWidth(60),
        'minWidth': 60.0,
        'column': const DataColumn(label: Text('Match')),
        'cell':
            (TenantPreference preference) => DataCell(
              TenantMatchScoreWidget(score: matchScores[preference.id]!),
            ),
        'isEssential': true,
      },
      {
        'name': 'Actions',
        'width': const FixedColumnWidth(70),
        'minWidth': 70.0,
        'column': const DataColumn(label: Text('Actions')),
        'cell':
            (TenantPreference preference) => DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue, size: 18),
                    onPressed: () => widget.onSendMessage(preference),
                    tooltip: 'Send Property Offer',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.visibility,
                      color: Colors.green,
                      size: 18,
                    ),
                    onPressed:
                        () => widget.onShowDetails(
                          preference,
                          _createUserFromPreference(preference),
                        ),
                    tooltip: 'View Details',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
        'isEssential': true,
      },
    ];

    // After the above columnDefs definition, add this section
    // to determine if we need horizontal scrolling at all
    final totalEssentialWidth = _columnDefs
        .where(
          (colDef) =>
              colDef['isEssential'] == true &&
              _columnVisibility[colDef['name']] == true,
        )
        .map((colDef) => colDef['minWidth'] as double)
        .fold<double>(0, (sum, width) => sum + width);

    final screenWidth =
        MediaQuery.of(context).size.width - 32; // Account for padding

    // Add only visible columns
    for (final colDef in _columnDefs) {
      if (_columnVisibility[colDef['name']] == true) {
        columns.add(colDef['column'] as DataColumn);
        columnWidths[columnIndex] = colDef['width'] as TableColumnWidth;
        columnIndex++;
      }
    }

    return CustomTableWidget<TenantPreference>(
      data: filteredPreferences,
      dataRowHeight: 70,
      columnWidths: columnWidths,
      columns: columns,
      cellsBuilder: (preference) {
        final cells = <DataCell>[];
        for (final colDef in _columnDefs) {
          if (_columnVisibility[colDef['name']] == true) {
            final cellBuilder = colDef['cell'] as Function;
            cells.add(cellBuilder(preference));
          }
        }
        return cells;
      },
      searchStringBuilder: (preference) => preference.city,
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
          icon: const Icon(Icons.view_column),
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
                          // Only allow unchecking if there would still be at least 2 visible columns
                          if (value == false &&
                              _columnVisibility.values.where((v) => v).length <=
                                  2) {
                            return;
                          }
                          _columnVisibility[column] = value!;
                          context.pop();
                        });
                      },
                    ),
                    Text(column),
                    // Show "essential" indicator
                    if (isEssential)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Essential',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList();
          },
        ),
      ],
    );
  }

  // Add the method as a class member
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

  // Helper method to check if a move-in date is urgent (within 30 days)
  bool _isUrgentMoveIn(DateTime moveInDate) {
    final now = DateTime.now();
    final difference = moveInDate.difference(now).inDays;
    return difference >= 0 && difference <= 30;
  }

  // Helper method to format dates in a user-friendly way
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Helper method to get initials from a full name
  String _getInitials(String fullName) {
    final names = fullName.split(' ');
    return names.map((name) => name[0]).join();
  }

  // Helper method to create a User object from a TenantPreference
  User _createUserFromPreference(TenantPreference preference) {
    final fullName = preference.userFullName ?? 'Unknown User';
    final nameParts = fullName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : 'Unknown';
    final lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'User';

    return User(
      id: preference.userId,
      email: preference.userEmail ?? 'no-email@example.com',
      username: preference.userEmail?.split('@').first ?? 'unknown',
      firstName: firstName,
      lastName: lastName,
      role: UserType.tenant, // Prospective tenants should be tenant role
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
