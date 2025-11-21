import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/features/profile/providers/invoices_provider.dart';
import 'package:e_rents_mobile/core/models/payment.dart' as model;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
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
      context.read<InvoicesProvider>().loadPending();
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
          final items = provider.pending;

          Widget content;
          if (hasError && errorMessage.isNotEmpty) {
            content = _buildError(context, errorMessage);
          } else if (items.isEmpty) {
            content = _buildEmpty(context);
          } else {
            content = RefreshIndicator(
              onRefresh: () => provider.loadPending(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final p = items[index];
                  return _InvoiceTile(
                    payment: p,
                    isPaying: provider.isPaying,
                    onPayNow: () => _processInvoicePayment(context, provider, p),
                    onShowDetails: () => _showPaymentDetails(context, p),
                    onTap: () => _showPaymentDetails(context, p),
                  );
                },
              ),
            );
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: content,
          );
        },
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

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            const Text(
              'No pending invoices',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'You have no unpaid subscription invoices at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.read<InvoicesProvider>().loadPending(),
              icon: const Icon(Icons.refresh),
              label: const Text('Check again'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  void _showPaymentDetails(BuildContext context, model.Payment p) {
    final property = p.propertyName ?? (p.propertyId != null ? 'Property #${p.propertyId}' : 'Property');
    String period;
    if (p.periodStart != null && p.periodEnd != null) {
      final from = '${p.periodStart!.year.toString().padLeft(4, '0')}-${p.periodStart!.month.toString().padLeft(2, '0')}-${p.periodStart!.day.toString().padLeft(2, '0')}';
      final to = '${p.periodEnd!.year.toString().padLeft(4, '0')}-${p.periodEnd!.month.toString().padLeft(2, '0')}-${p.periodEnd!.day.toString().padLeft(2, '0')}';
      period = '$from → $to';
    } else {
      period = 'Unavailable';
    }

    final amount = '${(p.currency ?? 'USD').toUpperCase()} ${p.amount.toStringAsFixed(2)}';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
        ],
      ),
    );
  }

  // Process invoice payment with Stripe
  Future<void> _processInvoicePayment(
      BuildContext context, InvoicesProvider provider, model.Payment payment) async {
    
    try {
      // Step 1: Create Stripe payment intent on backend
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparing payment...'),
            ],
          ),
        ),
      );

      final result = await provider.createStripePaymentIntent(payment);
      final clientSecret = result['clientSecret']!;
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      
      // Step 2: Initialize payment sheet with client secret
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'eRents',
          paymentIntentClientSecret: clientSecret,
          customerEphemeralKeySecret: null, // Optional: for saved cards
          customerId: null, // Optional: for saved cards
          style: ThemeMode.system,
          billingDetailsCollectionConfiguration: const BillingDetailsCollectionConfiguration(
            email: CollectionMode.always,
            phone: CollectionMode.always,
          ),
        ),
      );
      
      // Step 3: Present payment sheet to user
      await Stripe.instance.presentPaymentSheet();
      
      // Step 4: Payment successful! (if no exception thrown)
      if (!mounted) return;
      
      // Wait for webhook to confirm payment
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Confirming payment...'),
            ],
          ),
        ),
      );
      
      // Give webhook time to process (in production, use polling or WebSocket)
      await Future.delayed(const Duration(seconds: 2));
      
      // Refresh invoices list
      await provider.confirmStripePayment();
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Close confirming dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Payment successful! Invoice paid.'),
          backgroundColor: Colors.green,
        ),
      );
      
    } on StripeException catch (e) {
      if (!mounted) return;
      // Close any open dialogs
      Navigator.of(context).popUntil((route) => route.isFirst);
      
      // Handle specific Stripe errors
      String errorMessage = 'Payment failed';
      if (e.error.code == FailureCode.Canceled) {
        errorMessage = 'Payment cancelled';
      } else if (e.error.code == FailureCode.Failed) {
        errorMessage = 'Payment failed: ${e.error.message ?? "Unknown error"}';
      } else {
        errorMessage = 'Payment error: ${e.error.localizedMessage ?? e.error.message ?? "Unknown error"}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Close any open dialogs
      Navigator.of(context).popUntil((route) => route.isFirst);
      
      ScaffoldMessenger.of(context).showSnackBar(
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
  final VoidCallback onPayNow;
  final VoidCallback onShowDetails;
  final VoidCallback onTap;

  const _InvoiceTile({
    required this.payment,
    required this.isPaying,
    required this.onPayNow,
    required this.onShowDetails,
    required this.onTap,
  });

  String _formatAmount(model.Payment p) {
    final cur = (p.currency ?? 'USD').toUpperCase();
    return '$cur ${p.amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: InkWell(
          onTap: onTap,
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.receipt_long_outlined, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoice #${payment.paymentId}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Created ${_formatDate(payment.createdAt)}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatAmount(payment),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: isPaying ? null : onPayNow,
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text('Pay now'),
                ),
                TextButton.icon(
                  onPressed: onShowDetails,
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Details'),
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
