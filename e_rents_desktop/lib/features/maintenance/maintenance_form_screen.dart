import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/features/maintenance/providers/maintenance_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class MaintenanceFormScreen extends StatefulWidget {
  final String? propertyId;
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
  List<String> _images = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _pickImages() async {
    try {
      setState(() => _isLoading = true);
      // TODO: Implement image picking functionality
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  MaintenanceIssue _createIssue() {
    return MaintenanceIssue(
      id: widget.issue?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      propertyId: widget.propertyId ?? widget.issue?.propertyId ?? '',
      title: _titleController.text,
      description: _descriptionController.text,
      priority: _priority,
      status: widget.issue?.status ?? IssueStatus.pending,
      createdAt: widget.issue?.createdAt ?? DateTime.now(),
      resolvedAt: widget.issue?.resolvedAt,
      cost: widget.issue?.cost,
      assignedTo: widget.issue?.assignedTo,
      images: _images,
      reportedBy:
          widget.issue?.reportedBy ?? 'Current User', // TODO: Get actual user
      resolutionNotes: widget.issue?.resolutionNotes,
      category: _categoryController.text,
      requiresInspection: widget.issue?.requiresInspection ?? false,
      isTenantComplaint: _isTenantComplaint,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: widget.issue == null ? 'New Maintenance Issue' : 'Edit Issue',
      currentPath: '/maintenance',
      child: SingleChildScrollView(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_images.length} Images',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickImages,
                    icon:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.add_photo_alternate),
                    label: const Text('Add Images'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_images.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No images added yet',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click the button above to add images',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    final image = _images[index];
                    return Card(
                      key: ValueKey(image),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(image, fit: BoxFit.cover),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () => _removeImage(index),
                                padding: const EdgeInsets.all(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
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
                        final provider = context.read<MaintenanceProvider>();
                        try {
                          setState(() => _isLoading = true);
                          if (widget.issue == null) {
                            await provider.addItem(issue);
                          } else {
                            await provider.updateItem(issue);
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
                          if (mounted) {
                            setState(() => _isLoading = false);
                          }
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
      ),
    );
  }
}
