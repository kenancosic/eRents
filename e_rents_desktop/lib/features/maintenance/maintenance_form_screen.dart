import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/features/maintenance/providers/maintenance_collection_provider.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/widgets/inputs/image_picker_input.dart';
import 'package:e_rents_desktop/models/image_info.dart' as erents;

class MaintenanceFormScreen extends StatefulWidget {
  final int? propertyId;
  final MaintenanceIssue? issue;

  const MaintenanceFormScreen({super.key, this.propertyId, this.issue});

  @override
  State<MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends State<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late IssuePriority _priority;
  late bool _isTenantComplaint;
  List<erents.ImageInfo> _images = [];
  int _currentUserId = 0;

  @override
  void initState() {
    super.initState();
    _currentUserId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? 0;
    _titleController = TextEditingController(text: widget.issue?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.issue?.description ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.issue?.category ?? '',
    );
    _priority = widget.issue?.priority ?? IssuePriority.medium;
    _isTenantComplaint = widget.issue?.isTenantComplaint ?? false;
    _images = List.from(widget.issue?.images ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  MaintenanceIssue _createIssue() {
    return MaintenanceIssue(
      maintenanceIssueId: widget.issue?.maintenanceIssueId ?? 0,
      propertyId: widget.propertyId ?? widget.issue?.propertyId ?? 0,
      title: _titleController.text,
      description: _descriptionController.text,
      priority: _priority,
      status: widget.issue?.status ?? IssueStatus.pending,
      createdAt: widget.issue?.createdAt ?? DateTime.now(),
      resolvedAt: widget.issue?.resolvedAt,
      cost: widget.issue?.cost,
      assignedTo: widget.issue?.assignedTo,
      images: _images,
      reportedBy: _currentUserId,
      resolutionNotes: widget.issue?.resolutionNotes,
      category: _categoryController.text,
      requiresInspection: widget.issue?.requiresInspection ?? false,
      isTenantComplaint: _isTenantComplaint,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    value: _priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        IssuePriority.values
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
                        setState(() => _priority = value);
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
              value: _isTenantComplaint,
              onChanged: (value) {
                setState(() => _isTenantComplaint = value);
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Attached Images',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ImagePickerInput(
              initialImages: _images,
              onChanged: (updatedImages) {
                setState(() {
                  _images =
                      updatedImages
                          .map(
                            (imgInfo) => erents.ImageInfo(
                              id: imgInfo.id ?? 0,
                              url: imgInfo.url,
                              fileName: imgInfo.fileName,
                            ),
                          )
                          .toList();
                });
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    if (widget.propertyId != null) {
                      context.go('/properties/${widget.propertyId}');
                    } else {
                      context.go('/maintenance');
                    }
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final issue = _createIssue();
                      final provider =
                          context.read<MaintenanceCollectionProvider>();
                      try {
                        // Loading state will be managed by provider
                        if (widget.issue == null) {
                          await provider.addItem(issue);
                          final newIssues =
                              provider.items
                                  .where(
                                    (i) =>
                                        i.title == issue.title &&
                                        i.propertyId == issue.propertyId &&
                                        i.maintenanceIssueId != 0,
                                  )
                                  .toList();

                          if (mounted && newIssues.isNotEmpty) {
                            final newIssue = newIssues.last;
                            context.go(
                              '/maintenance/${newIssue.maintenanceIssueId}',
                            );
                            return;
                          }
                        } else {
                          await provider.updateItem(
                            issue.maintenanceIssueId.toString(),
                            issue,
                          );
                        }
                        if (mounted) {
                          if (widget.propertyId != null) {
                            context.go('/properties/${widget.propertyId}');
                          } else {
                            context.go('/maintenance');
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } finally {
                        // Loading state managed by provider
                      }
                    }
                  },
                  child: Text(widget.issue == null ? 'Create' : 'Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
