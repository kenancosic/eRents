import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/providers/maintenance_provider.dart';
import 'package:e_rents_desktop/providers/property_provider.dart';

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

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<MaintenanceProvider>().fetchIssues();
      context.read<PropertyProvider>().fetchProperties();
    });
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
              _buildFilters(context),
              const SizedBox(height: 16),
              Expanded(child: _buildIssuesList(context, filteredIssues)),
            ],
          );
        },
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
            const Text(
              'Filters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                // Calculate if we need to stack filters vertically
                final isNarrow = constraints.maxWidth < 1000;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width:
                          isNarrow
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 48) / 3,
                      child: DropdownButtonFormField<IssueStatus?>(
                        value: _selectedStatus,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Statuses'),
                          ),
                          ...IssueStatus.values.map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.toString().split('.').last),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width:
                          isNarrow
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 48) / 3,
                      child: DropdownButtonFormField<IssuePriority?>(
                        value: _selectedPriority,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Priorities'),
                          ),
                          ...IssuePriority.values.map(
                            (priority) => DropdownMenuItem(
                              value: priority,
                              child: Text(priority.toString().split('.').last),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedPriority = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width:
                          isNarrow
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 48) / 3,
                      child: Consumer<PropertyProvider>(
                        builder: (context, propertyProvider, child) {
                          return DropdownButtonFormField<String?>(
                            value: _selectedProperty,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Property',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All Properties'),
                              ),
                              ...propertyProvider.properties.map(
                                (property) => DropdownMenuItem(
                                  value: property.id,
                                  child: Text(property.title),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedProperty = value;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: isNarrow ? constraints.maxWidth : 200,
                      child: SwitchListTile(
                        title: const Text('Show Only Complaints'),
                        value: _showOnlyComplaints,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _showOnlyComplaints = value;
                          });
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssuesList(BuildContext context, List<MaintenanceIssue> issues) {
    if (issues.isEmpty) {
      return const Center(child: Text('No maintenance issues found'));
    }

    return ListView.builder(
      itemCount: issues.length,
      itemBuilder: (context, index) {
        final issue = issues[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: issue.priorityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _getIssueIcon(issue.category),
                color: issue.priorityColor,
              ),
            ),
            title: Text(issue.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(issue.description),
                const SizedBox(height: 4),
                Row(
                  children: [
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
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (issue.isTenantComplaint)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Tenant Complaint',
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            trailing: Text(
              _formatDate(issue.createdAt),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      'Property',
                      context
                          .read<PropertyProvider>()
                          .properties
                          .firstWhere(
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
                                  maintenanceRequests: [],
                                ),
                          )
                          .title,
                    ),
                    _buildDetailRow('Reported By', issue.reportedBy),
                    if (issue.assignedTo != null)
                      _buildDetailRow('Assigned To', issue.assignedTo!),
                    if (issue.category != null)
                      _buildDetailRow('Category', issue.category!),
                    if (issue.cost != null)
                      _buildDetailRow(
                        'Cost',
                        '\$${issue.cost!.toStringAsFixed(2)}',
                      ),
                    if (issue.resolutionNotes != null)
                      _buildDetailRow(
                        'Resolution Notes',
                        issue.resolutionNotes!,
                      ),
                    if (issue.images.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Images',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: issue.images.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => Dialog(
                                          child: Image.asset(
                                            issue.images[index],
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    issue.images[index],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            // TODO: Implement edit functionality
                          },
                          child: const Text('Edit'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Implement status update functionality
                          },
                          child: const Text('Update Status'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
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
      return true;
    }).toList();
  }

  IconData _getIssueIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electric_bolt;
      case 'structural':
        return Icons.home_repair_service;
      default:
        return Icons.build;
    }
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
