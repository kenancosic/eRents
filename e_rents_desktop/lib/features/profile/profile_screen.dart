import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:e_rents_desktop/features/profile/providers/profile_provider.dart';
import 'package:e_rents_desktop/features/profile/providers/stripe_connect_provider.dart';
import 'package:e_rents_desktop/features/profile/models/connect_account_status.dart';
import 'package:e_rents_desktop/features/profile/widgets/profile_header_widget.dart';
import 'package:e_rents_desktop/features/profile/widgets/personal_info_form_widget.dart';
import 'package:e_rents_desktop/features/profile/widgets/change_password_widget.dart';
import 'package:e_rents_desktop/features/profile/widgets/stripe_connect_not_linked.dart';
import 'package:e_rents_desktop/features/profile/widgets/stripe_connect_active.dart';
import 'package:e_rents_desktop/features/profile/widgets/stripe_connect_pending.dart';
import 'package:e_rents_desktop/widgets/common/section_card.dart';
import 'package:e_rents_desktop/utils/date_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // STRIPE DISABLED: See docs/STRIPE_INTEGRATION_DISABLED.md
    // Load Stripe Connect account status when profile screen opens
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final stripeProvider = context.read<StripeConnectProvider>();
    //   stripeProvider.loadAccountStatus();
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final user = profileProvider.currentUser;

        if (profileProvider.isLoading && user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (profileProvider.error != null && user == null) {
          return Center(child: Text('Error: ${profileProvider.error}'));
        }

        if (user == null) {
          return const Center(child: Text('No user data found.'));
        }

        return const _ProfileScreenContent();
      },
    );
  }
}

class _ProfileScreenContent extends StatelessWidget {
  const _ProfileScreenContent();

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final isEditing = profileProvider.isEditing;

    final personalInfoFormKey = GlobalKey<FormState>();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Section (simplified - no image upload logic tied to provider)
            ProfileHeaderWidget(
              onImageUploaded: (path) async {
                // Image upload functionality simplified: placeholder or handled externally
                // The widget itself might provide a pick, but actual upload is not in provider
                // For academic submission, this can be a dummy function or removed.
                // Or you can add it to the profile provider if it uses multipart
                // For now, no action.
              },
            ),

            const SizedBox(height: 32),

            // Main Content
            LayoutBuilder(
              builder: (context, constraints) {
                // Simplified layout for all screen widths
                return Column(
                  children: [
                    _buildPersonalInfoCard(
                      context,
                      isEditing,
                      personalInfoFormKey,
                    ),
                    const SizedBox(height: 24),
                    SectionCard(
                      title: 'Security',
                      titleIcon: Icons.lock_outline,
                      child: ChangePasswordWidget(isEditing: isEditing),
                    ),
                    const SizedBox(height: 24),
                    // STRIPE DISABLED: See docs/STRIPE_INTEGRATION_DISABLED.md
                    // _buildStripeConnectSection(context),
                    // const SizedBox(height: 24),
                    _buildAccountSummaryCard(context),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Action Buttons
            if (isEditing)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: profileProvider.toggleEditing,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Consumer<ProfileProvider>(
                      builder: (context, provider, child) {
                        return ElevatedButton(
                          onPressed: provider.isLoading // Using general isLoading
                              ? null
                              : () async {
                                  if (personalInfoFormKey.currentState?.validate() ?? false) {
                                    final success = await provider.saveChanges();
                                    if (context.mounted) {
                                      if (success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Profile updated successfully!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(provider.error ?? 'Failed to update profile.'), // Using general error
                                            backgroundColor: Theme.of(context).colorScheme.error,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: provider.isLoading // Using general isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Save Changes'),
                        );
                      },
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Logout Button
            Center(
              child: SizedBox(
                width: 200,
                child: OutlinedButton(
                  onPressed: () async {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    await authProvider.logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element - Stripe disabled, kept for re-enabling later
  Widget _buildStripeConnectSection(BuildContext context) {
    return SectionCard(
      title: 'Payment & Payouts',
      titleIcon: Icons.account_balance_wallet_outlined,
      child: Consumer<StripeConnectProvider>(
        builder: (context, stripeProvider, child) {
          if (stripeProvider.isLoading && stripeProvider.accountStatus == null) {
            return const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (stripeProvider.hasError && stripeProvider.accountStatus == null) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    'Error loading Stripe account status',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(stripeProvider.error ?? 'Unknown error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => stripeProvider.loadAccountStatus(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final accountStatus = stripeProvider.accountStatus;

          if (accountStatus == null || !stripeProvider.hasAccount) {
            return StripeConnectNotLinked(
              onConnect: () => _connectStripeAccount(context),
              isLoading: stripeProvider.isLoading,
            );
          }

          switch (accountStatus.state) {
            case ConnectAccountState.active:
              return StripeConnectActive(
                status: accountStatus,
                onViewDashboard: () => _openStripeDashboard(context),
                onDisconnect: () => _disconnectStripeAccount(context),
                isLoading: stripeProvider.isLoading,
              );
            case ConnectAccountState.pending:
            case ConnectAccountState.inactive:
            default:
              return StripeConnectPending(
                status: accountStatus,
                onCompleteSetup: () => _resumeOnboarding(context),
                isLoading: stripeProvider.isLoading,
              );
          }
        },
      ),
    );
  }

  Future<void> _connectStripeAccount(BuildContext context) async {
    final stripeProvider = context.read<StripeConnectProvider>();
    final refreshUrl = '${Uri.base}?setup=failed';
    final returnUrl = '${Uri.base}?setup=success';
    
    final onboardingUrl = await stripeProvider.createOnboardingLink(
      refreshUrl: refreshUrl,
      returnUrl: returnUrl,
    );
    
    if (onboardingUrl == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(stripeProvider.error ?? 'Failed to create onboarding link'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    final uri = Uri.parse(onboardingUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Complete Setup in Browser'),
            content: const Text(
              'Please complete the Stripe Connect setup in your browser. '
              'Return here when finished and your status will update automatically.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        
        Future.delayed(const Duration(seconds: 10), () {
          if (context.mounted) {
            stripeProvider.refreshAfterOnboarding();
          }
        });
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open browser'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resumeOnboarding(BuildContext context) async {
    await _connectStripeAccount(context);
  }

  Future<void> _openStripeDashboard(BuildContext context) async {
    final stripeProvider = context.read<StripeConnectProvider>();
    final dashboardUrl = await stripeProvider.getDashboardLink();
    
    if (dashboardUrl == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(stripeProvider.error ?? 'Failed to get dashboard link'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    final uri = Uri.parse(dashboardUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open dashboard'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnectStripeAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Stripe Account?'),
        content: const Text(
          'Are you sure you want to disconnect your Stripe account? '
          'You will no longer be able to receive payments until you reconnect.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    final stripeProvider = context.read<StripeConnectProvider>();
    final success = await stripeProvider.disconnectAccount();
    
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stripe account disconnected successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(stripeProvider.error ?? 'Failed to disconnect account'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPersonalInfoCard(
    BuildContext context,
    bool isEditing,
    GlobalKey<FormState> personalInfoFormKey,
  ) {
    return SectionCard(
      title: 'Personal Information',
      titleIcon: Icons.person,
      child: PersonalInfoFormWidget(
        isEditing: isEditing,
        formKey: personalInfoFormKey,
      ),
    );
  }

  Widget _buildAccountSummaryCard(BuildContext context) {
    final user = context.watch<ProfileProvider>().currentUser;
    if (user == null) {
      return const Center(child: Text('Profile information not available'));
    }

    return SectionCard(
      title: 'Account Summary',
      titleIcon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryItem(
            context,
            'Account Type',
            user.role.toString().split('.').last.toUpperCase(),
            Icons.account_circle,
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            context,
            'Member Since',
            AppDateUtils.formatPrimary(user.createdAt),
            Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          // STRIPE DISABLED: Payment integration disabled for academic submission
          // See docs/stripe/STRIPE_INTEGRATION_DISABLED.md
          _buildSummaryItem(
            context,
            'Profile Status',
            'Active',
            Icons.check_circle,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
