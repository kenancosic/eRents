import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/places_autocomplete_field.dart';
import 'package:e_rents_mobile/core/services/google_places_service.dart';
import 'package:e_rents_mobile/features/profile/providers/user_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_mobile/core/models/address.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _zipCodeController;
  
  PlaceDetails? _selectedPlaceDetails;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProfileProvider>().user;

    _nameController = TextEditingController(text: user?.name ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _addressController =
        TextEditingController(text: user?.address?.streetLine1 ?? '');
    _cityController = TextEditingController(text: user?.address?.city ?? '');
    _zipCodeController =
        TextEditingController(text: user?.address?.postalCode ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  // Callback method for handling place selection from Google Places autocomplete
  void _onPlaceSelected(PlaceDetails? placeDetails) {
    setState(() {
      _selectedPlaceDetails = placeDetails;
    });
    
    if (placeDetails != null) {
      // Update city controller with the best available city name
      final cityName = placeDetails.bestCityName ?? placeDetails.city ?? '';
      _cityController.text = cityName;
      
      // Optionally update other address fields if needed
      // For now, we're only handling the city field
    }
  }

  Future<void> _saveDetails() async {
    if (_formKey.currentState!.validate()) {
      final userProfileProvider = context.read<UserProfileProvider>();
      final currentUser = userProfileProvider.user;

      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          firstName: _nameController.text,
          lastName: _lastNameController.text,
          phoneNumber: _phoneController.text,
          address: currentUser.address?.copyWith(
                streetLine1: _addressController.text,
                city: _cityController.text,
                postalCode: _zipCodeController.text,
              ) ??
              Address( // Create new address if null
                streetLine1: _addressController.text,
                city: _cityController.text,
                postalCode: _zipCodeController.text,
              ),
        );

        try {
          await userProfileProvider.updateUserProfile(updatedUser);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
            context.pop();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(userProfileProvider.errorMessage.isNotEmpty
                      ? userProfileProvider.errorMessage
                      : 'Failed to update profile')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBar = CustomAppBar(
      title: 'Personal Details',
      showBackButton: true,
    );

    return Consumer<UserProfileProvider>(
      builder: (context, userProfileProvider, _) {
        final isLoading = userProfileProvider.isLoading;

        return BaseScreen(
          appBar: appBar,
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your first name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your last name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            helperText: 'Changing email will require re-login',
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        PlacesAutocompleteField(
                          controller: _cityController,
                          hintText: 'City',
                          searchType: '(cities)', // Restrict search to cities only
                          onPlaceSelected: _onPlaceSelected,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _zipCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Zip Code',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          label: 'Save Changes',
                          icon: Icons.save,
                          isLoading: isLoading,
                          width: ButtonWidth.expanded,
                          onPressed: isLoading ? () {} : _saveDetails,
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
