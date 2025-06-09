import '../base.dart';
import '../../widgets/table/core/table_query.dart';

/// Mixin for standardizing pagination patterns across collection providers
/// Eliminates code duplication in PropertyCollectionProvider, MaintenanceCollectionProvider, etc.
mixin PaginationProviderMixin<T> on CollectionProvider<T> {
  /// Generic pagination method that all collection providers can use
  Future<Map<String, dynamic>> getPagedData(
    Future<PagedResult<T>> Function(Map<String, dynamic>) repositoryCall, [
    Map<String, dynamic>? params,
  ]) async {
    try {
      final pagedResult = await repositoryCall(params ?? {});

      // Update local cache with current page data
      _updateLocalCacheFromPagedResult(pagedResult);

      return {
        'data': pagedResult.items,
        'totalCount': pagedResult.totalCount,
        'pageNumber': pagedResult.page,
        'pageSize': pagedResult.pageSize,
        'totalPages': pagedResult.totalPages,
        'hasPreviousPage': pagedResult.hasPreviousPage,
        'hasNextPage': pagedResult.hasNextPage,
      };
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Helper to update local cache from paged results
  void _updateLocalCacheFromPagedResult(PagedResult<T> pagedResult) {
    // Update local items for filtering/sorting operations
    // Note: Only replaces if this is the first page or we're doing a refresh
    if (pagedResult.page == 0) {
      // PagedResult uses 0-based indexing
      clear();
      for (final item in pagedResult.items) {
        // Use the inherited items list to add to cache
        items.add(item);
      }
    }
    notifyListeners();
  }
}
