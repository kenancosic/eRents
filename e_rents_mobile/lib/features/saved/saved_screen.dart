// lib/feature/saved/saved_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:e_rents_mobile/core/models/property_card_model.dart';
import 'package:e_rents_mobile/features/saved/saved_provider.dart';
import 'package:e_rents_mobile/core/utils/app_spacing.dart';
import 'package:e_rents_mobile/core/utils/app_colors.dart';
import 'package:e_rents_mobile/core/widgets/empty_state_widget.dart';
import 'package:e_rents_mobile/core/widgets/error_state_widget.dart';
import 'package:e_rents_mobile/core/enums/property_enums.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  String _selectedCategory = 'All';
  
  @override
  void initState() {
    super.initState();
    // Load saved properties when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SavedProvider>().loadSavedProperties();
    });
  }
  
  List<PropertyCardModel> _getFilteredProperties(SavedProvider provider) {
    final all = provider.items;
    if (_selectedCategory == 'All') return all;
    
    final rentalType = _selectedCategory == 'Daily' 
        ? PropertyRentalType.daily 
        : PropertyRentalType.monthly;
    
    return all.where((p) => p.rentalType == rentalType).toList();
  }

  Future<void> _removeFromSaved(PropertyCardModel property) async {
    try {
      final provider = context.read<SavedProvider>();
      await provider.unsaveProperty(property.propertyId);
      
      if (mounted) {
        // Show a snackbar to confirm removal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${property.name} removed from saved'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () async {
                // Add the property back if user taps UNDO
                await provider.saveProperty(property.propertyId);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove ${property.name}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBar = CustomAppBar(
      title: 'Saved Properties',
      showBackButton: false,
    );

    return BaseScreen(
      showAppBar: true,
      appBar: appBar,
      body: Consumer<SavedProvider>(
        builder: (context, provider, child) => _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(SavedProvider provider) {
    // Wrap entire body with RefreshIndicator for pull-to-refresh in all states
    return RefreshIndicator(
      onRefresh: () => provider.refreshSavedProperties(),
      color: AppColors.primary,
      child: _buildBodyContent(provider),
    );
  }

  Widget _buildBodyContent(SavedProvider provider) {
    if (provider.isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (provider.hasError) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 100),
          ErrorStateWidget(
            message: provider.errorMessage,
            onRetry: () => provider.refreshSavedProperties(),
          ),
        ],
      );
    }

    if (provider.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 100),
          EmptyStateWidget(
            icon: Icons.bookmark_border,
            title: 'No saved properties yet',
            message: 'Properties you save will appear here\nPull down to refresh',
            actionText: 'Explore Properties',
            onAction: () => context.go('/explore'),
          ),
        ],
      );
    }

    // Filter properties based on selected category
    final items = _getFilteredProperties(provider);
    
    return Column(
      children: [
        _buildCategoryTabs(),
        if (items.isEmpty)
          Expanded(
            child: EmptyStateCompact(
              icon: _selectedCategory == 'Daily' 
                  ? Icons.wb_sunny_outlined
                  : Icons.calendar_month_outlined,
              message: 'No $_selectedCategory properties saved',
            ),
          )
        else
          Expanded(
            child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSpacing.paddingV_SM,
                itemCount: items.length + 1, // items + footer spacer
                separatorBuilder: (_, __) => SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  if (index == items.length) {
                    // Footer spacer
                    return SizedBox(height: AppSpacing.sm);
                  }

                  final property = items[index];
                return Dismissible(
                  key: Key('saved_property_${property.propertyId}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: AppSpacing.lg),
                    color: AppColors.error,
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (direction) {
                    _removeFromSaved(property);
                  },
                  child: PropertyCard(
                    property: property,
                    onTap: () {
                      context.push('/property/${property.propertyId}');
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
  
  Widget _buildCategoryTabs() {
    return Container(
      padding: AppSpacing.paddingMD,
      color: Colors.white,
      child: Row(
        children: [
          _buildTabChip('All'),
          SizedBox(width: AppSpacing.sm),
          _buildTabChip('Daily'),
          SizedBox(width: AppSpacing.sm),
          _buildTabChip('Monthly'),
        ],
      ),
    );
  }
  
  Widget _buildTabChip(String label) {
    final isSelected = _selectedCategory == label;
    return Expanded(
      child: FilterChip(
        label: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedCategory = label);
        },
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.primary.withValues(alpha: 0.1),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.borderLight,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
    );
  }
}
