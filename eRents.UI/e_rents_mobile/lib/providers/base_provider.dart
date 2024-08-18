import 'dart:convert';
import 'dart:io';

import 'package:e_rents_mobile/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:e_rents_mobile/services/secure_storage_service.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  static String? _baseUrl;
  get baseUrl => _baseUrl;
  String? _endpoint;
  get endpoint => _endpoint;
  
  HttpClient client = HttpClient();
  IOClient? http;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  BaseProvider(String endpoint) {
    _baseUrl = const String.fromEnvironment("baseUrl",
        defaultValue: "https://localhost:7193/");
    print("baseurl: $_baseUrl");

    if (_baseUrl!.endsWith("/") == false) {
      _baseUrl = "${_baseUrl!}/";
    }

    _endpoint = endpoint;
    client.badCertificateCallback = (cert, host, port) => true;
    http = IOClient(client);
  }

  Future<T> getById(int id, [dynamic additionalData]) async {
    setLoadingState(true);
    var url = Uri.parse("$_baseUrl$_endpoint/$id");

    Map<String, String> headers = await createHeaders();

    try {
      var response = await http!.get(url, headers: headers);
      return handleResponse(response);
    } catch (e) {
      handleException(e, 'getById');
      rethrow;
    } finally {
      setLoadingState(false);
    }
  }

  Future<List<T>> get({dynamic search, int? page, int? pageSize}) async {
    setLoadingState(true);
    var url = "$_baseUrl$_endpoint";

    if (search != null) {
      String queryString = getQueryString(search);
      url = "$url?$queryString";
    }

    if (page != null && pageSize != null) {
      url = "$url&page=$page&pageSize=$pageSize";
    }

    var uri = Uri.parse(url);

    Map<String, String> headers = await createHeaders();

    try {
      var response = await http!.get(uri, headers: headers);
      return (jsonDecode(response.body) as List).map((x) => fromJson(x)).cast<T>().toList();
    } catch (e) {
      handleException(e, 'get');
      rethrow;
    } finally {
      setLoadingState(false);
    }
  }

  Future<T?> insert(dynamic request) async {
    setLoadingState(true);
    var url = "$_baseUrl$_endpoint";
    var uri = Uri.parse(url);

    Map<String, String> headers = await createHeaders();
    var jsonRequest = jsonEncode(request);

    try {
      var response = await http!.post(uri, headers: headers, body: jsonRequest);
      return handleResponse(response);
    } catch (e) {
      handleException(e, 'insert');
      rethrow;
    } finally {
      setLoadingState(false);
    }
  }

  Future<T?> update(int id, [dynamic request]) async {
    setLoadingState(true);
    var url = "$_baseUrl$_endpoint/$id";
    var uri = Uri.parse(url);

    Map<String, String> headers = await createHeaders();

    try {
      var response = await http!.put(uri, headers: headers, body: jsonEncode(request));
      return handleResponse(response);
    } catch (e) {
      handleException(e, 'update');
      rethrow;
    } finally {
      setLoadingState(false);
    }
  }

  Future<bool> delete(int id) async {
    setLoadingState(true);
    var url = "$_baseUrl$_endpoint/$id";
    var uri = Uri.parse(url);

    Map<String, String> headers = await createHeaders();

    try {
      var response = await http!.delete(uri, headers: headers);
      return isValidResponseCode(response);
    } catch (e) {
      handleException(e, 'delete');
      rethrow;
    } finally {
      setLoadingState(false);
    }
  }

  T fromJson(data) {
    throw Exception("Override method");
  }

  String getQueryString(Map params,
      {String prefix = '&', bool inRecursion = false}) {
    String query = '';
    params.forEach((key, value) {
      if (inRecursion) {
        if (key is int) {
          key = '[$key]';
        } else if (value is List || value is Map) {
          key = '.$key';
        } else {
          key = '.$key';
        }
      }
      if (value is String || value is int || value is double || value is bool) {
        var encoded = value;
        if (value is String) {
          encoded = Uri.encodeComponent(value);
        }
        query += '$prefix$key=$encoded';
      } else if (value is DateTime) {
        query += '$prefix$key=${(value).toIso8601String()}';
      } else if (value is List || value is Map) {
        if (value is List) value = value.asMap();
        value.forEach((k, v) {
          query +=
              getQueryString({k: v}, prefix: '$prefix$key', inRecursion: true);
        });
      }
    });
    return query;
  }

  bool isValidResponseCode(Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    } else {
      handleErrorResponse(response);
      return false;
    }
  }

  void logError(Object e, String method) {
    print("Error in $method: $e");
  }

  void handleErrorResponse(Response response) {
    print("Error response: ${response.statusCode} - ${response.body}");
    _errorMessage = "Error: ${response.statusCode}";
    notifyListeners();
    // You can throw specific exceptions here if needed
  }

  T handleResponse(Response response) {
    if (isValidResponseCode(response)) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      throw Exception("Exception... handle this gracefully");
    }
  }

void handleException(Object e, String method) {
  logError(e, method);
  _errorMessage = e.toString();
  
  WidgetsBinding.instance?.addPostFrameCallback((_) {
    CustomSnackBar.showErrorSnackBar(_errorMessage ?? 'An error occurred');
  });

  notifyListeners();
}

  void setLoadingState(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<Map<String, String>> createHeaders() async {
    String? jwt = await SecureStorageService.getItem('jwt_token');
    if (jwt == null) {
      throw Exception('JWT token not found');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $jwt',
    };
  }
}
