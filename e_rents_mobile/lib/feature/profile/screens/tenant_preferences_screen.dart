import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/models/tenant_preference_model.dart';
import 'package:e_rents_mobile/core/models/user.dart';
import 'package:e_rents_mobile/feature/profile/providers/user_detail_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TenantPreferencesScreen extends StatefulWidget {
  const TenantPreferencesScreen({super.key});

  @override
  State<TenantPreferencesScreen> createState() =>
      _TenantPreferencesScreenState();
}

class _TenantPreferencesScreenState extends State<TenantPreferencesScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  late TextEditingController _cityController;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late TextEditingController _amenitiesController;
  late TextEditingController _descriptionController;

  DateTime? _moveInStartDate;
  DateTime? _moveInEndDate;

  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserDetailProvider>();
    final preferences = userProvider.tenantPreference;

    _cityController = TextEditingController(text: preferences?.city ?? '');
    _minPriceController =
        TextEditingController(text: preferences?.minPrice?.toString() ?? '');
    _maxPriceController =
        TextEditingController(text: preferences?.maxPrice?.toString() ?? '');
    _amenitiesController =
        TextEditingController(text: preferences?.amenities?.join(', ') ?? '');
    _descriptionController =
        TextEditingController(text: preferences?.description ?? '');

    _moveInStartDate = preferences?.moveInStartDate;
    _moveInEndDate = preferences?.moveInEndDate;
    _isPublic = preferences?.isPublic ?? false;
  }

  @override
  void dispose() {
    _cityController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _amenitiesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          (isStartDate ? _moveInStartDate : _moveInEndDate) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(
          days: 30)), // Allow selecting past month for flexibility
      lastDate: DateTime.now().add(const Duration(
          days: 365 * 2)), // Allow selecting up to 2 years in future
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _moveInStartDate = picked;
          // Ensure end date is not before start date
          if (_moveInEndDate != null && _moveInEndDate!.isBefore(picked)) {
            _moveInEndDate = null;
          }
        } else {
          _moveInEndDate = picked;
        }
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final userProvider = context.read<UserDetailProvider>();
      final User? currentUser = userProvider.user;

      if (currentUser == null || currentUser.userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User not found. Cannot save preferences.')),
        );
        return;
      }

      final preferences = TenantPreferenceModel(
        id: userProvider.tenantPreference?.id, // Preserve existing ID if any
        userId: currentUser.userId!.toString(), // Ensure userId is a string
        city: _cityController.text.trim(),
        minPrice: double.tryParse(_minPriceController.text.trim()),
        maxPrice: double.tryParse(_maxPriceController.text.trim()),
        moveInStartDate: _moveInStartDate,
        moveInEndDate: _moveInEndDate,
        amenities: _amenitiesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        description: _descriptionController.text.trim(),
        isPublic: _isPublic,
      );

      final success = await userProvider.updateTenantPreferences(preferences);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Preferences saved successfully!'
                : 'Failed to save preferences.'),
          ),
        );
        if (success) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accommodation Preferences'),
      ),
      body: Consumer<UserDetailProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading &&
              userProvider.tenantPreference == null &&
              userProvider.user == null) {
            // Initial loading state for both user and preferences
            return const Center(child: CircularProgressIndicator());
          }
          // Initialize controllers and dates here if preferences were loaded after initState
          // This ensures that if data comes after screen is built, it gets populated.
          // However, with current UserProvider logic, initUser fetches prefs,
          // so they should be available via context.read in initState.
          // If direct navigation to this screen without ProfileScreen pre-loading is possible,
          // then a loading check for tenantPreference specifically might be needed here.

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
                    controller: _cityController,
                    decoration:
                        const InputDecoration(labelText: 'Preferred City/Area'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a city or area' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minPriceController,
                          decoration: const InputDecoration(
                              labelText: 'Min Budget (/month)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                            controller: _maxPriceController,
                            decoration: const InputDecoration(
                                labelText: 'Max Budget (/month)'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final minPrice =
                                    double.tryParse(_minPriceController.text);
                                final maxPrice = double.tryParse(value);
                                if (minPrice != null &&
                                    maxPrice != null &&
                                    maxPrice < minPrice) {
                                  return 'Max budget cannot be less than min budget';
                                }
                              }
                              return null;
                            }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                                labelText: 'Move-in Start Date'),
                            child: Text(_moveInStartDate != null
                                ? DateFormat.yMMMd().format(_moveInStartDate!)
                                : 'Select Date'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                                labelText: 'Move-in End Date (Optional)'),
                            child: Text(_moveInEndDate != null
                                ? DateFormat.yMMMd().format(_moveInEndDate!)
                                : 'Select Date'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amenitiesController,
                    decoration: const InputDecoration(
                      labelText: 'Key Amenities',
                      hintText: 'e.g., Parking, Pet-friendly, Balcony',
                      helperText: 'Enter amenities separated by commas',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description / About You',
                      hintText:
                          'Tell landlords a bit about what you are looking for or about yourself.',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Make these preferences public?'),
                    subtitle: const Text(
                        'If public, landlords may see your preferences and contact you.'),
                    value: _isPublic,
                    onChanged: (bool value) {
                      setState(() {
                        _isPublic = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: userProvider.isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        padding: const EdgeInsets.symmetric(vertical: 16.0)),
                    child: userProvider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Preferences'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
