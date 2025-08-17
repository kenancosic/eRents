import 'package:e_rents_desktop/features/maintenance/providers/maintenance_provider.dart';
import 'package:e_rents_desktop/models/enums/maintenance_issue_priority.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/presentation/extensions.dart';

import 'package:e_rents_desktop/models/maintenance_issue.dart';
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
  bool _isTenantComplaint = false;
  List<picker.ImageInfo> _images = [];

  // Controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _provider = context.read<MaintenanceProvider>();

    final existing = widget.issue;
    _priority = existing?.priority ?? MaintenanceIssuePriority.medium;
    _isTenantComplaint = existing?.isTenantComplaint ?? false;
    _images = (existing?.imageIds ?? const <int>[]) 
        .map((id) => picker.ImageInfo(id: id, url: '/api/Images/$id'))
        .toList();

    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
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

  void _updateIsTenantComplaint(bool isComplaint) {
    setState(() {
      _isTenantComplaint = isComplaint;
    });
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
          propertyId: widget.propertyId ?? initial?.propertyId ?? 0,
          title: _titleController.text,
          description: _descriptionController.text,
          priority: _priority,
          reportedByUserId: initial?.reportedByUserId ?? 1, // TODO: auth provider
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
          title: _titleController.text,
          description: _descriptionController.text,
          priority: _priority,
          isTenantComplaint: _isTenantComplaint,
          imageIds: imageIds,
        );
      },
      validator: (item) {
        if (item.title.trim().isEmpty) return 'Please enter a title';
        if ((item.description ?? '').trim().isEmpty) return 'Please enter a description';
        if (item.propertyId <= 0) return 'Invalid property';
        return null;
      },
      onSubmit: (item) async {
        final ok = await _provider.save(item);
        return ok;
      },
      formBuilder: (context, item, formKey) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              validator: (value) => (value == null || value.isEmpty) ? 'Please enter a description' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<MaintenanceIssuePriority>(
                    value: _priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
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
                    onChanged: (value) {
                      if (value != null) _updatePriority(value);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Tenant Complaint'),
              value: _isTenantComplaint,
              onChanged: _updateIsTenantComplaint,
            ),
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
  }
}
