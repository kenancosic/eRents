import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart' show PropertyProvider;
import 'package:e_rents_desktop/features/properties/providers/property_form_provider.dart';
import 'package:e_rents_desktop/features/properties/widgets/form/form_sections.dart';
import 'package:e_rents_desktop/services/image_service.dart';
import 'package:e_rents_desktop/services/api_service.dart';

/// Refactored Property Form Screen using clean architecture.
/// 
/// Key improvements over v1:
/// - Thin UI layer - delegates all business logic to PropertyFormProvider
/// - Atomic section widgets for modularity and testability
/// - Immutable form state via PropertyFormState
/// - Selector pattern for granular rebuilds
/// - No GlobalKey state access pattern
class PropertyFormScreenV2 extends StatelessWidget {
  final int? propertyId;

  const PropertyFormScreenV2({super.key, this.propertyId});

  bool get isEditMode => propertyId != null;

  @override
  Widget build(BuildContext context) {
    // Capture dependencies BEFORE creating the provider scope
    final apiService = context.read<ApiService>();
    
    return ChangeNotifierProvider(
      create: (context) {
        final provider = PropertyFormProvider(
          propertyProvider: context.read<PropertyProvider>(),
          imageService: context.read<ImageService>(),
        );
        
        // Initialize based on mode
        if (propertyId != null) {
          provider.initializeForEdit(propertyId!);
        } else {
          provider.initializeForCreate();
        }
        
        return provider;
      },
      child: _PropertyFormContent(
        isEditMode: isEditMode,
        apiService: apiService,
      ),
    );
  }
}

class _PropertyFormContent extends StatefulWidget {
  final bool isEditMode;
  final ApiService apiService;

  const _PropertyFormContent({
    required this.isEditMode,
    required this.apiService,
  });

  @override
  State<_PropertyFormContent> createState() => _PropertyFormContentState();
}

class _PropertyFormContentState extends State<_PropertyFormContent> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(widget.isEditMode ? 'Edit Property' : 'Add Property'),
      actions: [
        // Reset button
        TextButton(
          onPressed: () {
            context.read<PropertyFormProvider>().reset();
            _formKey.currentState?.reset();
          },
          child: const Text('Reset'),
        ),
        
        // Save button with loading state
        Selector<PropertyFormProvider, bool>(
          selector: (_, p) => p.isSubmitting,
          builder: (context, isSubmitting, _) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton(
                onPressed: isSubmitting ? null : () => _onSubmit(context),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        // Error banner
        Selector<PropertyFormProvider, String?>(
          selector: (_, p) => p.errorMessage,
          builder: (context, error, _) {
            if (error == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          error,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          context.read<PropertyFormProvider>().clearError();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        
        // Loading state for edit mode
        Selector<PropertyFormProvider, bool>(
          selector: (_, p) => p.isLoading,
          builder: (context, isLoading, child) {
            if (isLoading) {
              return const Expanded(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return child!;
          },
          child: Expanded(
            child: _FormContent(
              apiService: widget.apiService,
              formKey: _formKey,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onSubmit(BuildContext context) async {
    // Validate the form first
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final provider = context.read<PropertyFormProvider>();
    final success = await provider.submit();
    
    if (success && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }
}

/// The actual form content with all sections
class _FormContent extends StatelessWidget {
  final ApiService apiService;
  final GlobalKey<FormState> formKey;
  
  const _FormContent({required this.apiService, required this.formKey});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Basic Info Section
            const _SectionCard(child: BasicInfoSection()),
            const SizedBox(height: 24),
            
            // Pricing Section
            const _SectionCard(child: PricingSection()),
            const SizedBox(height: 24),
            
            // Address Section
            const _SectionCard(child: AddressSection()),
            const SizedBox(height: 24),
            
            // Status Section
            const _SectionCard(child: StatusSection()),
            const SizedBox(height: 24),
            
            // Amenities Section
            const _SectionCard(child: AmenitiesSection()),
            const SizedBox(height: 24),
            
            // Images Section
            _SectionCard(child: ImagesSection(apiService: apiService)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Card wrapper for form sections providing consistent styling
class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}
