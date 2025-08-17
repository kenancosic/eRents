import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/image_service.dart';
import 'package:e_rents_desktop/models/image.dart' as model;


/// A widget for picking, displaying, and managing a list of image paths.
class ImageInfo {
  final int? id;
  final String? fileName;
  final String? url;
  final Uint8List? data;
  final bool isCover;
  final bool isNew; // Flag to indicate if this is a newly selected image

  ImageInfo({
    this.id,
    this.fileName,
    this.url,
    this.data,
    this.isCover = false,
    this.isNew = false,
  });

  ImageInfo copyWith({
    int? id,
    String? fileName,
    String? url,
    Uint8List? data,
    bool? isCover,
    bool? isNew,
  }) {
    return ImageInfo(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      url: url ?? this.url,
      data: data ?? this.data,
      isCover: isCover ?? this.isCover,
      isNew: isNew ?? this.isNew,
    );
  }
}

class ImagePickerInput extends StatefulWidget {
  final List<dynamic> initialImages;
  final Function(List<ImageInfo>) onChanged;
  final int maxImages;
  final bool allowReordering;
  final bool allowCoverSelection;
  final String emptyStateText;
  final ApiService apiService;

  const ImagePickerInput({
    super.key,
    this.initialImages = const [],
    required this.onChanged,
    required this.apiService,
    this.maxImages = 10,
    this.allowReordering = true,
    this.allowCoverSelection = true,
    this.emptyStateText = 'No images selected. Click to add images.',
  });

  @override
  State<ImagePickerInput> createState() => _ImagePickerInputState();
}

class _ImagePickerInputState extends State<ImagePickerInput> {
  List<ImageInfo> _images = [];

  @override
  void initState() {
    super.initState();
    _initializeImages();
  }

  @override
  void didUpdateWidget(ImagePickerInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialImages != widget.initialImages) {
      _initializeImages();
    }
  }

  void _initializeImages() {
    _images =
        widget.initialImages.map((img) {
          if (img is Map<String, dynamic>) {
            // Backend image format
            return ImageInfo(
              id: img['imageId'] ?? img['id'],
              fileName: img['fileName'] ?? 'image.jpg',
              url: img['url'],
              isCover: img['isCover'] ?? false,
              isNew: false,
            );
          } else if (img is ImageInfo) {
            return img;
          } else {
            // Fallback
            return ImageInfo(fileName: 'image.jpg', isNew: false);
          }
        }).toList();
  }

  Future<void> _pickImages() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result != null) {
        final newImages =
            result.files.map((file) {
              return ImageInfo(
                fileName: file.name,
                data: file.bytes,
                isNew: true,
              );
            }).toList();

        setState(() {
          _images.addAll(newImages);
          // Limit to maxImages
          if (_images.length > widget.maxImages) {
            _images = _images.sublist(0, widget.maxImages);
          }
        });

        widget.onChanged(_images);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
    widget.onChanged(_images);
  }

  void _setCoverImage(int index) {
    if (!widget.allowCoverSelection) return;

    setState(() {
      for (int i = 0; i < _images.length; i++) {
        _images[i] = _images[i].copyWith(isCover: i == index);
      }
    });
    widget.onChanged(_images);
  }

  void _reorderImages(int oldIndex, int newIndex) {
    if (!widget.allowReordering) return;

    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);
    });
    widget.onChanged(_images);
  }

  Widget _buildImageTile(ImageInfo image, int index) {
    return Card(
      margin: const EdgeInsets.all(4.0),
      child: Stack(
        children: [
          // Image display
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: _buildImageWidget(image),
            ),
          ),

          // Cover badge
          if (image.isCover && widget.allowCoverSelection)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'COVER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // New badge
          if (image.isNew)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Action buttons
          Positioned(
            bottom: 4,
            right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.allowCoverSelection && !image.isCover)
                  InkWell(
                    onTap: () => _setCoverImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star_border,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _removeImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // File name
          Positioned(
            bottom: 4,
            left: 4,
            right: 50,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                image.fileName ??
                    (image.id != null
                        ? 'Property Image ${image.id}'
                        : 'image.jpg'),
                style: const TextStyle(color: Colors.white, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(ImageInfo image) {
    if (image.data != null) {
      // New image with local data
      return Image.memory(
        image.data!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    } else if (image.url != null) {
      // If URL points to our Images API (JSON), fetch bytes via ImageService
      final url = image.url!;
      ImageService? images;
      try {
        images = context.read<ImageService>();
      } catch (_) {
        images = null;
      }
      if (images != null && url.startsWith('/api/Images/')) {
        final idStr = url.replaceFirst('/api/Images/', '');
        final id = int.tryParse(idStr);
        if (id != null) {
          return images.buildImageById(
            id,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 120,
            errorWidget: _buildErrorWidget(),
          );
        }
      }
      // Fallback: if this is an API Images JSON endpoint and ImageService is unavailable,
      // avoid delegating to ApiService.buildImage (would call Image.network on JSON).
      if (url.startsWith('/api/Images/')) {
        return _buildErrorWidget();
      }
      // Non-API URL: safe to use ApiService.buildImage
      return widget.apiService.buildImage(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 120,
      );
    } else if (image.id != null) {
      // Existing image with ID - use ImageService to fetch bytes
      ImageService? images;
      try {
        images = context.read<ImageService>();
      } catch (_) {
        images = null;
      }
      if (images != null) {
        return images.buildImageById(
          image.id!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 120,
          errorWidget: _buildErrorWidget(),
        );
      }
      // Fallback if no ImageService found: do NOT render /api/Images/* via network
      return _buildErrorWidget();
    } else {
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.error_outline, color: Colors.grey, size: 32),
      ),
    );
  }

  Widget _buildAddImageButton() {
    if (_images.length < widget.maxImages) {
      return GestureDetector(
        onTap: _pickImages,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: Colors.grey[400]!,
              style: BorderStyle.solid,
              width: 2,
            ),
            color: Colors.grey[50],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 32,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 8),
              Text(
                'Add Images',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Images grid
        if (_images.isNotEmpty || _images.length < widget.maxImages)
          SizedBox(
            height: 140,
            child:
                widget.allowReordering
                    ? ReorderableListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          _images.length +
                          (_images.length < widget.maxImages ? 1 : 0),
                      onReorder: _reorderImages,
                      itemBuilder: (context, index) {
                        if (index == _images.length) {
                          return Container(
                            key: const ValueKey('add_button'),
                            child: _buildAddImageButton(),
                          );
                        }
                        return Container(
                          key: ValueKey(
                            'image_${_images[index].id ?? index}_$index',
                          ),
                          child: _buildImageTile(_images[index], index),
                        );
                      },
                    )
                    : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          _images.length +
                          (_images.length < widget.maxImages ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _images.length) {
                          return Container(
                            key: const ValueKey('add_image_button'),
                            child: _buildAddImageButton(),
                          );
                        }
                        return Container(
                          key: ValueKey('image_${_images[index].id ?? index}'),
                          child: _buildImageTile(_images[index], index),
                        );
                      },
                    ),
          ),

        // Empty state
        if (_images.isEmpty)
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.grey[50],
            ),
            child: InkWell(
              onTap: _pickImages,
              borderRadius: BorderRadius.circular(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.emptyStateText,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

        // Instructions
        const SizedBox(height: 8),
        Text(
          widget.allowCoverSelection
              ? 'Tip: Click the star icon to set a cover image. Drag to reorder.'
              : 'Click "Add Images" or drag images here.',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}
