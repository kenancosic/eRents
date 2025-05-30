import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/widgets/custom_search_bar.dart';
import 'package:e_rents_desktop/widgets/custom_table_widget.dart';
import 'package:e_rents_desktop/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/features/maintenance/providers/maintenance_provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:e_rents_desktop/utils/image_utils.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  IssueStatus? _selectedStatus;
  IssuePriority? _selectedPriority;
  String? _selectedProperty;
  bool _showOnlyComplaints = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MaintenanceProvider>().fetchIssues();
        context.read<PropertyProvider>().fetchProperties();
      }
    });
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MaintenanceProvider, PropertyProvider>(
      builder: (context, maintenanceProvider, propertyProvider, child) {
        if (maintenanceProvider.state == ViewState.Busy ||
            propertyProvider.state == ViewState.Busy) {
          return const Center(child: CircularProgressIndicator());
        }

        if (maintenanceProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  maintenanceProvider.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => maintenanceProvider.fetchIssues(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final filteredIssues = _filterIssues(
          maintenanceProvider.issues,
          propertyProvider.properties,
        );

        return Column(
          children: [
            _buildHeader(context, maintenanceProvider),
            const SizedBox(height: 16),
            Expanded(
              child: CustomTableWidget<MaintenanceIssue>(
                data: filteredIssues,
                columns: _getTableColumns(),
                cellsBuilder:
                    (issue) => _buildTableCells(issue, propertyProvider),
                searchStringBuilder:
                    (issue) =>
                        '${issue.title} ${issue.description} ${_getPropertyTitle(issue.propertyId, propertyProvider)}',
                emptyStateWidget: _buildEmptyState(context),
                defaultRowsPerPage: 10,
                onRowTap: (issue) {
                  // Single click highlights row
                  print('Selected maintenance issue: ${issue.title}');
                },
                onRowDoubleTap: (issue) {
                  context.push('/maintenance/${issue.id}');
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, MaintenanceProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maintenance Dashboard',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${provider.issues.length} total issues • ${provider.getIssuesByStatus(IssueStatus.pending).length} pending • ${provider.getIssuesByStatus(IssueStatus.inProgress).length} in progress',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Expanded(
              flex: 2,
              child: CustomSearchBar(
                controller: _searchController,
                hintText: 'Search issues...',
                onFilterPressed: () => _showFilterOptions(context),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => context.go('/maintenance/new'),
              icon: const Icon(Icons.add),
              label: const Text('New Issue'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No maintenance issues found matching your criteria',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or create a new issue',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  List<DataColumn> _getTableColumns() {
    return [
      const DataColumn(label: Text('Priority')),
      const DataColumn(label: Text('Title')),
      const DataColumn(label: Text('Property')),
      const DataColumn(label: Text('Status')),
      const DataColumn(label: Text('Reported'), numeric: true),
      const DataColumn(label: Text('Actions')),
    ];
  }

  List<DataCell> _buildTableCells(
    MaintenanceIssue issue,
    PropertyProvider propertyProvider,
  ) {
    final property = propertyProvider.properties.firstWhere(
      (p) => p.id == issue.propertyId,
      orElse: () => Property.empty(),
    );
    final statusIcon = _getIconForMaintenanceStatus(issue.status);

    return [
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: issue.priorityColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(issue.priority.toString().split('.').last),
          ],
        ),
      ),
      DataCell(Text(issue.title, overflow: TextOverflow.ellipsis)),
      DataCell(
        InkWell(
          onTap: () {
            if (property.id != 0) {
              context.push('/properties/${property.id}');
            }
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Row(
              children: [
                if (property.images.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: ImageUtils.buildImage(
                        property.images.first.url!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.apartment,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.apartment,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    property.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      DataCell(
        StatusChip(
          label: issue.status.toString().split('.').last,
          backgroundColor: issue.statusColor,
          iconData: statusIcon,
        ),
      ),
      DataCell(Text(_formatDate(issue.createdAt))),
      DataCell(
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, size: 20),
              tooltip: 'View Details',
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onPressed: () => context.go('/maintenance/${issue.id}'),
            ),
          ],
        ),
      ),
    ];
  }

  String _getPropertyTitle(int propertyId, PropertyProvider propertyProvider) {
    return propertyProvider.properties
        .firstWhere((p) => p.id == propertyId, orElse: () => Property.empty())
        .title;
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMd().add_jm().format(date);
  }

  void _showFilterOptions(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(
      context,
      listen: false,
    );

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 16.0,
                children: [
                  _buildFilterSectionTitle(context, "Status"),
                  _buildStatusFilterOptions(setSheetState),
                  const Divider(),
                  _buildFilterSectionTitle(context, "Priority"),
                  _buildPriorityFilterOptions(setSheetState),
                  const Divider(),
                  _buildFilterSectionTitle(context, "Property"),
                  _buildPropertyFilterOptions(propertyProvider, setSheetState),
                  const Divider(),
                  _buildFilterSectionTitle(context, "Other"),
                  _buildComplaintFilterOption(setSheetState),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusFilterOptions(StateSetter setSheetState) {
    return Wrap(
      spacing: 8.0,
      children: [
        _buildFilterChip<IssueStatus?>(
          label: 'All',
          value: null,
          groupValue: _selectedStatus,
          onSelected: (value) {
            setState(() => _selectedStatus = value);
            setSheetState(() {});
          },
        ),
        ...IssueStatus.values.map(
          (status) => _buildFilterChip<IssueStatus?>(
            label: status.toString().split('.').last,
            value: status,
            groupValue: _selectedStatus,
            onSelected: (value) {
              setState(() => _selectedStatus = value);
              setSheetState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityFilterOptions(StateSetter setSheetState) {
    return Wrap(
      spacing: 8.0,
      children: [
        _buildFilterChip<IssuePriority?>(
          label: 'All',
          value: null,
          groupValue: _selectedPriority,
          onSelected: (value) {
            setState(() => _selectedPriority = value);
            setSheetState(() {});
          },
        ),
        ...IssuePriority.values.map(
          (priority) => _buildFilterChip<IssuePriority?>(
            label: priority.toString().split('.').last,
            value: priority,
            groupValue: _selectedPriority,
            onSelected: (value) {
              setState(() => _selectedPriority = value);
              setSheetState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyFilterOptions(
    PropertyProvider propertyProvider,
    StateSetter setSheetState,
  ) {
    var propertiesToShow = propertyProvider.properties.take(10).toList();
    bool limited = propertiesToShow.length < propertyProvider.properties.length;

    return Wrap(
      spacing: 8.0,
      children: [
        _buildFilterChip<String?>(
          label: 'All',
          value: null,
          groupValue: _selectedProperty,
          onSelected: (value) {
            setState(() => _selectedProperty = value);
            setSheetState(() {});
          },
        ),
        ...propertiesToShow.map(
          (property) => _buildFilterChip<String?>(
            label: property.title,
            value: property.title,
            groupValue: _selectedProperty,
            onSelected: (value) {
              setState(() => _selectedProperty = value);
              setSheetState(() {});
            },
          ),
        ),
        if (limited) const Chip(label: Text('...')),
      ],
    );
  }

  Widget _buildComplaintFilterOption(StateSetter setSheetState) {
    return FilterChip(
      label: const Text('Only Tenant Complaints'),
      selected: _showOnlyComplaints,
      onSelected: (selected) {
        setState(() => _showOnlyComplaints = selected);
        setSheetState(() {});
      },
    );
  }

  Widget _buildFilterChip<T>({
    required String label,
    required T value,
    required T groupValue,
    required ValueChanged<T> onSelected,
  }) {
    final bool isSelected = value == groupValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          onSelected(value);
        }
      },
      selectedColor:
          Theme.of(context).chipTheme.selectedColor ??
          Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Colors.white,
    );
  }

  List<MaintenanceIssue> _filterIssues(
    List<MaintenanceIssue> allIssues,
    List<Property> allProperties,
  ) {
    final searchTermLower = _searchController.text.toLowerCase();

    return allIssues.where((issue) {
      final property = allProperties.firstWhere(
        (p) => p.id == issue.propertyId,
        orElse: () => Property.empty(),
      );

      final matchesSearch =
          searchTermLower.isEmpty ||
          issue.title.toLowerCase().contains(searchTermLower) ||
          issue.description.toLowerCase().contains(searchTermLower) ||
          property.title.toLowerCase().contains(searchTermLower);

      final matchesStatus =
          _selectedStatus == null || issue.status == _selectedStatus;
      final matchesPriority =
          _selectedPriority == null || issue.priority == _selectedPriority;
      final matchesProperty =
          _selectedProperty == null || property.title == _selectedProperty;
      final matchesComplaint = !_showOnlyComplaints || issue.isTenantComplaint;

      return matchesSearch &&
          matchesStatus &&
          matchesPriority &&
          matchesProperty &&
          matchesComplaint;
    }).toList();
  }

  IconData _getIconForMaintenanceStatus(IssueStatus status) {
    switch (status) {
      case IssueStatus.pending:
        return Icons.pending_actions_outlined;
      case IssueStatus.inProgress:
        return Icons.construction_outlined;
      case IssueStatus.completed:
        return Icons.check_circle_outline_rounded;
      case IssueStatus.cancelled:
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }
}
