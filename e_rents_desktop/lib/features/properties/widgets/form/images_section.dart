import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_form_provider.dart';
import 'package:e_rents_desktop/widgets/inputs/image_picker_input.dart' as img;
import 'package:e_rents_desktop/services/api_service.dart';

/// Atomic widget for property image management.
class ImagesSection extends StatelessWidget {
  final ApiService apiService;
  
  const ImagesSection({super.key, required this.apiService});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Images', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Add up to 20 images. First image or starred image will be the cover.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        
        Selector<PropertyFormProvider, List<img.ImageInfo>>(
          selector: (_, p) => p.state.images,
          builder: (context, images, _) {
            // Convert ImageInfo list to the format expected by ImagePickerInput
            final initialImages = images.map((i) => {
              'imageId': i.id,
              'fileName': i.fileName,
              'isCover': i.isCover,
              'url': i.url,
            }).toList();
            
            return img.ImagePickerInput(
              initialImages: initialImages,
              apiService: apiService,
              onChanged: (List<img.ImageInfo> imgs) {
                context.read<PropertyFormProvider>().updateImages(imgs);
              },
              allowCoverSelection: true,
              maxImages: 20,
            );
          },
        ),
      ],
    );
  }
}
