import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/models/user.dart';
import 'package:e_rents_mobile/feature/profile/providers/user_detail_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    final user = context.read<UserDetailProvider>().user;

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

  Future<void> _saveDetails() async {
    if (_formKey.currentState!.validate()) {
      final userProvider = context.read<UserDetailProvider>();
      final currentUser = userProvider.user;

      if (currentUser != null) {
        final updatedUser = User(
          userId: currentUser.userId,
          username: currentUser.username,
          email: _emailController.text,
          firstName: _nameController.text,
          lastName: _lastNameController.text,
          phoneNumber: _phoneController.text,
          address: currentUser.address,
          dateOfBirth: currentUser.dateOfBirth,
          role: currentUser.role,
          token: currentUser.token,
        );

        try {
          await userProvider.updateCurrentUserProfile(updatedUser);

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
                  content: Text(
                      userProvider.errorMessage ?? 'Failed to update profile')),
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

    return Consumer<UserDetailProvider>(
      builder: (context, userProvider, _) {
        final isLoading = userProvider.isLoading;

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
                          ),
                          keyboardType: TextInputType.emailAddress,
                          readOnly: true, // Email shouldn't be editable
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
                        TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(),
                          ),
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
