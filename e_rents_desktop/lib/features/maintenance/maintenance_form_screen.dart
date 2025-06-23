import 'package:e_rents_desktop/features/maintenance/state/maintenance_form_state.dart';
import 'package:e_rents_desktop/repositories/maintenance_repository.dart';
import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/widgets/inputs/image_picker_input.dart';
import 'package:e_rents_desktop/models/image_info.dart' as erents;
import 'package:e_rents_desktop/base/service_locator.dart';

class MaintenanceFormScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (context) => MaintenanceFormState(
            getService<MaintenanceRepository>(),
            issue,
            propertyId: propertyId,
            tenantId: tenantId,
          ),
      child: const _MaintenanceFormView(),
    );
  }
}

class _MaintenanceFormView extends StatelessWidget {
  const _MaintenanceFormView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MaintenanceFormState>();

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: state.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.errorMessage != null) ...[
              Text(
                state.errorMessage!,
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
              controller: state.titleController,
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
              controller: state.descriptionController,
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
                    value: state.issue.priority,
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
                        state.updatePriority(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: state.categoryController,
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
              value: state.issue.isTenantComplaint,
              onChanged: (value) {
                state.updateIsTenantComplaint(value);
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Attached Images',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ImagePickerInput(
              initialImages: state.images,
              onChanged: (updatedImages) {
                state.updateImages(
                  updatedImages
                      .map(
                        (img) => erents.ImageInfo(
                          id: img.id,
                          url: img.url,
                          fileName: img.fileName,
                          // No 'path' property available on the picker's ImageInfo
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      state.isLoading
                          ? null
                          : () {
                            final propertyId = state.issue.propertyId;
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
                  onPressed:
                      state.isLoading
                          ? null
                          : () async {
                            final savedIssue = await state.save();
                            if (savedIssue != null && context.mounted) {
                              context.go(
                                '/maintenance/${savedIssue.maintenanceIssueId}',
                              );
                            }
                          },
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
