import 'package:flutter/material.dart';
import 'package:e_rents_desktop/widgets/custom_avatar.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/profile/providers/profile_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ProfileHeaderWidget extends StatefulWidget {
  final bool isEditing;
  final VoidCallback onEditPressed;
  final VoidCallback? onCancelPressed;

  const ProfileHeaderWidget({
    super.key,
    required this.isEditing,
    required this.onEditPressed,
    this.onCancelPressed,
  });

  @override
  State<ProfileHeaderWidget> createState() => _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends State<ProfileHeaderWidget> {
  final ImagePicker _picker = ImagePicker();
  String? _tempProfileImagePath;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _tempProfileImagePath = pickedFile.path;
        });

        if (!mounted) return;

        // Update profile image in provider
        final profileProvider = Provider.of<ProfileProvider>(
          context,
          listen: false,
        );
        await profileProvider.updateProfileImage(_tempProfileImagePath!);
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
    final profileProvider = Provider.of<ProfileProvider>(context);
    final user = profileProvider.currentUser;

    // Determine which image to show
    if (_tempProfileImagePath == null) {
      _tempProfileImagePath =
          user?.profileImage ?? 'assets/images/user-image.png';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Stack(
            children: [
              CustomAvatar(
                imageUrl: _tempProfileImagePath!,
                size: 100,
                borderWidth: 3,
              ),
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
                      size: 20,
                    ),
                    onPressed: () {
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
                    },
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'John Doe',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  user?.role.toString() ?? 'Property Manager',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: widget.onEditPressed,
                      icon: Icon(widget.isEditing ? Icons.save : Icons.edit),
                      label: Text(
                        widget.isEditing ? 'Save Changes' : 'Edit Profile',
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (widget.isEditing && widget.onCancelPressed != null)
                      TextButton.icon(
                        onPressed: widget.onCancelPressed,
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancel'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
