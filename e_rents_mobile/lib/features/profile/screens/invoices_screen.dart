import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/features/profile/providers/invoices_provider.dart';
import 'package:e_rents_mobile/core/models/payment.dart' as model;
import 'package:e_rents_mobile/core/providers/current_user_provider.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:e_rents_mobile/core/utils/date_extensions.dart';
// Stripe payment integration for monthly invoices
// Note: 'hide Card' prevents conflict with Flutter's Card widget

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentUserProvider = context.read<CurrentUserProvider>();
      context.read<InvoicesProvider>().loadPending(currentUserProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appBar = const CustomAppBar(
      title: 'Invoices',
      showBackButton: true,
    );

    return BaseScreen(
      appBar: appBar,
      body: Consumer<InvoicesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final hasError = provider.hasError;
          final errorMessage = provider.errorMessage;
          final items = provider.filteredInvoices;

          return Column(
            children: [
              // Filter chips
              _buildFilterChips(context, provider),
              // Content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: hasError && errorMessage.isNotEmpty
                      ? _buildError(context, errorMessage)
                      : items.isEmpty
                          ? _buildEmpty(context, provider.filter)
                          : RefreshIndicator(
                              onRefresh: () => provider.loadInvoices(context.read<CurrentUserProvider>()),
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: items.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final p = items[index];
                                  final isPaid = p.paymentStatus == 'Completed' || p.paymentStatus == 'Paid';
                                  final apiService = context.read<ApiService>();
                                  return _InvoiceTile(
                                    payment: p,
                                    isPaying: provider.isPaying,
                                    isPaid: isPaid,
                                    apiService: apiService,
                                    onPayNow: isPaid ? null : () => _processInvoicePayment(context, provider, p),
                                    onShowDetails: () => _showPaymentDetails(context, p),
                                    onSendEmail: () => _sendInvoiceEmail(context, provider, p),
                                    onTap: () => _showPaymentDetails(context, p),
                                  );
                                },
                              ),
                            ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, InvoicesProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _filterChip(context, provider, InvoiceFilter.pending, 'Pending'),
          const SizedBox(width: 8),
          _filterChip(context, provider, InvoiceFilter.paid, 'Paid'),
          const SizedBox(width: 8),
          _filterChip(context, provider, InvoiceFilter.all, 'All'),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, InvoicesProvider provider, InvoiceFilter filter, String label) {
    final isSelected = provider.filter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => provider.setFilter(filter),
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, InvoiceFilter filter) {
    final (icon, title, subtitle) = switch (filter) {
      InvoiceFilter.pending => (
        Icons.receipt_long_outlined,
        'No pending invoices',
        'You have no unpaid subscription invoices at the moment.'
      ),
      InvoiceFilter.paid => (
        Icons.check_circle_outline,
        'No paid invoices',
        'You have no paid subscription invoices yet.'
      ),
      InvoiceFilter.all => (
        Icons.receipt_long_outlined,
        'No invoices',
        'You have no subscription invoices yet.'
      ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.read<InvoicesProvider>().loadInvoices(context.read<CurrentUserProvider>()),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendInvoiceEmail(BuildContext context, InvoicesProvider provider, model.Payment p) async {
    // Save ScaffoldMessenger reference before async gap to avoid widget deactivation error
    final messenger = ScaffoldMessenger.of(context);
    final success = await provider.sendInvoicePdfToEmail(p.paymentId);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(success ? 'Invoice sent to your email!' : 'Failed to send invoice'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  String _formatDate(DateTime? dt) => dt.toApiDateOrEmpty();

  void _showPaymentDetails(BuildContext context, model.Payment p) {
    final property = p.propertyName ?? (p.propertyId != null ? 'Property #${p.propertyId}' : 'Property');
    final period = (p.periodStart != null && p.periodEnd != null)
        ? '${p.periodStart!.toApiDate()} → ${p.periodEnd!.toApiDate()}'
        : 'Unavailable';

    final amount = '${(p.currency ?? 'USD').toUpperCase()} ${p.amount.toStringAsFixed(2)}';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Invoice details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv('Invoice #', '#${p.paymentId}'),
            _kv('Property', property),
            _kv('Amount', amount),
            _kv('Period', period),
            if (p.createdAt != null) _kv('Created', _formatDate(p.createdAt)),
            if ((p.paymentStatus ?? '').isNotEmpty) _kv('Status', p.paymentStatus!),
          ],
        ),
        actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
        ],
      ),
    );
  }

  // Process invoice payment with Stripe
  Future<void> _processInvoicePayment(
      BuildContext context, InvoicesProvider provider, model.Payment payment) async {
    
    // Capture references before async gaps to avoid "deactivated widget" errors
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    final currentUserProvider = context.read<CurrentUserProvider>();
    
    // Track if we have a dialog open to prevent double-pops
    bool dialogOpen = false;
    
    // Helper to safely close dialog using captured navigator
    void closeDialog() {
      if (dialogOpen) {
        navigator.pop();
        dialogOpen = false;
      }
    }
    
    // Helper to show loading dialog
    void showLoadingDialog(String message) {
      if (!mounted) return;
      dialogOpen = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      );
    }
    
    try {
      // Step 1: Create Stripe payment intent on backend
      showLoadingDialog('Preparing payment...');

      Map<String, String> result;
      try {
        result = await provider.createStripePaymentIntent(payment);
      } catch (e) {
        closeDialog();
        rethrow;
      }
      final clientSecret = result['clientSecret']!;
      
      if (!mounted) return;
      closeDialog();
      
      // Step 2: Initialize payment sheet with client secret
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'eRents',
          paymentIntentClientSecret: clientSecret,
          customerEphemeralKeySecret: null,
          customerId: null,
          style: ThemeMode.system,
          // Pre-fill billing details for testing
          billingDetails: const BillingDetails(
            name: 'Test User',
            email: 'test@erents.com',
            phone: '+12345678901',
            address: Address(
              city: 'New York',
              country: 'US',
              line1: '123 Test Street',
              line2: 'Apt 1',
              postalCode: '10001',
              state: 'NY',
            ),
          ),
          billingDetailsCollectionConfiguration: const BillingDetailsCollectionConfiguration(
            email: CollectionMode.always,
            phone: CollectionMode.always,
            name: CollectionMode.always,
            address: AddressCollectionMode.full,
          ),
        ),
      );
      
      // Step 3: Present payment sheet to user
      // This will throw StripeException if cancelled or failed
      await Stripe.instance.presentPaymentSheet();
      
      // Step 4: Stripe SDK completed - now verify with backend
      // The backend fetches PaymentIntent status directly from Stripe API (not waiting for webhook)
      if (!mounted) return;
      
      // Show confirming dialog
      showLoadingDialog('Verifying payment...');
      
      // Verify payment with backend - this calls Stripe API directly and updates our database
      final confirmResult = await provider.confirmStripePayment(payment.paymentId);
      
      // Reload invoices to show updated status
      if (mounted) {
        await provider.loadInvoices(currentUserProvider);
      }
      
      closeDialog();
      
      if (confirmResult['success'] == true) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('✓ Payment successful! Invoice paid.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Payment not yet confirmed - show status message
        final status = confirmResult['status'] ?? 'unknown';
        final message = confirmResult['message'] ?? 'Payment verification failed';
        
        messenger.showSnackBar(
          SnackBar(
            content: Text(status == 'processing' 
                ? 'Payment is processing. It may take a few minutes to confirm.'
                : message),
            backgroundColor: status == 'processing' ? Colors.orange : Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
    } on StripeException catch (e) {
      closeDialog();
      
      // Handle specific Stripe errors
      String errorMessage = 'Payment failed';
      if (e.error.code == FailureCode.Canceled) {
        errorMessage = 'Payment cancelled';
      } else if (e.error.code == FailureCode.Failed) {
        errorMessage = 'Payment failed: ${e.error.message ?? "Unknown error"}';
      } else {
        errorMessage = 'Payment error: ${e.error.localizedMessage ?? e.error.message ?? "Unknown error"}';
      }
      
      messenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      closeDialog();
      
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to process payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Expanded(child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Expanded(child: Text(v, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final model.Payment payment;
  final bool isPaying;
  final bool isPaid;
  final ApiService apiService;
  final VoidCallback? onPayNow;
  final VoidCallback onShowDetails;
  final VoidCallback onSendEmail;
  final VoidCallback onTap;

  const _InvoiceTile({
    required this.payment,
    required this.isPaying,
    this.isPaid = false,
    required this.apiService,
    this.onPayNow,
    required this.onShowDetails,
    required this.onSendEmail,
    required this.onTap,
  });

  String _formatAmount(model.Payment p) {
    final cur = (p.currency ?? 'USD').toUpperCase();
    return '$cur ${p.amount.toStringAsFixed(2)}';
  }

  String _formatDisplayDate(DateTime? dt) {
    if (dt == null) return '';
    return dt.toShortDate(); // "Jan 23, 2026"
  }

  String _formatPeriod(model.Payment p) {
    if (p.periodStart != null && p.periodEnd != null) {
      return '${p.periodStart!.toShortDate()} - ${p.periodEnd!.toShortDate()}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final propertyName = payment.propertyName ?? 'Property #${payment.propertyId ?? "N/A"}';
    final period = _formatPeriod(payment);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property info row
              Row(
                children: [
                  // Property image placeholder or icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: payment.propertyImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              // Backend returns relative URL, make it absolute
                              apiService.makeAbsoluteUrl(payment.propertyImageUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.home_outlined,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.home_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          propertyName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Invoice #${payment.paymentId}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        if (period.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            period,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Amount and actions row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _formatAmount(payment),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isPaid ? Colors.green : Theme.of(context).colorScheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isPaid) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'PAID',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          isPaid ? 'Paid ${_formatDisplayDate(payment.datePaid ?? payment.createdAt)}' : 'Due ${_formatDisplayDate(payment.createdAt)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Email PDF button
                      IconButton(
                        onPressed: onSendEmail,
                        icon: const Icon(Icons.email_outlined, size: 20),
                        tooltip: 'Send invoice to email',
                      ),
                      TextButton(
                        onPressed: onShowDetails,
                        child: const Text('Details'),
                      ),
                      if (!isPaid) ...[
                        const SizedBox(width: 4),
                        ElevatedButton.icon(
                          onPressed: isPaying ? null : onPayNow,
                          icon: const Icon(Icons.payment, size: 18),
                          label: const Text('Pay'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
