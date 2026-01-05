import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/utils/app_colors.dart';
import 'package:e_rents_mobile/core/utils/app_spacing.dart';
import 'package:e_rents_mobile/core/models/maintenance_issue.dart';
import 'package:e_rents_mobile/core/enums/maintenance_issue_enums.dart';
import 'package:e_rents_mobile/core/providers/current_user_provider.dart';
import 'package:e_rents_mobile/features/maintenance/providers/maintenance_provider.dart';

/// Screen displaying all maintenance issues reported by the current tenant
class MaintenanceIssuesScreen extends StatefulWidget {
  const MaintenanceIssuesScreen({super.key});

  @override
  State<MaintenanceIssuesScreen> createState() => _MaintenanceIssuesScreenState();
}

class _MaintenanceIssuesScreenState extends State<MaintenanceIssuesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIssues();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadIssues() async {
    final currentUserProvider = context.read<CurrentUserProvider>();
    await context.read<MaintenanceProvider>().loadIssues(currentUserProvider);
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      appBar: CustomAppBar(
        title: 'Maintenance Issues',
        showBackButton: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: Consumer<MaintenanceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage.isNotEmpty 
                        ? provider.errorMessage 
                        : 'Failed to load issues',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadIssues,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadIssues,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildIssuesList(provider.pendingIssues, isPending: true),
                _buildIssuesList(provider.resolvedIssues, isPending: false),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIssuesList(List<MaintenanceIssue> issues, {required bool isPending}) {
    if (issues.isEmpty) {
      return _buildEmptyState(isPending: isPending);
    }

    return ListView.builder(
      padding: EdgeInsets.all(AppSpacing.md),
      itemCount: issues.length,
      itemBuilder: (context, index) {
        return _buildIssueCard(issues[index]);
      },
    );
  }

  Widget _buildEmptyState({required bool isPending}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.check_circle_outline : Icons.history,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? 'No Pending Issues' : 'No Resolved Issues',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPending
                  ? 'All your maintenance requests have been resolved!'
                  : 'Your resolved issues will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueCard(MaintenanceIssue issue) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: AppColors.borderLight),
      ),
      child: InkWell(
        onTap: () => _showIssueDetails(issue),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      issue.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(issue.status),
                ],
              ),
              const SizedBox(height: 8),
              
              // Description preview
              Text(
                issue.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              
              // Footer with priority and date
              Row(
                children: [
                  _buildPriorityIndicator(issue.priority),
                  const Spacer(),
                  Icon(Icons.access_time, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(issue.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(MaintenanceIssueStatus status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case MaintenanceIssueStatus.pending:
        bgColor = AppColors.warningLight;
        textColor = AppColors.warningDark;
        label = 'Pending';
        break;
      case MaintenanceIssueStatus.inProgress:
        bgColor = AppColors.infoLight;
        textColor = AppColors.infoDark;
        label = 'In Progress';
        break;
      case MaintenanceIssueStatus.completed:
        bgColor = AppColors.successLight;
        textColor = AppColors.successDark;
        label = 'Resolved';
        break;
      case MaintenanceIssueStatus.cancelled:
        bgColor = AppColors.errorLight;
        textColor = AppColors.errorDark;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(MaintenanceIssuePriority priority) {
    Color color;
    String label;

    switch (priority) {
      case MaintenanceIssuePriority.low:
        color = AppColors.success;
        label = 'Low';
        break;
      case MaintenanceIssuePriority.medium:
        color = AppColors.warning;
        label = 'Medium';
        break;
      case MaintenanceIssuePriority.high:
        color = AppColors.error;
        label = 'High';
        break;
      case MaintenanceIssuePriority.emergency:
        color = Colors.purple;
        label = 'Emergency';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return DateFormat.yMMMd().format(date);
  }

  void _showIssueDetails(MaintenanceIssue issue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Title and status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            issue.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusBadge(issue.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Meta info
                    Row(
                      children: [
                        _buildPriorityIndicator(issue.priority),
                        const SizedBox(width: 16),
                        Icon(Icons.calendar_today, size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          'Reported: ${_formatDate(issue.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    
                    // Description
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      issue.description,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                    
                    // Category if available
                    if (issue.category != null && issue.category!.isNotEmpty) ...[
                      Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        issue.category!,
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Resolution notes if resolved
                    if (issue.isResolved && issue.resolutionNotes != null) ...[
                      Text(
                        'Resolution Notes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.successDark),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                issue.resolutionNotes!,
                                style: TextStyle(color: AppColors.successDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
