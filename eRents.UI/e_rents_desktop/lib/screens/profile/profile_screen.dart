import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/widgets/custom_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _companyController;
  late final TextEditingController _addressController;
  late final TabController _tabController;
  bool _isEditing = false;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _maintenanceAlerts = true;
  bool _rentalAlerts = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _nameController = TextEditingController(text: 'John Doe');
    _emailController = TextEditingController(text: 'john.doe@example.com');
    _phoneController = TextEditingController(text: '+1 234 567 8900');
    _companyController = TextEditingController(
      text: 'Property Management Inc.',
    );
    _addressController = TextEditingController(
      text: '123 Business St, Suite 100',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: 'Profile',
      currentPath: '/profile',
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.person), text: 'Personal Info'),
                Tab(icon: Icon(Icons.settings), text: 'Account'),
                Tab(icon: Icon(Icons.security), text: 'Security'),
                Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
                Tab(icon: Icon(Icons.history), text: 'Activity'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildPersonalInfo(),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildAccountSettings(),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildSecuritySettings(),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildNotificationSettings(),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildActivityLog(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Stack(
            children: [
              CustomAvatar(
                imageUrl: 'assets/images/user-image.png',
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
                      // TODO: Implement image picker
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
                                      // TODO: Implement gallery picker
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.camera),
                                    title: const Text('Take a Photo'),
                                    onTap: () {
                                      // TODO: Implement camera picker
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
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
                  'John Doe',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Property Manager',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isEditing = !_isEditing;
                        });
                      },
                      icon: Icon(_isEditing ? Icons.save : Icons.edit),
                      label: Text(_isEditing ? 'Save Changes' : 'Edit Profile'),
                    ),
                    const SizedBox(width: 16),
                    if (_isEditing)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                          });
                        },
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

  Widget _buildPersonalInfo() {
    return _buildSection(
      title: 'Personal Information',
      icon: Icons.person,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _companyController,
              label: 'Company',
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressController,
              label: 'Address',
              enabled: _isEditing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettings() {
    return _buildSection(
      title: 'Account Settings',
      icon: Icons.settings,
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English',
            onTap: () {},
          ),
          const Divider(),
          _buildSettingTile(
            icon: Icons.access_time,
            title: 'Time Zone',
            subtitle: 'UTC-05:00 (Eastern Time)',
            onTap: () {},
          ),
          const Divider(),
          _buildSettingTile(
            icon: Icons.currency_exchange,
            title: 'Currency',
            subtitle: 'USD (\$)',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return _buildSection(
      title: 'Security',
      icon: Icons.security,
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.lock,
            title: 'Change Password',
            subtitle: 'Last changed 3 months ago',
            onTap: () {},
          ),
          const Divider(),
          _buildSettingTile(
            icon: Icons.phone_android,
            title: 'Two-Factor Authentication',
            subtitle: 'Not enabled',
            onTap: () {},
          ),
          const Divider(),
          _buildSettingTile(
            icon: Icons.devices,
            title: 'Connected Devices',
            subtitle: '2 devices',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSection(
      title: 'Notifications',
      icon: Icons.notifications,
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive updates via email'),
            value: _emailNotifications,
            onChanged: (value) {
              setState(() {
                _emailNotifications = value;
              });
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('SMS Notifications'),
            subtitle: const Text('Receive updates via SMS'),
            value: _smsNotifications,
            onChanged: (value) {
              setState(() {
                _smsNotifications = value;
              });
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Maintenance Alerts'),
            subtitle: const Text('Get notified about maintenance requests'),
            value: _maintenanceAlerts,
            onChanged: (value) {
              setState(() {
                _maintenanceAlerts = value;
              });
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Rental Alerts'),
            subtitle: const Text('Get notified about rental updates'),
            value: _rentalAlerts,
            onChanged: (value) {
              setState(() {
                _rentalAlerts = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLog() {
    return _buildSection(
      title: 'Recent Activity',
      icon: Icons.history,
      child: Column(
        children: [
          _buildActivityItem(
            icon: Icons.edit,
            title: 'Updated Property Details',
            subtitle: 'Luxury Villa - 123 Main St',
            time: '2 hours ago',
          ),
          const Divider(),
          _buildActivityItem(
            icon: Icons.add,
            title: 'Added New Property',
            subtitle: 'Modern Apartment - 456 Park Ave',
            time: '1 day ago',
          ),
          const Divider(),
          _buildActivityItem(
            icon: Icons.assignment,
            title: 'Created Maintenance Request',
            subtitle: 'Plumbing Issue - 789 Oak St',
            time: '2 days ago',
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: Theme.of(context).cardTheme.elevation,
      shape: Theme.of(context).cardTheme.shape,
      color: Theme.of(context).cardTheme.color,
      clipBehavior: Clip.antiAlias,

      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool enabled,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(
        time,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
      ),
    );
  }
}
