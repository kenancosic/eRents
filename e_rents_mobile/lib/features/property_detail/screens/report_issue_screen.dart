import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_mobile/core/enums/maintenance_issue_enums.dart';

import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/features/profile/providers/user_profile_provider.dart';
import 'package:e_rents_mobile/features/property_detail/providers/maintenance_issues_provider.dart';

class ReportIssueScreen extends StatefulWidget {
  final int propertyId;
  final int bookingId;

  const ReportIssueScreen({
    super.key,
    required this.propertyId,
    required this.bookingId,
  });

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  MaintenanceIssuePriority _selectedPriority = MaintenanceIssuePriority.medium;
  final List<File> _selectedImages = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                context.pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                context.pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get current user from provider
      final userProvider = context.read<UserProfileProvider>();
      final currentUser = userProvider.user;

      if (currentUser == null || currentUser.userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not found. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final maintenanceProvider = context.read<MaintenanceIssuesProvider>();

      final success = await maintenanceProvider.reportMaintenanceIssue(
        widget.propertyId,
        _titleController.text.trim(),
        _descriptionController.text.trim(),
        priorityId: _selectedPriority.index + 1, // Convert enum to 1-based ID
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Issue reported successfully! Your landlord has been notified.'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to report issue. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      appBar: CustomAppBar(
        title: 'Report Issue',
        showBackButton: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Issue Title *',
                hintText: 'e.g., Leaky faucet, Broken heating',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title for the issue';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Priority selector
            DropdownButtonFormField<MaintenanceIssuePriority>(
              initialValue: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Priority Level *',
                border: OutlineInputBorder(),
              ),
              items: MaintenanceIssuePriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getPriorityColor(priority),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_getPriorityLabel(priority)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPriority = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe the issue in detail...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please provide a description of the issue';
                }
                if (value.trim().length < 10) {
                  return 'Please provide more details (at least 10 characters)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Images section
            const Text(
              'Photos (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add photos to help your landlord understand the issue better.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),

            // Image grid
            if (_selectedImages.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(_selectedImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

            // Add image button
            const SizedBox(height: 12),
            if (_selectedImages.length < 5) // Limit to 5 images
              CustomOutlinedButton(
                onPressed: _showImageSourceOptions,
                icon: Icons.add_a_photo,
                isLoading: false,
                label:
                    _selectedImages.isEmpty ? 'Add Photos' : 'Add More Photos',
                size: OutlinedButtonSize.normal,
                width: OutlinedButtonWidth.expanded,
              ),

            if (_selectedImages.length >= 5)
              const Text(
                'Maximum 5 photos allowed',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: CustomOutlinedButton(
                    label: 'Save Draft',
                    icon: Icons.save_outlined,
                    isLoading: false,
                    width: OutlinedButtonWidth.expanded,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Draft saved successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    icon: Icons.send,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? () {} : _submitReport,
                    label: Text(
                      _isSubmitting ? 'Submitting...' : 'Submit Report',
                      style: const TextStyle(color: Colors.white),
                    ),
                    width: ButtonWidth.expanded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(MaintenanceIssuePriority priority) {
    switch (priority) {
      case MaintenanceIssuePriority.low:
        return Colors.green;
      case MaintenanceIssuePriority.medium:
        return Colors.orange;
      case MaintenanceIssuePriority.high:
        return Colors.red;
      case MaintenanceIssuePriority.emergency:
        return Colors.purple;
    }
  }

  String _getPriorityLabel(MaintenanceIssuePriority priority) {
    switch (priority) {
      case MaintenanceIssuePriority.low:
        return 'Low Priority';
      case MaintenanceIssuePriority.medium:
        return 'Medium Priority';
      case MaintenanceIssuePriority.high:
        return 'High Priority';
      case MaintenanceIssuePriority.emergency:
        return 'Emergency';
    }
  }
}
