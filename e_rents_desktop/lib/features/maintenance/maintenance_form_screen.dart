import 'package:e_rents_desktop/features/maintenance/providers/maintenance_provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/models/enums/maintenance_issue_priority.dart';
import 'package:e_rents_desktop/models/enums/maintenance_issue_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/presentation/extensions.dart';

import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/widgets/inputs/image_picker_input.dart' as picker;
import 'package:e_rents_desktop/base/crud/form_screen.dart';

class MaintenanceFormScreen extends StatefulWidget {
  final int? propertyId;
  final MaintenanceIssue? issue;
  final int? tenantId;

  const MaintenanceFormScreen({
    super.key,
    this.propertyId,
    this.issue,
    this.tenantId,
  });

  @override
  State<MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends State<MaintenanceFormScreen> {
  late MaintenanceProvider _provider;

  // Local form state captured by createNewItem/updateItem closures
  late MaintenanceIssuePriority _priority;
  late MaintenanceIssueStatus _status;
  bool _isTenantComplaint = false;
  List<picker.ImageInfo> _images = [];
  Property? _selectedProperty;
  User? _selectedTenant;

  // Controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _provider = context.read<MaintenanceProvider>();

    final existing = widget.issue;
    _priority = existing?.priority ?? MaintenanceIssuePriority.medium;
    _status = existing?.status ?? MaintenanceIssueStatus.pending;
    _isTenantComplaint = existing?.isTenantComplaint ?? false;
    _images = (existing?.imageIds ?? const <int>[]) 
        .map((id) => picker.ImageInfo(id: id, url: 'Images/$id'))
        .toList();

    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    
    // Load properties when form initializes (using PropertyProvider to avoid duplication)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().loadProperties();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updatePriority(MaintenanceIssuePriority priority) {
    setState(() {
      _priority = priority;
    });
  }

  void _updateStatus(MaintenanceIssueStatus status) {
    setState(() {
      _status = status;
    });
  }

  void _updateIsTenantComplaint(bool isComplaint) {
    setState(() {
      _isTenantComplaint = isComplaint;
      if (!isComplaint) {
        _selectedTenant = null;
        _provider.clearTenants();
      } else if (_selectedProperty != null) {
        _provider.loadTenantsForProperty(_selectedProperty!.propertyId);
      }
    });
  }

  void _updateSelectedProperty(Property? property) {
    setState(() {
      _selectedProperty = property;
      _selectedTenant = null;
      _provider.clearTenants();
      
      if (property != null && _isTenantComplaint) {
        _provider.loadTenantsForProperty(property.propertyId);
      }
    });
  }

  void _updateSelectedTenant(User? tenant) {
    setState(() {
      _selectedTenant = tenant;
    });
  }

  /// Get display name for property dropdown
  String _getPropertyDisplayName(Property property) {
    final name = property.name;
    final address = property.address;
    if (address != null) {
      return '$name - ${address.city ?? ''}';
    }
    return name;
  }

  void _updateImages(List<picker.ImageInfo> updatedImages) {
    setState(() {
      _images = updatedImages;
    });
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.issue;
    return FormScreen<MaintenanceIssue>(
      title: initial == null ? 'New Maintenance Issue' : 'Edit Maintenance Issue',
      initialItem: initial,
      autovalidate: false,
      createNewItem: () {
        final imageIds = _images
            .map((img) => img.id)
            .where((id) => id != null && id > 0)
            .cast<int>()
            .toList();
        return MaintenanceIssue.empty().copyWith(
          propertyId: _selectedProperty?.propertyId ?? widget.propertyId ?? initial?.propertyId ?? 0,
          title: _titleController.text,
          description: _descriptionController.text,
          priority: _priority,
          status: _status,
          reportedByUserId: _selectedTenant?.userId ?? initial?.reportedByUserId ?? 1,
          isTenantComplaint: _isTenantComplaint,
          imageIds: imageIds,
        );
      },
      updateItem: (existing) {
        final imageIds = _images
            .map((img) => img.id)
            .where((id) => id != null && id > 0)
            .cast<int>()
            .toList();
        return existing.copyWith(
          propertyId: _selectedProperty?.propertyId ?? existing.propertyId,
          title: _titleController.text,
          description: _descriptionController.text,
          priority: _priority,
          status: _status,
          reportedByUserId: _selectedTenant?.userId ?? existing.reportedByUserId,
          isTenantComplaint: _isTenantComplaint,
          imageIds: imageIds,
        );
      },
      validator: (item) {
        if (item.title.trim().isEmpty) return 'Please enter a title';
        if (item.propertyId <= 0) return 'Please select a property';
        // Status and priority are enums, so they always have values
        return null;
      },
      onSubmit: (item) async {
        final ok = await _provider.save(item);
        return ok;
      },
      formBuilder: (context, item, formKey) {
        return Consumer2<MaintenanceProvider, PropertyProvider>(
          builder: (context, maintenanceProvider, propertyProvider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property Selection Dropdown (using PropertyProvider)
                DropdownButtonFormField<Property>(
                  value: _selectedProperty,
                  decoration: const InputDecoration(
                    labelText: 'Property *',
                    border: OutlineInputBorder(),
                    hintText: 'Select a property',
                  ),
                  items: propertyProvider.items
                      .map(
                        (property) => DropdownMenuItem(
                          value: property,
                          child: Text(_getPropertyDisplayName(property)),
                        ),
                      )
                      .toList(),
                  onChanged: _updateSelectedProperty,
                  validator: (value) => value == null ? 'Please select a property' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<MaintenanceIssuePriority>(
                        value: _priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority *',
                          border: OutlineInputBorder(),
                        ),
                        items: MaintenanceIssuePriority.values
                            .map(
                              (priority) => DropdownMenuItem(
                                value: priority,
                                child: Row(
                                  children: [
                                    Icon(priority.icon, color: priority.color, size: 18),
                                    const SizedBox(width: 8),
                                    Text(priority.displayName),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        selectedItemBuilder: (context) {
                          return MaintenanceIssuePriority.values.map((priority) {
                            return Row(
                              children: [
                                Icon(priority.icon, color: priority.color, size: 18),
                                const SizedBox(width: 8),
                                Text(priority.displayName),
                              ],
                            );
                          }).toList();
                        },
                        validator: (value) => value == null ? 'Please select a priority' : null,
                        onChanged: (value) {
                          if (value != null) _updatePriority(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<MaintenanceIssueStatus>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status *',
                          border: OutlineInputBorder(),
                        ),
                        items: MaintenanceIssueStatus.values
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.displayName),
                              ),
                            )
                            .toList(),
                        validator: (value) => value == null ? 'Please select a status' : null,
                        onChanged: (value) {
                          if (value != null) _updateStatus(value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Tenant Complaint'),
                  subtitle: const Text('Check if this is a complaint from a tenant'),
                  value: _isTenantComplaint,
                  onChanged: _updateIsTenantComplaint,
                ),
                if (_isTenantComplaint && _selectedProperty != null) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<User>(
                    value: _selectedTenant,
                    decoration: const InputDecoration(
                      labelText: 'Tenant *',
                      border: OutlineInputBorder(),
                      hintText: 'Select the tenant who reported this issue',
                    ),
                    items: maintenanceProvider.tenants
                        .map(
                          (tenant) => DropdownMenuItem(
                            value: tenant,
                            child: Text(maintenanceProvider.getTenantDisplayName(tenant)),
                          ),
                        )
                        .toList(),
                    onChanged: _updateSelectedTenant,
                    validator: (value) => _isTenantComplaint && value == null ? 'Please select a tenant' : null,
                  ),
                ],
                const SizedBox(height: 32),
                Text(
                  'Attached Images',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                picker.ImagePickerInput(
                  initialImages: _images
                      .map((img) => picker.ImageInfo(
                            id: img.id,
                            url: img.url,
                            fileName: img.fileName,
                          ))
                      .toList(),
                  apiService: _provider.apiService,
                  onChanged: _updateImages,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
