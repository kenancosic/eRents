import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/features/maintenance/providers/maintenance_provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:go_router/go_router.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  IssueStatus? _selectedStatus;
  IssuePriority? _selectedPriority;
  String? _selectedProperty;
  bool _showOnlyComplaints = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(() {
      context.read<MaintenanceProvider>().fetchIssues();
      context.read<PropertyProvider>().fetchProperties();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: 'Maintenance Issues',
      currentPath: '/maintenance',
      child: Consumer2<MaintenanceProvider, PropertyProvider>(
        builder: (context, maintenanceProvider, propertyProvider, child) {
          if (maintenanceProvider.isLoading || propertyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (maintenanceProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    maintenanceProvider.error!,
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
              _buildFilters(context),
              const SizedBox(height: 16),
              Expanded(
                child: _buildMainContent(
                  context,
                  filteredIssues,
                  propertyProvider,
                ),
              ),
            ],
          );
        },
      ),
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
            ElevatedButton.icon(
              onPressed: () => context.go('/maintenance/new'),
              icon: const Icon(Icons.add),
              label: const Text('New Issue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search issues...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                              : null,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filter Options',
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'status',
                          child: Row(
                            children: [
                              const Icon(Icons.flag),
                              const SizedBox(width: 8),
                              Text(
                                _selectedStatus?.toString().split('.').last ??
                                    'All Statuses',
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'priority',
                          child: Row(
                            children: [
                              const Icon(Icons.priority_high),
                              const SizedBox(width: 8),
                              Text(
                                _selectedPriority?.toString().split('.').last ??
                                    'All Priorities',
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'property',
                          child: Row(
                            children: [
                              const Icon(Icons.apartment),
                              const SizedBox(width: 8),
                              Text(_selectedProperty ?? 'All Properties'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'complaints',
                          child: Row(
                            children: [
                              const Icon(Icons.warning),
                              const SizedBox(width: 8),
                              Text(
                                _showOnlyComplaints
                                    ? 'Show All'
                                    : 'Show Only Complaints',
                              ),
                            ],
                          ),
                        ),
                      ],
                  onSelected: (value) {
                    switch (value) {
                      case 'status':
                        _showStatusFilter(context);
                        break;
                      case 'priority':
                        _showPriorityFilter(context);
                        break;
                      case 'property':
                        _showPropertyFilter(context);
                        break;
                      case 'complaints':
                        setState(
                          () => _showOnlyComplaints = !_showOnlyComplaints,
                        );
                        break;
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    List<MaintenanceIssue> issues,
    PropertyProvider propertyProvider,
  ) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildIssuesList(context, issues, propertyProvider),
              _buildIssuesList(
                context,
                issues.where((i) => i.status == IssueStatus.pending).toList(),
                propertyProvider,
              ),
              _buildIssuesList(
                context,
                issues
                    .where((i) => i.status == IssueStatus.inProgress)
                    .toList(),
                propertyProvider,
              ),
              _buildIssuesList(
                context,
                issues.where((i) => i.status == IssueStatus.completed).toList(),
                propertyProvider,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIssuesList(
    BuildContext context,
    List<MaintenanceIssue> issues,
    PropertyProvider propertyProvider,
  ) {
    if (issues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No maintenance issues found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
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

    return ListView.builder(
      itemCount: issues.length,
      itemBuilder: (context, index) {
        final issue = issues[index];
        final property = propertyProvider.properties.firstWhere(
          (p) => p.id == issue.propertyId,
          orElse:
              () => Property(
                id: 'unknown',
                title: 'Unknown Property',
                description: '',
                type: 'unknown',
                price: 0,
                status: 'unknown',
                images: [],
                address: '',
                bedrooms: 0,
                bathrooms: 0,
                area: 0,
                maintenanceIssues: [],
              ),
        );

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () => context.go('/maintenance/${issue.id}'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      Expanded(
                        child: Text(
                          issue.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: issue.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          issue.status.toString().split('.').last,
                          style: TextStyle(
                            color: issue.statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    issue.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.apartment, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        property.title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(issue.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (issue.isTenantComplaint) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning,
                            size: 14,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tenant Complaint',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showStatusFilter(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filter by Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<IssueStatus?>(
                  title: const Text('All Statuses'),
                  value: null,
                  groupValue: _selectedStatus,
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                    Navigator.pop(context);
                  },
                ),
                ...IssueStatus.values.map(
                  (status) => RadioListTile<IssueStatus>(
                    title: Text(status.toString().split('.').last),
                    value: status,
                    groupValue: _selectedStatus,
                    onChanged: (value) {
                      setState(() => _selectedStatus = value);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showPriorityFilter(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filter by Priority'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<IssuePriority?>(
                  title: const Text('All Priorities'),
                  value: null,
                  groupValue: _selectedPriority,
                  onChanged: (value) {
                    setState(() => _selectedPriority = value);
                    Navigator.pop(context);
                  },
                ),
                ...IssuePriority.values.map(
                  (priority) => RadioListTile<IssuePriority>(
                    title: Text(priority.toString().split('.').last),
                    value: priority,
                    groupValue: _selectedPriority,
                    onChanged: (value) {
                      setState(() => _selectedPriority = value);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showPropertyFilter(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filter by Property'),
            content: Consumer<PropertyProvider>(
              builder: (context, provider, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String?>(
                      title: const Text('All Properties'),
                      value: null,
                      groupValue: _selectedProperty,
                      onChanged: (value) {
                        setState(() => _selectedProperty = value);
                        Navigator.pop(context);
                      },
                    ),
                    ...provider.properties.map(
                      (property) => RadioListTile<String>(
                        title: Text(property.title),
                        value: property.id,
                        groupValue: _selectedProperty,
                        onChanged: (value) {
                          setState(() => _selectedProperty = value);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
    );
  }

  List<MaintenanceIssue> _filterIssues(
    List<MaintenanceIssue> issues,
    List<Property> properties,
  ) {
    return issues.where((issue) {
      if (_selectedStatus != null && issue.status != _selectedStatus) {
        return false;
      }
      if (_selectedPriority != null && issue.priority != _selectedPriority) {
        return false;
      }
      if (_selectedProperty != null && issue.propertyId != _selectedProperty) {
        return false;
      }
      if (_showOnlyComplaints && !issue.isTenantComplaint) {
        return false;
      }
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        return issue.title.toLowerCase().contains(searchTerm) ||
            issue.description.toLowerCase().contains(searchTerm);
      }
      return true;
    }).toList();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
