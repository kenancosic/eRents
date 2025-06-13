import 'package:e_rents_desktop/base/base.dart';
import 'package:e_rents_desktop/models/rental_request.dart';
import 'package:e_rents_desktop/services/rental_request_service.dart';

/// Repository for rental request data with caching support
class RentalRequestRepository
    extends BaseRepository<RentalRequest, RentalRequestService> {
  RentalRequestRepository({
    required RentalRequestService service,
    required CacheManager cacheManager,
  }) : super(service: service, cacheManager: cacheManager);

  @override
  String get resourceName => 'rental_requests';

  @override
  Duration get defaultCacheTtl => const Duration(minutes: 10);

  // ===================================================================
  // UNIVERSAL SYSTEM INTEGRATION (Primary Methods)
  // ===================================================================

  /// Get paginated rental requests (Universal System)
  Future<Map<String, dynamic>> getPagedRentalRequests([
    Map<String, dynamic>? params,
  ]) async {
    try {
      final cacheKey = _buildCacheKey('paged', params);

      // Try cache first if enabled
      if (enableCaching) {
        final cached = await cacheManager.get<Map<String, dynamic>>(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      // Fetch from service
      final result = await service.getPagedRentalRequests(params);

      // Cache the result if enabled
      if (enableCaching) {
        await cacheManager.set(cacheKey, result, duration: defaultCacheTtl);
      }

      return result;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Get all rental requests without pagination (for RentalManagementService)
  Future<List<RentalRequest>> getAll([Map<String, dynamic>? params]) async {
    try {
      final cacheKey = _buildCacheKey('all', params);

      // Try cache first if enabled
      if (enableCaching) {
        final cached = await cacheManager.get<List<RentalRequest>>(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      // Fetch from service
      final result = await service.getAllRentalRequests(params);

      // Cache the result
      if (enableCaching) {
        await cacheManager.set(cacheKey, result, duration: defaultCacheTtl);
      }

      return result;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  // ===================================================================
  // SPECIALIZED RENTAL REQUEST METHODS
  // ===================================================================

  /// Submit annual rental request
  Future<RentalRequest> requestAnnualRental(
    Map<String, dynamic> requestData,
  ) async {
    try {
      final result = await service.requestAnnualRental(requestData);

      // Invalidate relevant cache entries
      await _invalidateCache();

      return result;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Approve rental request
  Future<void> approveRentalRequest(
    int requestId,
    bool approved,
    String response,
  ) async {
    try {
      if (approved) {
        await service.approveRentalRequest(requestId, response);
      } else {
        await service.rejectRentalRequest(requestId, response);
      }

      // Invalidate cache for this specific request and lists
      if (enableCaching) {
        final cacheKey = _buildCacheKey('item', {'id': requestId.toString()});
        await cacheManager.remove(cacheKey);
        await _invalidateListCaches();
      }
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Get pending rental requests for landlord
  Future<List<RentalRequest>> getPendingRequests() async {
    try {
      final cacheKey = _buildCacheKey('pending');

      // Try cache first if enabled
      if (enableCaching) {
        final cached = await cacheManager.get<List<RentalRequest>>(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      // Fetch from service
      final result = await service.getPendingRequests();

      // Cache the result with shorter TTL (more dynamic data)
      if (enableCaching) {
        await cacheManager.set(
          cacheKey,
          result,
          duration: Duration(minutes: defaultCacheTtl.inMinutes ~/ 2),
        );
      }

      return result;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Get all rental requests for landlord's properties
  Future<List<RentalRequest>> getMyPropertyRequests() async {
    try {
      final cacheKey = _buildCacheKey('my_properties');

      // Try cache first if enabled
      if (enableCaching) {
        final cached = await cacheManager.get<List<RentalRequest>>(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      // Fetch from service
      final result = await service.getMyPropertyRequests();

      // Cache the result
      if (enableCaching) {
        await cacheManager.set(cacheKey, result, duration: defaultCacheTtl);
      }

      return result;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Withdraw rental request
  Future<void> withdrawRentalRequest(int requestId) async {
    try {
      await service.withdrawRentalRequest(requestId);

      // Invalidate cache for this specific request and lists
      if (enableCaching) {
        final cacheKey = _buildCacheKey('item', {'id': requestId.toString()});
        await cacheManager.remove(cacheKey);
        await _invalidateListCaches();
      }
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Check if user can request a property
  Future<bool> canRequestProperty(int propertyId) async {
    try {
      return await service.canRequestProperty(propertyId);
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Get expiring contracts
  Future<List<RentalRequest>> getExpiringContracts({int? daysAhead}) async {
    try {
      final cacheKey = _buildCacheKey('expiring', {'daysAhead': daysAhead});

      // Try cache first if enabled
      if (enableCaching) {
        final cached = await cacheManager.get<List<RentalRequest>>(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      // Fetch from service
      final result = await service.getExpiringContracts(daysAhead: daysAhead);

      // Cache with shorter TTL (time-sensitive data)
      if (enableCaching) {
        await cacheManager.set(
          cacheKey,
          result,
          duration: const Duration(minutes: 5),
        );
      }

      return result;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Get rental request statistics
  Future<Map<String, dynamic>> getRentalRequestStatistics() async {
    try {
      final cacheKey = _buildCacheKey('statistics');

      // Try cache first if enabled
      if (enableCaching) {
        final cached = await cacheManager.get<Map<String, dynamic>>(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      // For now, return basic statistics from pending requests
      // This can be enhanced when the backend provides dedicated statistics endpoint
      final pendingRequests = await service.getPendingRequests();
      final allRequests = await service.getAllRentalRequests();

      final stats = {
        'totalRequests': allRequests.length,
        'pendingRequests': pendingRequests.length,
        'approvedRequests': allRequests.where((r) => r.isApproved).length,
        'rejectedRequests': allRequests.where((r) => r.isRejected).length,
      };

      // Cache statistics with shorter TTL
      if (enableCaching) {
        await cacheManager.set(
          cacheKey,
          stats,
          duration: const Duration(minutes: 5),
        );
      }

      return stats;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  // ===================================================================
  // BASE REPOSITORY IMPLEMENTATION
  // ===================================================================

  @override
  Future<List<RentalRequest>> fetchAllFromService([
    Map<String, dynamic>? params,
  ]) async {
    return await service.getAllRentalRequests(params);
  }

  @override
  Future<RentalRequest> fetchByIdFromService(String id) async {
    return await service.getRentalRequestById(int.parse(id));
  }

  @override
  Future<RentalRequest> createInService(RentalRequest item) async {
    return await service.createRentalRequest(item.toJson());
  }

  @override
  Future<RentalRequest> updateInService(String id, RentalRequest item) async {
    return await service.updateRentalRequest(int.parse(id), item.toJson());
  }

  @override
  Future<void> deleteInService(String id) async {
    await service.deleteRentalRequest(int.parse(id));
  }

  @override
  Future<bool> existsInService(String id) async {
    try {
      await service.getRentalRequestById(int.parse(id));
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> countInService([Map<String, dynamic>? params]) async {
    final items = await service.getAllRentalRequests(params);
    return items.length;
  }

  @override
  String? extractIdFromItem(RentalRequest item) {
    return item.requestId.toString();
  }

  // ===================================================================
  // HELPER METHODS
  // ===================================================================

  /// Build a cache key for rental request operations
  String _buildCacheKey(String operation, [Map<String, dynamic>? params]) {
    final buffer = StringBuffer();
    buffer.write('${resourceName}_$operation');

    if (params != null && params.isNotEmpty) {
      final sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );

      for (final entry in sortedParams.entries) {
        buffer.write('_${entry.key}:${entry.value}');
      }
    }

    return buffer.toString();
  }

  /// Invalidate all cache entries for this repository
  Future<void> _invalidateCache() async {
    await cacheManager.clear(resourceName);
  }

  /// Invalidate only list-related cache entries
  Future<void> _invalidateListCaches() async {
    await cacheManager.clearByRegex(
      RegExp(
        '^${resourceName}_(all|count|paged|pending|my_properties|expiring)',
      ),
    );
  }
}
