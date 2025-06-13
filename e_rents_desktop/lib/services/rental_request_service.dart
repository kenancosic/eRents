import 'dart:convert';
import 'package:e_rents_desktop/models/rental_request.dart';
import 'package:e_rents_desktop/services/api_service.dart';

/// Service for handling rental request API operations
/// Follows the same pattern as BookingService
class RentalRequestService extends ApiService {
  RentalRequestService(super.baseUrl, super.secureStorageService);

  String get endpoint => '/rentalrequest';

  /// Get paginated rental requests (Universal System integration)
  Future<Map<String, dynamic>> getPagedRentalRequests([
    Map<String, dynamic>? params,
  ]) async {
    try {
      // Build query string from params
      String queryString = '';
      if (params != null && params.isNotEmpty) {
        queryString =
            '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await get('$endpoint$queryString', authenticated: true);
      return json.decode(response.body);
    } catch (e) {
      throw Exception('Failed to fetch paginated rental requests: $e');
    }
  }

  /// Get all rental requests without pagination
  Future<List<RentalRequest>> getAllRentalRequests([
    Map<String, dynamic>? params,
  ]) async {
    try {
      // Use Universal System with noPaging=true for all items
      final queryParams = <String, dynamic>{'noPaging': 'true', ...?params};

      String queryString = '';
      if (queryParams.isNotEmpty) {
        queryString =
            '?' +
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await get('$endpoint$queryString', authenticated: true);
      final responseData = json.decode(response.body);

      // Handle both paginated and non-paginated responses
      final List<dynamic> items;
      if (responseData is Map && responseData['items'] != null) {
        items = responseData['items'];
      } else if (responseData is List) {
        items = responseData;
      } else {
        items = [];
      }

      return items.map((json) => RentalRequest.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch all rental requests: $e');
    }
  }

  /// Get rental request by ID
  Future<RentalRequest> getRentalRequestById(int id) async {
    try {
      final response = await get('$endpoint/$id', authenticated: true);
      final responseData = json.decode(response.body);
      return RentalRequest.fromJson(responseData);
    } catch (e) {
      throw Exception('Failed to fetch rental request: $e');
    }
  }

  /// Create a new rental request
  Future<RentalRequest> createRentalRequest(
    Map<String, dynamic> requestData,
  ) async {
    try {
      final response = await post(endpoint, requestData, authenticated: true);
      final responseData = json.decode(response.body);
      return RentalRequest.fromJson(responseData);
    } catch (e) {
      throw Exception('Failed to create rental request: $e');
    }
  }

  /// Submit annual rental request (specialized endpoint)
  Future<RentalRequest> requestAnnualRental(
    Map<String, dynamic> requestData,
  ) async {
    try {
      final response = await post(
        '$endpoint/request-annual-rental',
        requestData,
        authenticated: true,
      );
      final responseData = json.decode(response.body);
      return RentalRequest.fromJson(responseData);
    } catch (e) {
      throw Exception('Failed to submit rental request: $e');
    }
  }

  /// Approve a rental request
  Future<bool> approveRentalRequest(int requestId, String response) async {
    try {
      final requestBody = {'response': response, 'approved': true};

      final apiResponse = await post(
        '$endpoint/approve/$requestId',
        requestBody,
        authenticated: true,
      );

      return apiResponse.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to approve rental request: $e');
    }
  }

  /// Reject a rental request
  Future<bool> rejectRentalRequest(int requestId, String reason) async {
    try {
      final requestBody = {'response': reason, 'approved': false};

      final apiResponse = await post(
        '$endpoint/reject/$requestId',
        requestBody,
        authenticated: true,
      );

      return apiResponse.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to reject rental request: $e');
    }
  }

  /// Get pending rental requests for landlord
  Future<List<RentalRequest>> getPendingRequests() async {
    try {
      final response = await get(
        '$endpoint/pending-requests',
        authenticated: true,
      );
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => RentalRequest.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending requests: $e');
    }
  }

  /// Get all rental requests for landlord's properties
  Future<List<RentalRequest>> getMyPropertyRequests() async {
    try {
      final response = await get(
        '$endpoint/my-property-requests',
        authenticated: true,
      );
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => RentalRequest.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch property requests: $e');
    }
  }

  /// Withdraw a pending rental request
  Future<bool> withdrawRentalRequest(int requestId) async {
    try {
      final response = await post(
        '$endpoint/withdraw/$requestId',
        {},
        authenticated: true,
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to withdraw rental request: $e');
    }
  }

  /// Check if user can request a property
  Future<bool> canRequestProperty(int propertyId) async {
    try {
      final response = await get(
        '$endpoint/can-request/$propertyId',
        authenticated: true,
      );
      final responseData = json.decode(response.body);
      return responseData['canRequest'] ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get expiring contracts
  Future<List<RentalRequest>> getExpiringContracts({int? daysAhead}) async {
    try {
      final params = <String, dynamic>{};
      if (daysAhead != null) {
        params['daysAhead'] = daysAhead;
      }

      String queryString = '';
      if (params.isNotEmpty) {
        queryString =
            '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await get(
        '$endpoint/expiring-contracts$queryString',
        authenticated: true,
      );
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => RentalRequest.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch expiring contracts: $e');
    }
  }

  /// Update rental request
  Future<RentalRequest> updateRentalRequest(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await put('$endpoint/$id', data, authenticated: true);
      final responseData = json.decode(response.body);
      return RentalRequest.fromJson(responseData);
    } catch (e) {
      throw Exception('Failed to update rental request: $e');
    }
  }

  /// Delete rental request
  Future<bool> deleteRentalRequest(int id) async {
    try {
      final response = await delete('$endpoint/$id', authenticated: true);
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to delete rental request: $e');
    }
  }
}
