import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/models/tenant.dart';
import 'package:e_rents_desktop/features/rents/providers/rents_provider.dart';
import 'package:e_rents_desktop/features/chat/providers/chat_provider.dart';
import 'package:e_rents_desktop/router.dart';

/// Actions widget for monthly rental tenants
/// Shows contextual actions based on tenant status
class MonthlyTenantActions extends StatelessWidget {
  final Tenant tenant;
  final VoidCallback onRefresh;

  const MonthlyTenantActions({
    super.key,
    required this.tenant,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Always show the popup menu for all statuses
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'Actions',
          onSelected: (action) => _handleAction(context, action),
          itemBuilder: (context) => _buildMenuItems(),
        ),
        // Show quick action buttons for pending tenants
        if (tenant.tenantStatus == TenantStatus.inactive && tenant.propertyId != null) ...[
          const SizedBox(width: 4),
          _buildAcceptButton(context),
          const SizedBox(width: 4),
          _buildRejectButton(context),
        ],
      ],
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    final items = <PopupMenuEntry<String>>[];

    switch (tenant.tenantStatus) {
      case TenantStatus.active:
        items.addAll([
          const PopupMenuItem(
            value: 'view_lease',
            child: ListTile(
              leading: Icon(Icons.description, size: 20),
              title: Text('View Lease Details'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'send_invoice',
            child: ListTile(
              leading: Icon(Icons.receipt_long, size: 20),
              title: Text('Send Payment Request'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          const PopupMenuItem(
            value: 'payment_history',
            child: ListTile(
              leading: Icon(Icons.history, size: 20),
              title: Text('View Payment History'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'message',
            child: ListTile(
              leading: Icon(Icons.chat_bubble_outline, size: 20),
              title: Text('Message Tenant'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'extend_lease',
            child: ListTile(
              leading: Icon(Icons.update, size: 20),
              title: Text('Request Lease Extension'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          const PopupMenuItem(
            value: 'terminate',
            child: ListTile(
              leading: Icon(Icons.cancel, color: Colors.red, size: 20),
              title: Text('Terminate Lease'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        ]);
        break;

      case TenantStatus.inactive:
        items.addAll([
          const PopupMenuItem(
            value: 'view_application',
            child: ListTile(
              leading: Icon(Icons.person_search, size: 20),
              title: Text('View Application'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          const PopupMenuItem(
            value: 'message',
            child: ListTile(
              leading: Icon(Icons.chat_bubble_outline, size: 20),
              title: Text('Message Applicant'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          if (tenant.propertyId != null) ...[
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'accept',
              child: ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green, size: 20),
                title: Text('Accept Tenant'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'reject',
              child: ListTile(
                leading: Icon(Icons.cancel, color: Colors.red, size: 20),
                title: Text('Reject Tenant'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ]);
        break;

      case TenantStatus.evicted:
      case TenantStatus.leaseEnded:
        items.addAll([
          const PopupMenuItem(
            value: 'view_history',
            child: ListTile(
              leading: Icon(Icons.history, size: 20),
              title: Text('View Rental History'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          const PopupMenuItem(
            value: 'payment_history',
            child: ListTile(
              leading: Icon(Icons.receipt_long, size: 20),
              title: Text('View Payment History'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          if (tenant.tenantStatus == TenantStatus.leaseEnded) ...[
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 're_sign',
              child: ListTile(
                leading: Icon(Icons.autorenew, color: Colors.blue, size: 20),
                title: Text('Offer New Lease'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ]);
        break;
    }

    return items;
  }

  Widget _buildAcceptButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.check, size: 16),
      label: const Text('Accept'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: () => _handleAccept(context),
    );
  }

  Widget _buildRejectButton(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.close, size: 16),
      label: const Text('Reject'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: () => _handleReject(context),
    );
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'view_lease':
        _showLeaseDetails(context);
        break;
      case 'send_invoice':
        _showSendInvoiceDialog(context);
        break;
      case 'payment_history':
        _showPaymentHistory(context);
        break;
      case 'message':
        _openChat(context);
        break;
      case 'extend_lease':
        _showExtendLeaseDialog(context);
        break;
      case 'terminate':
        _showTerminateDialog(context);
        break;
      case 'accept':
        _handleAccept(context);
        break;
      case 'reject':
        _handleReject(context);
        break;
      case 'view_application':
      case 'view_history':
        _showTenantDetails(context);
        break;
      case 're_sign':
        _showReSignDialog(context);
        break;
    }
  }

  Future<void> _handleAccept(BuildContext context) async {
    if (tenant.propertyId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Tenant'),
        content: Text(
          'Accept ${tenant.fullName} as a tenant?\n\n'
          'This will also reject all other pending applications for this property.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = context.read<RentsProvider>();
      await provider.acceptTenantRequest(tenant.tenantId, tenant.propertyId!);
      onRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tenant.fullName} has been accepted as a tenant'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Tenant'),
        content: Text('Reject ${tenant.fullName}\'s application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = context.read<RentsProvider>();
      await provider.rejectTenantRequest(tenant.tenantId);
      onRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tenant.fullName}\'s application has been rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showLeaseDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.description, color: Colors.blue),
            const SizedBox(width: 8),
            Text('Lease Details - ${tenant.fullName}'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Property', tenant.propertyName),
              _buildDetailRow('Tenant', tenant.fullName),
              _buildDetailRow('Email', tenant.email),
              const Divider(),
              _buildDetailRow('Lease Period', tenant.leasePeriod),
              _buildDetailRow('Status', tenant.tenantStatus.displayName),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSendInvoiceDialog(BuildContext context) async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController(
      text: 'Monthly rent for ${tenant.propertyName}',
    );
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.blue),
              SizedBox(width: 8),
              Text('Send Payment Request'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  enabled: !isLoading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send),
              label: Text(isLoading ? 'Sending...' : 'Send Invoice'),
              onPressed: isLoading ? null : () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                setState(() => isLoading = true);

                try {
                  final provider = context.read<RentsProvider>();
                  
                  // Get subscription ID for this tenant
                  final subscriptionId = await provider.getSubscriptionIdForTenant(tenant.tenantId);
                  
                  if (subscriptionId == null) {
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('No active subscription found for ${tenant.fullName}'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                    return;
                  }

                  // Send invoice
                  final result = await provider.sendInvoice(
                    subscriptionId: subscriptionId,
                    amount: amount,
                    description: descriptionController.text.isNotEmpty 
                        ? descriptionController.text 
                        : null,
                  );

                  if (ctx.mounted) Navigator.of(ctx).pop();
                  
                  if (result != null && result['success'] == true) {
                    final emailSent = result['emailSent'] == true;
                    final notificationSent = result['notificationSent'] == true;
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Payment request sent to ${tenant.fullName}' +
                            (emailSent ? ' (email sent)' : '') +
                            (notificationSent ? ' (notification sent)' : ''),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    onRefresh();
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result?['message'] ?? 'Failed to send invoice'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPaymentHistory(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => _PaymentHistoryDialog(tenant: tenant),
    );
  }

  Future<void> _openChat(BuildContext context) async {
    final chatProvider = context.read<ChatProvider>();
    final success = await chatProvider.ensureContact(tenant.userId);
    if (success && context.mounted) {
      chatProvider.selectContact(tenant.userId);
      context.go(AppRoutes.chat);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start chat with tenant')),
      );
    }
  }

  void _showExtendLeaseDialog(BuildContext context) {
    int extensionMonths = 6;
    final messageController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.update, color: Colors.blue),
              SizedBox(width: 8),
              Text('Offer Lease Extension'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Offer lease extension to ${tenant.fullName}'),
                const SizedBox(height: 8),
                Text(
                  'An email notification will be sent to the tenant.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: extensionMonths,
                  decoration: const InputDecoration(
                    labelText: 'Extension Period',
                    border: OutlineInputBorder(),
                  ),
                  items: [3, 6, 12, 24].map((months) {
                    return DropdownMenuItem(
                      value: months,
                      child: Text('$months months'),
                    );
                  }).toList(),
                  onChanged: isLoading ? null : (value) => setState(() => extensionMonths = value ?? 6),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message to Tenant (optional)',
                    hintText: 'Add a personal message...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  enabled: !isLoading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send),
              label: Text(isLoading ? 'Sending...' : 'Send Offer'),
              onPressed: isLoading
                  ? null
                  : () async {
                      // Need to get bookingId from tenant
                      final provider = context.read<RentsProvider>();
                      final bookingId = await provider.getLatestBookingIdForTenantProperty(
                        tenant.userId,
                        tenant.propertyId ?? 0,
                      );

                      if (bookingId == null) {
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No active booking found for this tenant'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        final result = await provider.offerLeaseExtension(
                          bookingId: bookingId,
                          extendByMonths: extensionMonths,
                          message: messageController.text.isNotEmpty ? messageController.text : null,
                        );

                        if (ctx.mounted) Navigator.of(ctx).pop();

                        if (result != null && context.mounted) {
                          final emailSent = result['emailSent'] == true;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Lease extension offer sent to ${tenant.fullName}${emailSent ? ' (email sent)' : ''}',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          onRefresh();
                        }
                      } catch (e) {
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  void _showTerminateDialog(BuildContext context) {
    final reasonController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cancel, color: Colors.red),
              SizedBox(width: 8),
              Text('Terminate Lease'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to terminate the lease for ${tenant.fullName}?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This action cannot be undone. The tenant will be notified via email.',
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text(
                  'Note: Per the lease agreement, the tenant will be charged for one additional month.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Termination Reason',
                    hintText: 'Provide a reason for termination...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  enabled: !isLoading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cancel),
              label: Text(isLoading ? 'Terminating...' : 'Terminate Lease'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      // Need to get bookingId from tenant
                      final provider = context.read<RentsProvider>();
                      final bookingId = await provider.getLatestBookingIdForTenantProperty(
                        tenant.userId,
                        tenant.propertyId ?? 0,
                      );

                      if (bookingId == null) {
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No active booking found for this tenant'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        await provider.terminateLease(
                          bookingId: bookingId,
                          reason: reasonController.text.isNotEmpty ? reasonController.text : null,
                        );

                        if (ctx.mounted) Navigator.of(ctx).pop();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lease terminated for ${tenant.fullName}. Email notification sent.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          onRefresh();
                        }
                      } catch (e) {
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  void _showTenantDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person, color: Colors.blue),
            const SizedBox(width: 8),
            Text(tenant.fullName),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email', tenant.email),
              _buildDetailRow('Property', tenant.propertyName),
              _buildDetailRow('Status', tenant.tenantStatus.displayName),
              if (tenant.leaseStartDate != null || tenant.leaseEndDate != null)
                _buildDetailRow('Lease Period', tenant.leasePeriod),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showReSignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.autorenew, color: Colors.blue),
            SizedBox(width: 8),
            Text('Offer New Lease'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Offer a new lease to ${tenant.fullName}?'),
              const SizedBox(height: 16),
              const Text(
                'This will send a lease offer to the tenant for their previous property.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.send),
            label: const Text('Send Offer'),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Lease offer sent to ${tenant.fullName}'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Dialog widget to display payment history for a tenant
class _PaymentHistoryDialog extends StatefulWidget {
  final Tenant tenant;

  const _PaymentHistoryDialog({required this.tenant});

  @override
  State<_PaymentHistoryDialog> createState() => _PaymentHistoryDialogState();
}

class _PaymentHistoryDialogState extends State<_PaymentHistoryDialog> {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    try {
      final provider = context.read<RentsProvider>();
      final payments = await provider.getTenantPaymentHistory(widget.tenant.tenantId);
      if (mounted) {
        setState(() {
          _payments = payments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.history, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Payment History - ${widget.tenant.fullName}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 400,
        child: _buildContent(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Error loading payment history', style: TextStyle(color: Colors.red[600])),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      );
    }

    if (_payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No payment history found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _payments.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final payment = _payments[index];
        return _PaymentHistoryItem(payment: payment);
      },
    );
  }
}

class _PaymentHistoryItem extends StatelessWidget {
  final Map<String, dynamic> payment;

  const _PaymentHistoryItem({required this.payment});

  @override
  Widget build(BuildContext context) {
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final currency = payment['currency'] as String? ?? 'USD';
    final status = payment['paymentStatus'] as String? ?? 'Unknown';
    final type = payment['paymentType'] as String? ?? 'Payment';
    final createdAt = payment['createdAt'] as String?;
    final method = payment['paymentMethod'] as String? ?? 'N/A';

    DateTime? date;
    if (createdAt != null) {
      date = DateTime.tryParse(createdAt);
    }

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'failed':
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.1),
        child: Icon(
          type.toLowerCase() == 'refund' ? Icons.keyboard_return : Icons.payment,
          color: statusColor,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '$currency ${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            '$type • $method',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          if (date != null)
            Text(
              '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
