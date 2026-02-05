import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_form_provider.dart';

/// Atomic widget for property basic information (name, description).
/// Uses Selector for granular rebuilds on specific state changes.
class BasicInfoSection extends StatefulWidget {
  const BasicInfoSection({super.key});

  @override
  State<BasicInfoSection> createState() => _BasicInfoSectionState();
}

class _BasicInfoSectionState extends State<BasicInfoSection> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final provider = context.read<PropertyFormProvider>();
      _nameController.text = provider.state.name;
      _descriptionController.text = provider.state.description;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Basic Information', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        
        // Name field with error display
        Selector<PropertyFormProvider, String?>(
          selector: (_, p) => p.getFieldError('name'),
          builder: (context, error, _) {
            return TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Property Name *',
                border: const OutlineInputBorder(),
                errorText: error,
              ),
              onChanged: (value) {
                context.read<PropertyFormProvider>().updateName(value);
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Property name is required';
                }
                return null;
              },
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        // Description field
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          onChanged: (value) {
            context.read<PropertyFormProvider>().updateDescription(value);
          },
        ),
      ],
    );
  }
}
