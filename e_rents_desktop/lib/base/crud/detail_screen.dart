import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A generic detail screen template that provides common functionality for displaying
/// detailed information about an item with a master-detail layout pattern.
///
/// This template follows Material 3 design principles optimized for desktop UI.
class DetailScreen<T> extends StatefulWidget {
  /// The title to display in the app bar
  final String title;

  /// The item to display details for
  final T item;

  /// Function to fetch an item by ID (for refresh functionality)
  final Future<T> Function(String id)? fetchItem;

  /// The ID of the item (for refresh functionality)
  final String? itemId;

  /// Function to build the detail view
  final Widget Function(BuildContext context, T item) detailBuilder;

  /// Function to navigate to the edit view
  final void Function(T item)? onEdit;

  /// Whether to show action buttons
  final bool showActions;

  /// Additional action buttons to display
  final List<Widget>? additionalActions;

  /// Whether to use a master-detail layout
  final bool useMasterDetailLayout;

  /// Master widget for master-detail layout
  final Widget? masterWidget;

  const DetailScreen({
    Key? key,
    required this.title,
    required this.item,
    this.fetchItem,
    this.itemId,
    required this.detailBuilder,
    this.onEdit,
    this.showActions = true,
    this.additionalActions,
    this.useMasterDetailLayout = false,
    this.masterWidget,
  }) : super(key: key);

  @override
  State<DetailScreen<T>> createState() => _DetailScreenState<T>();
}

class _DetailScreenState<T> extends State<DetailScreen<T>> {
  late T _item;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    if (widget.itemId != null && widget.fetchItem != null) {
      _refreshItem();
    }
  }

  Future<void> _refreshItem() async {
    if (widget.fetchItem == null || widget.itemId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final refreshedItem = await widget.fetchItem!(widget.itemId!);
      setState(() {
        _item = refreshedItem;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useMasterDetailLayout && widget.masterWidget != null) {
      return _buildMasterDetailLayout();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: _buildActions(),
      ),
      body: _buildBody(),
    );
  }

  List<Widget> _buildActions() {
    final actions = <Widget>[];

    if (widget.showActions) {
      if (widget.onEdit != null) {
        actions.add(
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => widget.onEdit!(_item),
          ),
        );
      }

      if (widget.fetchItem != null && widget.itemId != null) {
        actions.add(
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshItem,
          ),
        );
      }
    }

    if (widget.additionalActions != null) {
      actions.addAll(widget.additionalActions!);
    }

    return actions;
  }

  Widget _buildBody() {
    if (_isLoading && _errorMessage.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_errorMessage'),
            ElevatedButton(
              onPressed: _refreshItem,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return widget.detailBuilder(context, _item);
  }

  Widget _buildMasterDetailLayout() {
    return Row(
      children: [
        // Master panel (typically a list or navigation)
        SizedBox(
          width: 300,
          child: widget.masterWidget!,
        ),
        // Vertical divider
        const VerticalDivider(thickness: 1, width: 1),
        // Detail panel
        Expanded(
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              actions: _buildActions(),
            ),
            body: _buildBody(),
          ),
        ),
      ],
    );
  }
}