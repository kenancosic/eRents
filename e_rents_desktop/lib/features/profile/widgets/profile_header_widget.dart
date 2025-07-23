import 'package:flutter/material.dart';
import 'package:e_rents_desktop/widgets/custom_avatar.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/profile/providers/profile_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ProfileHeaderWidget extends StatefulWidget {
  final Future<void> Function(String path)? onImageUploaded;

  const ProfileHeaderWidget({
    super.key,
    this.onImageUploaded,
  });

  @override
  State<ProfileHeaderWidget> createState() => _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends State<ProfileHeaderWidget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null && widget.onImageUploaded != null) {
        await widget.onImageUploaded!(pickedFile.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final user = profileProvider.currentUser;

    // Determine which image to show
    String? imageUrl;
    if (user?.profileImageId != null) {
      imageUrl = '/Image/${user!.profileImageId}';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withAlpha(77),
            Theme.of(context).colorScheme.secondaryContainer.withAlpha(26),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Profile Image Section
          Stack(
            children: [
              CustomAvatar(
                imageUrl: imageUrl ?? 'assets/images/user-image.png',
                size: 80,
                borderWidth: 3,
              ),
              if (profileProvider.isEditing)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                      onPressed: () => _showImagePickerDialog(),
                      constraints: const BoxConstraints.tightFor(
                        width: 28,
                        height: 28,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 20),

          // User Info Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'John Doe',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.business,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user?.role.toString().split('.').last.toUpperCase() ??
                          'LANDLORD',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.email,
                      size: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(153),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user?.email ?? 'john.doe@example.com',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(179),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Edit Toggle Button
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: profileProvider.toggleEditing,
              icon: Icon(
                profileProvider.isEditing ? Icons.edit_off : Icons.edit,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: profileProvider.isEditing ? 'Stop Editing' : 'Edit Profile',
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Change Profile Picture'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    _pickImage(ImageSource.gallery);
                    context.pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    _pickImage(ImageSource.camera);
                    context.pop();
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }
}
