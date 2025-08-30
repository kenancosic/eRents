import 'dart:async';
import 'package:flutter/material.dart';
import 'package:e_rents_desktop/widgets/custom_search_bar.dart';

// Internal notifier to isolate table-only rebuilds
class FilterController {
  Map<String, dynamic> Function()? _getFilters;
  VoidCallback? _resetFields;

  void bind({
    required Map<String, dynamic> Function() getFilters,
    required VoidCallback resetFields,
  }) {
    _getFilters = getFilters;
    _resetFields = resetFields;
  }

  Map<String, dynamic> getFilters() => _getFilters?.call() ?? const <String, dynamic>{};
  void resetFields() => _resetFields?.call();
}
/// Public controller to allow parent widgets to trigger ListScreen refreshes
class ListController {
  Future<void> Function()? _refresh;

  void bind({required Future<void> Function() refresh}) {
    _refresh = refresh;
  }

  Future<void> refresh() async {
    final fn = _refresh;
    if (fn != null) {
      await fn();
    }
  }
}
class _ListContentState<T> extends ChangeNotifier {
  List<T> _items = const [];
  bool _isLoading = false;
  String _errorMessage = '';
  bool _hasMore = true;

  List<T> get items => _items;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  void setItems(List<T> newItems) {
    _items = newItems;
    notifyListeners();
  }

  void appendItems(List<T> newItems) {
    _items = List<T>.from(_items)..addAll(newItems);
    notifyListeners();
  }

  void setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void setHasMore(bool value) {
    if (_hasMore == value) return;
    _hasMore = value;
    notifyListeners();
  }
}

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
  final Future<List<T>> Function({
    int page,
    int pageSize,
    Map<String, dynamic>? filters,
  })
  fetchItems;

  /// Function to navigate to the detail view for an item
  final void Function(T item) onItemTap;

  /// Optional function to handle double-tap on an item (desktop UX)
  final void Function(T item)? onItemDoubleTap;

  /// Optional function to sort items
  ///
  /// This function is used to sort items client-side after they are fetched
  /// from the server. It follows the standard Dart comparison function pattern
  /// where it should return a negative value if a < b, zero if a == b, and a
  /// positive value if a > b.
  final int Function(T a, T b)? sortFunction;

  /// Optional function to filter items
  ///
  /// This function is used to filter items client-side after they are fetched
  /// from the server. It should return true for items that should be included
  /// in the list and false for items that should be filtered out.
  final bool Function(T item)? filterFunction;

  /// Whether to enable pagination
  final bool enablePagination;

  /// Page size for pagination
  final int pageSize;


  /// Whether to show filter functionality
  final bool showFilters;

  /// Optional: builds the filter panel. Receives current filters and a
  /// FilterController to surface the panel's state back to the dialog actions.
  final Widget Function(
    BuildContext context,
    Map<String, dynamic> currentFilters,
    FilterController controller,
  )? filterBuilder;

  /// The querystring key used when building search filters via inline/appbar search.
  /// Defaults to 'search'. Override per screen if backend expects a different key
  /// (e.g., 'nameContains').
  final String searchParamKey;

  /// Optional custom actions to display in the AppBar before the built-in actions
  /// such as search, filter and refresh. Useful for providing context-specific
  /// actions like "Add".
  final List<Widget>? actions;
  /// Whether to show a Reset button in the filter dialog actions.
  final bool showResetButton;

  /// Optional: when provided, the screen will render items in a DataTable
  /// instead of a ListView. This allows desktop-friendly, columnar layouts
  /// while reusing all existing loading, pagination, refresh, and search logic.
  final List<DataColumn>? tableColumns;

  /// Builder for table rows when [tableColumns] is provided.
  final List<DataRow> Function(BuildContext context, List<T> items)? tableRowsBuilder;

  /// Show an inline search bar above the content (in addition to or instead of the
  /// AppBar search action). When enabled, it uses the existing search behavior.
  final bool inlineSearchBar;
  final String inlineSearchHint;

  /// When true, renders only the body so this widget can be embedded inside an
  /// existing Scaffold (e.g., inside TabBarView) without duplicating AppBars.
  final bool embedded;

  /// Optional controller to trigger a refresh from parent widgets.
  final ListController? controller;

  const ListScreen({
    super.key,
    required this.title,
    required this.itemBuilder,
    required this.fetchItems,
    required this.onItemTap,
    this.onItemDoubleTap,
    this.sortFunction,
    this.filterFunction,
    this.enablePagination = false,
    this.pageSize = 20,
    this.showFilters = false,
    this.filterBuilder,
    this.searchParamKey = 'search',
    this.actions,
    this.tableColumns,
    this.tableRowsBuilder,
    this.inlineSearchBar = false,
    this.inlineSearchHint = 'Search...',
    this.showResetButton = true,
    this.embedded = false,
    this.controller,
  });

  @override
  State<ListScreen<T>> createState() => _ListScreenState<T>();
}

class _ListScreenState<T> extends State<ListScreen<T>> {
  int _currentPage = 1;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic> _filters = {};
  Timer? _searchDebounce;
  late final _ListContentState<T> _content = _ListContentState<T>();

  @override
  void initState() {
    super.initState();
    _loadItems();
    if (widget.enablePagination) {
      _scrollController.addListener(_scrollListener);
    }
    // Bind external controller if provided
    widget.controller?.bind(refresh: _refresh);
  }

  @override
  void didUpdateWidget(covariant ListScreen<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller && widget.controller != null) {
      widget.controller!.bind(refresh: _refresh);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _content.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Trigger load more slightly before the very bottom for smoother UX
    final position = _scrollController.position;
    const threshold = 200.0; // px from bottom
    if (position.maxScrollExtent - position.pixels <= threshold) {
      _loadMore();
    }
  }

  Future<void> _loadItems() async {
    _content.setLoading(true);
    _content.setError('');

    try {
      final items = await widget.fetchItems(
        page: _currentPage,
        pageSize: widget.pageSize,
        filters: _filters,
      );

      // If the widget was disposed while awaiting, abort further state updates
      if (!mounted) return;

      // Apply client-side filtering if filterFunction is provided
      List<T> filteredItems = items;
      if (widget.filterFunction != null) {
        filteredItems = items.where(widget.filterFunction!).toList();
      }

      // Apply client-side sorting if sortFunction is provided
      if (widget.sortFunction != null) {
        filteredItems.sort(widget.sortFunction);
      }

      if (_currentPage == 1) {
        _content.setItems(filteredItems);
      } else {
        _content.appendItems(filteredItems);
      }
      _content.setHasMore(items.length == widget.pageSize);
      _content.setLoading(false);
    } catch (e) {
      // If the widget was disposed during the request, avoid touching _content
      if (!mounted) return;
      _content.setError(e.toString());
      _content.setLoading(false);
    }
  }

  Future<void> _loadMore() async {
    if (!_content.hasMore || _content.isLoading) return;
    _content.setLoading(true);

    _currentPage++;
    await _loadItems();
  }

  Future<void> _refresh() async {
    _currentPage = 1;
    _content.setItems(const []);
    await _loadItems();
  }

  void _onSearchChanged(String query) {
    // Debounce to avoid spamming API while typing
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _filters[widget.searchParamKey] = query;
        _currentPage = 1;
        _content.setItems(const []);
      });
      _loadItems();
    });
  }

  void _applyFilters(Map<String, dynamic> newFilters) {
    setState(() {
      _filters = newFilters;
      _currentPage = 1;
      _content.setItems(const []);
    });
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      // Render only the body content for embedding inside another Scaffold
      return _buildBody();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.actions != null) ...widget.actions!,
          if (!widget.inlineSearchBar && widget.showFilters && widget.filterBuilder != null)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Fixed top section for search, filters and actions
        if (widget.inlineSearchBar)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: CustomSearchBar(
              controller: _searchController,
              hintText: widget.inlineSearchHint,
              onChanged: _onSearchChanged,
              onFilterPressed: widget.showFilters && widget.filterBuilder != null
                  ? _showFilterDialog
                  : null,
            ),
          ),
        // Indicator that filters are active with quick clear action
        if (_hasActiveFilters())
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.filter_alt, size: 18),
                const SizedBox(width: 8),
                Text('Filters active' + (_activeFilterCount() > 0 ? ' (${_activeFilterCount()})' : '')),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                  onPressed: () => _applyFilters({}),
                ),
              ],
            ),
          ),
        // Dynamic table section that rebuilds independently
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: AnimatedBuilder(
              animation: _content,
              builder: (context, _) {
                return _TableContent<T>(
                  items: _content.items,
                  isLoading: _content.isLoading,
                  errorMessage: _content.errorMessage,
                  hasMore: _content.hasMore && widget.enablePagination,
                  scrollController: _scrollController,
                  listScreenWidget: widget,
                  onRefresh: _refresh,
                  onLoadMore: _loadMore,
                  buildLoadMoreIndicator: _buildLoadMoreIndicator,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    if (widget.filterBuilder == null) return;
    final controller = FilterController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filters'),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            if (widget.showResetButton)
              OutlinedButton.icon(
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset'),
                onPressed: () {
                  controller.resetFields();
                  Navigator.of(context).pop();
                  _applyFilters({});
                },
              ),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Search'),
              onPressed: () {
                final map = controller.getFilters();
                Navigator.of(context).pop();
                _applyFilters(map);
              },
            ),
          ],
          content: SizedBox(
            width: 720, // stabilize width to avoid jumpy transition while loading lookups
            child: widget.filterBuilder!(
              context,
              Map<String, dynamic>.from(_filters),
              controller,
            ),
          ),
        );
      },
    );
  }

  bool _hasActiveFilters() {
    // Any non-empty value in _filters indicates active filters
    for (final entry in _filters.entries) {
      final key = entry.key;
      final val = entry.value;
      if (key == widget.searchParamKey && (val is String) && val.trim().isEmpty) {
        continue; // ignore empty search text
      }
      if (_isValueActive(val)) return true;
    }
    return false;
  }

  int _activeFilterCount() {
    int count = 0;
    for (final entry in _filters.entries) {
      final key = entry.key;
      final val = entry.value;
      if (key == widget.searchParamKey && (val is String) && val.trim().isEmpty) {
        continue;
      }
      if (_isValueActive(val)) count++;
    }
    return count;
  }

  bool _isValueActive(dynamic v) {
    if (v == null) return false;
    if (v is String) return v.trim().isNotEmpty;
    if (v is num) return true; // numeric 0 can be a legitimate filter
    if (v is bool) return true;
    if (v is Iterable) return v.isNotEmpty;
    return true;
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: _content.isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
              onPressed: _loadMore,
              child: const Text('Load More'),
            ),
      ),
    );
  }
}

/// A separate widget for the table content that can rebuild independently
/// without affecting the search/filter controls
class _TableContent<T> extends StatefulWidget {
  final List<T> items;
  final bool isLoading;
  final String errorMessage;
  final bool hasMore;
  final ScrollController scrollController;
  final ListScreen<T> listScreenWidget;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final Widget Function() buildLoadMoreIndicator;

  const _TableContent({
    super.key,
    required this.items,
    required this.isLoading,
    required this.errorMessage,
    required this.hasMore,
    required this.scrollController,
    required this.listScreenWidget,
    required this.onRefresh,
    required this.onLoadMore,
    required this.buildLoadMoreIndicator,
  });

  @override
  State<_TableContent<T>> createState() => _TableContentState<T>();
}

class _TableContentState<T> extends State<_TableContent<T>> {
  int? _selectedRowIndex;
  int? _lastTappedIndex;
  DateTime? _lastTapTime;

  bool _isDoubleTapOnSameRow(int index) {
    final now = DateTime.now();
    final isSame = _lastTappedIndex == index;
    final within = _lastTapTime != null && now.difference(_lastTapTime!) < const Duration(milliseconds: 400);
    _lastTappedIndex = index;
    _lastTapTime = now;
    return isSame && within;
  }
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.onRefresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (widget.items.isEmpty && !widget.isLoading) {
      return const Center(
        child: Text('No items found'),
      );
    }

    // Table mode (desktop-friendly)
    if (widget.listScreenWidget.tableColumns != null &&
        widget.listScreenWidget.tableRowsBuilder != null) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final baseRows = widget.listScreenWidget.tableRowsBuilder!(context, widget.items);
            // Wrap rows to inject selection and double-click behavior
            final rows = <DataRow>[];
            for (var i = 0; i < baseRows.length; i++) {
              final base = baseRows[i];
              rows.add(
                DataRow(
                  cells: base.cells,
                  selected: _selectedRowIndex == i,
                  color: base.color,
                  onSelectChanged: (selected) {
                    if (_isDoubleTapOnSameRow(i)) {
                      // Double click – open details
                      final item = widget.items[i];
                      widget.listScreenWidget.onItemDoubleTap?.call(item);
                      return;
                    }
                    // Single click – select the row
                    setState(() {
                      _selectedRowIndex = i;
                    });
                  },
                ),
              );
            }

            return ListView(
              controller: widget.scrollController,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      columns: widget.listScreenWidget.tableColumns!,
                      rows: rows,
                      showCheckboxColumn: false,
                      headingRowHeight: 56,
                      dataRowMinHeight: 56,
                      dataRowMaxHeight: 72,
                      columnSpacing: 24,
                      horizontalMargin: 24,
                    ),
                  ),
                ),
                if (widget.hasMore) widget.buildLoadMoreIndicator(),
              ],
            );
          },
        ),
      );
    }

    // Default: card/list tiles
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        controller: widget.scrollController,
        itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (widget.hasMore && index == widget.items.length) {
            return widget.buildLoadMoreIndicator();
          }

          final item = widget.items[index];
          return InkWell(
            onTap: () => widget.listScreenWidget.onItemTap(item),
            onDoubleTap: widget.listScreenWidget.onItemDoubleTap != null
                ? () => widget.listScreenWidget.onItemDoubleTap!(item)
                : null,
            child: widget.listScreenWidget.itemBuilder(context, item),
          );
        },
      ),
    );
  }
}
