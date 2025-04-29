import 'dart:io'; // Required for File operations if using actual file paths

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

/// A widget for picking, displaying, and managing a list of image paths.
class ImagePickerInput extends StatefulWidget {
  final List<String> initialImages; // List of image paths (or identifiers)
  final Function(List<String> updatedImages) onChanged;

  const ImagePickerInput({
    super.key,
    required this.initialImages,
    required this.onChanged,
  });

  @override
  State<ImagePickerInput> createState() => _ImagePickerInputState();
}

class _ImagePickerInputState extends State<ImagePickerInput> {
  late List<String> _images;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.initialImages);
  }

  @override
  void didUpdateWidget(covariant ImagePickerInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update state if initial images change externally
    if (widget.initialImages != oldWidget.initialImages) {
      setState(() {
        _images = List.from(widget.initialImages);
      });
    }
  }

  Future<void> _pickImages() async {
    setState(() => _isLoading = true);
    try {
      final typeGroup = XTypeGroup(
        label: 'images',
        extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'], // Added webp
      );
      // Use openFiles to allow selecting multiple images
      final files = await openFiles(acceptedTypeGroups: [typeGroup]);

      if (files.isNotEmpty) {
        // Assuming we store paths. If storing bytes, handle that here.
        final newImagePaths = files.map((file) => file.path).toList();
        setState(() {
          _images.addAll(newImagePaths);
        });
        widget.onChanged(_images);
      }
    } catch (e) {
      // Handle potential errors during file picking
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
    widget.onChanged(_images);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              // Dynamic count based on the current state
              '${_images.length} Image${_images.length == 1 ? '' : 's'}',
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
        if (_images.isEmpty) _buildEmptyState() else _buildImageGrid(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity, // Take full available width
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey[100], // Subtle background
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_search, // More descriptive icon
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No images selected',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Click the button above to add images.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    // Determine cross axis count based on available width
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = (constraints.maxWidth / 150).floor().clamp(2, 5);
        // Adjust the 150 (approx item width) as needed

        return GridView.builder(
          shrinkWrap: true, // Important for use in Column/ScrollView
          physics:
              const NeverScrollableScrollPhysics(), // Disable grid scrolling
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1, // Square images
          ),
          itemCount: _images.length,
          itemBuilder: (context, index) {
            final imagePath = _images[index];
            // Use FileImage for local paths, NetworkImage for URLs
            // Assuming local paths for now
            // TODO: Handle potential errors loading image (e.g., file not found)
            final imageProvider = FileImage(File(imagePath));

            return Card(
              key: ValueKey(imagePath), // Use path as key
              clipBehavior: Clip.antiAlias,
              elevation: 2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image(
                    image: imageProvider,
                    fit: BoxFit.cover,
                    // Add error builder for robustness
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.grey[400]),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                'Load Error',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    // Optional: Add loading builder
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                          strokeWidth: 2,
                        ),
                      );
                    },
                  ),
                  // Remove button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      // Use Material for InkWell effect
                      color: Colors.black.withOpacity(0.6),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => _removeImage(index),
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Cover image indicator (optional)
                  if (index == 0)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Cover',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
