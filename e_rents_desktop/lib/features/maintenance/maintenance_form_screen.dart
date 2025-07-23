import 'package:e_rents_desktop/features/maintenance/providers/maintenance_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/widgets/inputs/image_picker_input.dart' as picker;
import 'package:e_rents_desktop/models/image_info.dart' as erents;

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
  final _formKey = GlobalKey<FormState>();
  late MaintenanceProvider _provider;

  late MaintenanceIssue _issue;
  List<erents.ImageInfo> _images = [];
  bool _isLoading = false;
  String? _errorMessage;

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _provider = context.read<MaintenanceProvider>();

    if (widget.issue != null) {
      _issue = widget.issue!.copyWith();
      _images = widget.issue!.imageIds
          .map((id) => erents.ImageInfo(id: id, url: '/Image/$id'))
          .toList();
    } else {
      _issue = MaintenanceIssue.empty().copyWith(
        propertyId: widget.propertyId,
        tenantId: widget.tenantId,
        createdAt: DateTime.now(),
      );
    }

    _titleController = TextEditingController(text: _issue.title);
    _descriptionController = TextEditingController(text: _issue.description);
    _categoryController = TextEditingController(text: _issue.category);

    _addListeners();
  }

  void _addListeners() {
    _titleController.addListener(() {
      _issue = _issue.copyWith(title: _titleController.text);
    });
    _descriptionController.addListener(() {
      _issue = _issue.copyWith(description: _descriptionController.text);
    });
    _categoryController.addListener(() {
      _issue = _issue.copyWith(category: _categoryController.text);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _updatePriority(IssuePriority priority) {
    setState(() {
      _issue = _issue.copyWith(priority: priority);
    });
  }

  void _updateIsTenantComplaint(bool isComplaint) {
    setState(() {
      _issue = _issue.copyWith(isTenantComplaint: isComplaint);
    });
  }

  void _updateImages(List<erents.ImageInfo> updatedImages) {
    final imageIds = updatedImages
        .map((img) => img.id)
        .where((id) => id != null && id > 0)
        .cast<int>()
        .toList();
    setState(() {
      _images = updatedImages;
      _issue = _issue.copyWith(imageIds: imageIds);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = 'Please fix the errors before saving.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _provider.save(_issue);
      if (success && mounted) {
        final savedIssue = _provider.issues.firstWhere(
          (i) => i.propertyId == _issue.propertyId && i.title == _issue.title,
        );
        context.go('/maintenance/${savedIssue.maintenanceIssueId}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Issue Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<IssuePriority>(
                    value: _issue.priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: IssuePriority.values
                        .map(
                          (priority) => DropdownMenuItem(
                            value: priority,
                            child: Text(
                              priority.toString().split('.').last,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _updatePriority(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a category';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Tenant Complaint'),
              value: _issue.isTenantComplaint,
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
              onChanged: (images) => _updateImages(images
                  .map((img) => erents.ImageInfo(
                        id: img.id,
                        url: img.url,
                        fileName: img.fileName,
                      ))
                  .toList()),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          final propertyId = _issue.propertyId;
                          if (propertyId > 0) {
                            context.go('/properties/$propertyId');
                          } else {
                            context.go('/maintenance');
                          }
                        },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: const Text('Save Issue'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
