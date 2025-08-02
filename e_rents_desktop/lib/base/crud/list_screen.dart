import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A generic list screen template that provides common functionality for displaying
/// lists of items with sorting, filtering, pagination, and navigation capabilities.
///
/// This template follows Material 3 design principles optimized for desktop UI.
class ListScreen<T> extends StatefulWidget {
  /// The title to display in the app bar
  final String title;

  /// Function to build individual list items
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Function to fetch items with optional pagination parameters
  final Future<List<T>> Function({int page, int pageSize, Map<String, dynamic>? filters}) fetchItems;

  /// Function to navigate to the detail view for an item
  final void Function(T item) onItemTap;

  /// Optional function to sort items
  final int Function(T a, T b)? sortFunction;

  /// Optional function to filter items
  final bool Function(T item)? filterFunction;

  /// Whether to enable pagination
  final bool enablePagination;

  /// Page size for pagination
  final int pageSize;

  /// Whether to show search functionality
  final bool showSearch;

  /// Whether to show filter functionality
  final bool showFilters;

  /// Custom filter widget to display in the filter panel
  final Widget? filterWidget;

  const ListScreen({
    Key? key,
    required this.title,
    required this.itemBuilder,
    required this.fetchItems,
    required this.onItemTap,
    this.sortFunction,
    this.filterFunction,
    this.enablePagination = false,
    this.pageSize = 20,
    this.showSearch = true,
    this.showFilters = false,
    this.filterWidget,
  }) : super(key: key);

  @override
  State<ListScreen<T>> createState() => _ListScreenState<T>();
}

class _ListScreenState<T> extends State<ListScreen<T>> {
  late Future<List<T>> _itemsFuture;
  List<T> _items = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMore = true;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic> _filters = {};

  @override
  void initState() {
    super.initState();
    _loadItems();
    if (widget.enablePagination) {
      _scrollController.addListener(_scrollListener);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMore();
    }
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final items = await widget.fetchItems(
        page: _currentPage,
        pageSize: widget.pageSize,
        filters: _filters,
      );
      
      setState(() {
        if (_currentPage == 1) {
          _items = items;
        } else {
          _items.addAll(items);
        }
        _hasMore = items.length == widget.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    _currentPage++;
    await _loadItems();
  }

  Future<void> _refresh() async {
    setState(() {
      _currentPage = 1;
      _items.clear();
    });
    await _loadItems();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filters['search'] = query;
      _currentPage = 1;
      _items.clear();
    });
    _loadItems();
  }

  void _applyFilters(Map<String, dynamic> newFilters) {
    setState(() {
      _filters = newFilters;
      _currentPage = 1;
      _items.clear();
    });
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.showSearch)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showSearchDialog,
            ),
          if (widget.showFilters && widget.filterWidget != null)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_errorMessage'),
            ElevatedButton(
              onPressed: _refresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(child: Text('No items found'));
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _items.length + (widget.enablePagination && _hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (widget.enablePagination && index == _items.length) {
            return _buildLoadMoreIndicator();
          }
          
          final item = _items[index];
          return InkWell(
            onTap: () => widget.onItemTap(item),
            child: widget.itemBuilder(context, item),
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _loadMore,
                child: const Text('Load More'),
              ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        _searchController.text = _filters['search'] ?? '';
        return AlertDialog(
          title: const Text('Search'),
          content: TextField(
            controller: _searchController,
            decoration: const InputDecoration(hintText: 'Enter search term'),
            onSubmitted: (value) {
              Navigator.of(context).pop();
              _onSearchChanged(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _onSearchChanged(_searchController.text);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _showFilterDialog() {
    if (widget.filterWidget == null) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filters'),
          content: widget.filterWidget,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Apply filters would be handled by the filterWidget itself
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }
}