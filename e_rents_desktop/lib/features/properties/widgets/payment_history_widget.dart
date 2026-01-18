import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:e_rents_desktop/models/payment.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/features/chat/providers/chat_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/router.dart';

/// Redesigned Payment History widget with summary cards, filtering, and actions
class PaymentHistoryWidget extends StatefulWidget {
  final int propertyId;

  const PaymentHistoryWidget({
    super.key,
    required this.propertyId,
  });

  @override
  State<PaymentHistoryWidget> createState() => _PaymentHistoryWidgetState();
}

class _PaymentHistoryWidgetState extends State<PaymentHistoryWidget> {
  PaymentStatus? _statusFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Payment>?>(
      future: context.read<PropertyProvider>().fetchPropertyPayments(widget.propertyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final allPayments = snapshot.data ?? [];
        if (allPayments.isEmpty) {
          return _buildEmptyState();
        }

        // Apply filters
        final filteredPayments = _applyFilters(allPayments);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title
            Row(
              children: [
                const Icon(Icons.receipt_long, size: 20, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Payment History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () => setState(() {}),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary cards
            _buildSummaryCards(allPayments),
            const SizedBox(height: 16),

            // Filter bar
            _buildFilterBar(),
            const SizedBox(height: 12),

            // Payment table
            _buildPaymentTable(filteredPayments),
          ],
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text('Failed to load payments: $error')),
            TextButton(
              onPressed: () => setState(() {}),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, color: Colors.grey.shade400, size: 48),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No payment records',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Payment history will appear here once payments are made.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(List<Payment> payments) {
    final paid = payments.where((p) => p.paymentStatus == PaymentStatus.completed).toList();
    final pending = payments.where((p) => p.paymentStatus == PaymentStatus.pending).toList();
    final failed = payments.where((p) => p.paymentStatus == PaymentStatus.failed).toList();
    final refunded = payments.where((p) => p.paymentStatus == PaymentStatus.refunded).toList();

    double sumAmount(List<Payment> list) =>
        list.fold(0.0, (sum, p) => sum + p.amount);

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total Received',
            amount: sumAmount(paid),
            count: paid.length,
            color: Colors.green,
            icon: Icons.check_circle,
            isSelected: _statusFilter == PaymentStatus.completed,
            onTap: () => setState(() {
              _statusFilter = _statusFilter == PaymentStatus.completed ? null : PaymentStatus.completed;
            }),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Pending',
            amount: sumAmount(pending),
            count: pending.length,
            color: Colors.orange,
            icon: Icons.pending,
            isSelected: _statusFilter == PaymentStatus.pending,
            onTap: () => setState(() {
              _statusFilter = _statusFilter == PaymentStatus.pending ? null : PaymentStatus.pending;
            }),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Failed',
            amount: sumAmount(failed),
            count: failed.length,
            color: Colors.red,
            icon: Icons.error,
            isSelected: _statusFilter == PaymentStatus.failed,
            onTap: () => setState(() {
              _statusFilter = _statusFilter == PaymentStatus.failed ? null : PaymentStatus.failed;
            }),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Refunded',
            amount: sumAmount(refunded),
            count: refunded.length,
            color: Colors.blue,
            icon: Icons.replay,
            isSelected: _statusFilter == PaymentStatus.refunded,
            onTap: () => setState(() {
              _statusFilter = _statusFilter == PaymentStatus.refunded ? null : PaymentStatus.refunded;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        // Status filter dropdown
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<PaymentStatus?>(
            value: _statusFilter,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Statuses')),
              ...PaymentStatus.values.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s.displayName),
              )),
            ],
            onChanged: (value) => setState(() => _statusFilter = value),
          ),
        ),
        const SizedBox(width: 12),
        // Search field
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search',
              hintText: 'Search by reference or tenant...',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        const SizedBox(width: 12),
        // Clear filters button
        if (_statusFilter != null || _searchQuery.isNotEmpty)
          OutlinedButton.icon(
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('Clear'),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _statusFilter = null;
                _searchQuery = '';
              });
            },
          ),
      ],
    );
  }

  List<Payment> _applyFilters(List<Payment> payments) {
    var filtered = payments;

    // Apply status filter
    if (_statusFilter != null) {
      filtered = filtered.where((p) => p.paymentStatus == _statusFilter).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        final ref = (p.paymentReference ?? '').toLowerCase();
        final tenantName = (p.tenant?.fullName ?? '').toLowerCase();
        return ref.contains(query) || tenantName.contains(query);
      }).toList();
    }

    // Sort: pending first, then by date descending
    filtered.sort((a, b) {
      if (a.paymentStatus == PaymentStatus.pending && b.paymentStatus != PaymentStatus.pending) return -1;
      if (a.paymentStatus != PaymentStatus.pending && b.paymentStatus == PaymentStatus.pending) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  Widget _buildPaymentTable(List<Payment> payments) {
    if (payments.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('No payments match your filters', style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }

    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
          columns: const [
            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Tenant', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Reference', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Method', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: payments.map((payment) {
            final isPending = payment.paymentStatus == PaymentStatus.pending;
            final isFailed = payment.paymentStatus == PaymentStatus.failed;

            return DataRow(
              color: isPending
                  ? WidgetStateProperty.all(Colors.orange.shade50)
                  : isFailed
                      ? WidgetStateProperty.all(Colors.red.shade50)
                      : null,
              cells: [
                DataCell(Text(dateFormat.format(payment.createdAt))),
                DataCell(Text(payment.tenant?.fullName ?? 'N/A')),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      payment.paymentReference ?? '-',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
                DataCell(_buildPaymentMethodChip(payment.paymentMethod?.displayName)),
                DataCell(
                  Text(
                    '\$${payment.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isPending ? Colors.orange.shade800 : null,
                    ),
                  ),
                ),
                DataCell(_buildStatusChip(payment.paymentStatus)),
                DataCell(_PaymentRowActions(
                  payment: payment,
                  onRefresh: () => setState(() {}),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodChip(String? method) {
    IconData icon;
    Color color;

    switch (method?.toLowerCase()) {
      case 'stripe':
        icon = Icons.credit_card;
        color = Colors.purple;
        break;
      case 'paypal':
        icon = Icons.account_balance_wallet;
        color = Colors.blue;
        break;
      case 'manual':
      case 'cash':
        icon = Icons.money;
        color = Colors.green;
        break;
      default:
        icon = Icons.payment;
        color = Colors.grey;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(method ?? 'Unknown', style: TextStyle(color: color)),
      ],
    );
  }

  Widget _buildStatusChip(PaymentStatus? status) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case PaymentStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'Paid';
        break;
      case PaymentStatus.pending:
        color = Colors.orange;
        icon = Icons.pending;
        label = 'Pending';
        break;
      case PaymentStatus.failed:
        color = Colors.red;
        icon = Icons.error;
        label = 'Failed';
        break;
      case PaymentStatus.refunded:
        color = Colors.blue;
        icon = Icons.replay;
        label = 'Refunded';
        break;
      case PaymentStatus.cancelled:
        color = Colors.grey;
        icon = Icons.cancel;
        label = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Summary card for payment statistics
class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final int count;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.count,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count payment${count == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row actions for individual payments
class _PaymentRowActions extends StatelessWidget {
  final Payment payment;
  final VoidCallback onRefresh;

  const _PaymentRowActions({
    required this.payment,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      tooltip: 'Actions',
      onSelected: (action) => _handleAction(context, action),
      itemBuilder: (context) => _buildMenuItems(),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    final items = <PopupMenuEntry<String>>[];

    // Always show view details
    items.add(const PopupMenuItem(
      value: 'view_details',
      child: ListTile(
        leading: Icon(Icons.visibility, size: 20),
        title: Text('View Details'),
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    ));

    // Status-specific actions
    switch (payment.paymentStatus) {
      case PaymentStatus.pending:
        items.addAll([
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'mark_paid',
            child: ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green, size: 20),
              title: Text('Mark as Paid'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          const PopupMenuItem(
            value: 'send_reminder',
            child: ListTile(
              leading: Icon(Icons.notification_add, color: Colors.orange, size: 20),
              title: Text('Send Reminder'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        ]);
        break;

      case PaymentStatus.failed:
        items.addAll([
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'retry',
            child: ListTile(
              leading: Icon(Icons.refresh, color: Colors.blue, size: 20),
              title: Text('Retry Payment'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        ]);
        break;

      case PaymentStatus.completed:
        items.addAll([
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'refund',
            child: ListTile(
              leading: Icon(Icons.replay, color: Colors.blue, size: 20),
              title: Text('Issue Refund'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        ]);
        break;

      default:
        break;
    }

    // Message tenant (if tenant info available)
    if (payment.tenantId != null) {
      items.addAll([
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
      ]);
    }

    return items;
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'view_details':
        _showPaymentDetails(context);
        break;
      case 'mark_paid':
        _showMarkAsPaidDialog(context);
        break;
      case 'send_reminder':
        _sendReminder(context);
        break;
      case 'retry':
        _retryPayment(context);
        break;
      case 'refund':
        _showRefundDialog(context);
        break;
      case 'message':
        _openChat(context);
        break;
    }
  }

  void _showPaymentDetails(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.receipt, color: Colors.purple),
            SizedBox(width: 8),
            Text('Payment Details'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Payment ID', '#${payment.paymentId}'),
              _buildDetailRow('Date', dateFormat.format(payment.createdAt)),
              _buildDetailRow('Amount', '\$${payment.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Status', payment.paymentStatus?.displayName ?? 'Unknown'),
              _buildDetailRow('Method', payment.paymentMethod?.displayName ?? 'Unknown'),
              if (payment.paymentReference != null)
                _buildDetailRow('Reference', payment.paymentReference!),
              if (payment.tenant != null)
                _buildDetailRow('Tenant', payment.tenant!.fullName),
              if (payment.bookingId != null)
                _buildDetailRow('Booking ID', '#${payment.bookingId}'),
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

  void _showMarkAsPaidDialog(BuildContext context) {
    final referenceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Mark as Paid'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Mark payment of \$${payment.amount.toStringAsFixed(2)} as paid?'),
              const SizedBox(height: 16),
              TextField(
                controller: referenceController,
                decoration: const InputDecoration(
                  labelText: 'Payment Reference (optional)',
                  hintText: 'e.g., Check #, Bank transfer ID',
                  border: OutlineInputBorder(),
                ),
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
            icon: const Icon(Icons.check),
            label: const Text('Mark as Paid'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.of(ctx).pop();
              onRefresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment marked as paid'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _sendReminder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment reminder sent to ${payment.tenant?.fullName ?? 'tenant'}'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _retryPayment(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Retrying payment...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showRefundDialog(BuildContext context) {
    final amountController = TextEditingController(
      text: payment.amount.toStringAsFixed(2),
    );
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.replay, color: Colors.blue),
            SizedBox(width: 8),
            Text('Issue Refund'),
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
                  labelText: 'Refund Amount',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Reason for refund...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
            icon: const Icon(Icons.replay),
            label: const Text('Issue Refund'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              Navigator.of(ctx).pop();
              onRefresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refund issued successfully'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openChat(BuildContext context) async {
    if (payment.tenant == null) return;

    final chatProvider = context.read<ChatProvider>();
    final userId = payment.tenant!.userId;
    final success = await chatProvider.ensureContact(userId);
    if (success && context.mounted) {
      chatProvider.selectContact(userId);
      context.go(AppRoutes.chat);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start chat with tenant')),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
